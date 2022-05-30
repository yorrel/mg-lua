-- Wegesystem

local base   = require 'base'
local tools  = require 'utils.tools'
local room   = require 'room'
local ME     = require 'gmcp-data'

local logger = client.createLogger('wege')
local keymap = base.keymap


-- ---------------------------------------------------------------------------
-- Zustand des Moduls (nichts persistent)

-- configuration
local paths = {}
local pre = {}

-- letzten Startpunkt merken fuer zurueck
local last_start_wp = nil
-- List von Wegpunkten fuer Rueckweg - hat Prio vor last_start_wp
local prio_rueckweg = nil
-- enthaelt ggf. als naechstes zu gehende Schritte
local active_path = {}
-- zu erreichende Wegpunkte
local active_wp_list = {}
-- wann wurde zurueck zuletzt betaetigt?
local last_back_ack_time = os.time() - 10
-- ist die wegverarbeitung unterbrochen, z.B. fuer Trigger?
local ist_wegverarbeitung_unterbrochen = false


-- ---------------------------------------------------------------------------
-- Konfiguration der Wege

-- Pfad zur Weg-DB hinzufuegen
-- path kann ein String von schritten sein, die durch ';' getrennt sind,
-- oder eine Funktion die solch einen String liefert
local function definiereWeg(src, dest, path)
  local name = src..'-'..dest
  if paths[name] ~= nil then
    logger.warn('Weg wird ueberschrieben: '..name)
  end
  paths[name] = path
  -- add pre data
  local pre_nodes = pre[dest]
  if pre_nodes == nil then
    pre_nodes = {}
    pre[dest] = pre_nodes
  end
  if not tools.listContains(pre_nodes, src) then
    pre_nodes[#pre_nodes+1] = src
  end
end


local function entferneWeg(src, dest)
  local name = src..'-'..dest
  paths[name] = nil
  -- remove pre data
  local pre_nodes = pre[dest]
  logger.info('rm weg '..name)
  tools.listRemove(pre_nodes, src)
end


local reverse_steps = {
  n='s', no='sw', o='w', so='nw', ob='u', 
  nordoben='suedunten', nordostoben='suedwestunten', ostoben='westunten',
  suedostoben='nordwestunten', suedoben='nordunten', suedwestoben='nordostunten',
  westoben='ostunten', nordwestoben='suedostunten',
}
-- alle gegenrichtungen erzeugen
local tmpsteps = {}
for dir1,dir2 in pairs(reverse_steps) do
  tmpsteps[dir2] = dir1
end
for dir1,dir2 in pairs(tmpsteps) do
  reverse_steps[dir1] = dir2
end


-- /dopath Teilweg verarbeiten: liefert ersten schritt und rest-dopath
local function dopathExpansion(dopath_string)
  -- /dopath 5 o ...
  local n,cmd,rest = string.match(dopath_string, '/dopath %s*(%d+)%s+(%S+)%s*(.*)%s*$')
  if n ~= nil then
    local count = tonumber(n)
    if count > 1 then
      return cmd, '/dopath '..(count-1)..' '..cmd..' '..rest
    else
      return cmd, '/dopath '..rest
    end
  end
  -- /dopath o ...
  cmd,rest = string.match(dopath_string, '/dopath %s*(%a%S*)%s*(.*)%s*$')
  if cmd ~= nil then
    return cmd, '/dopath '..rest
  end
  -- /dopath leer
  return nil
end


-- erst /dopath expandieren -> platte Liste mit Schritten
-- danach alle Schritte invertieren
local function erzeugeInversenPfad(path)
  local steps = tools.splitString(path, ';')
  local back = {}
  while (#steps > 0) do
    local step = steps[1]
    table.remove(steps,1)
    if step:sub(1,8) == '/dopath ' then
      local cmd,step = dopathExpansion(step)
      while (cmd ~= nil) do
        local reverse_cmd = reverse_steps[cmd]
        if reverse_cmd == nil then
          logger.error('step nicht invertierbar: '..cmd)
          return nil
        end
        table.insert(back, 1, reverse_cmd)
        cmd,step = dopathExpansion(step)
      end
    else
      local reverse_cmd = reverse_steps[step]
      if reverse_cmd == nil then
        logger.error('step nicht invertierbar: '..step)
        return nil
      end
      table.insert(back, 1, reverse_cmd)
    end
  end
  return table.concat(back, ';')
end


-- automatically create backward path
local function definiereWegUndRueckweg(src, dest, path)
  definiereWeg(src, dest, path)
  local path_back = erzeugeInversenPfad(path)
  if path_back == nil then
    logger.error('path '..src..'-'..dest..' is not reversible!')
  else
    definiereWeg(dest, src, path_back)
  end
end


-- ---------------------------------------------------------------------------
-- Interface der Engine (Teil 1)

-- Hilfsfunktion: liefert den vermutlichen Ausgangspunkt
local function ermittleAktuellenStartpunkt()
  local wp = room.getRoomName()
  if wp ~= nil and string.match(wp, '.*_p[1-9]$') then
    wp = wp:sub(1, -4)
  end
  return wp
end

-- Hilfsfunktion: pruefung ob noch ein weg zu gehen ist
local function istWegBeendet()
  return
    (active_wp_list == nil or #active_wp_list == 0)
    and (active_path == nil or #active_path == 0)
end


-- ---------------------------------------------------------------------------
-- Implementierung der Engine

-- hilfsmacro: active_path auf naechsten Teilweg setzen falls dieser
-- leer ist und weitere Wegpunkte existieren
-- return false bei Fehler
local function erzeugeNaechstenTeilweg(from)
  if #active_wp_list > 0 then
    local next_wp = active_wp_list[1]
    local _ref = from..'-'..next_wp
    logger.debug('erzeuge naechsten Teilweg ¸\''.._ref..'\'')
    local path = paths[_ref]
    if type(path) == 'function' then
      path = path()
    end
    if path == nil then
      logger.error('Weg \''.._ref..'\' unbekannt!')
      return false
    end
    active_path = tools.splitString(path, ';')
  end
  return true
end


-- handler fuer spezielle Weg-Cmds (plugin-wege-commands)
-- Die Abarbeitung des Weges wird unterbrochen. Die Fortsetzung muss explizit
-- von aussen mit continue() angestossen werden.
-- Liefert ein Handler true beim Aufruf zurueck, so wird der Schritt nach Aufruf
-- von continue() erneut ausgefuehrt, nur bei continue(true) nicht.
-- Das ist nuetzlich fuer Pruefungen (z.B. Blocker oder vorhandene Items).
local wege_handler = {}

local function defHandler(id, f)
  wege_handler[id] = f
end

local continue_stutter_step

local function brecheAktuellenWegAb(silent)
  active_wp_list = {}
  active_path = {}
  continue_stutter_step = nil
  if not silent then
    logger.info('Aktuellen Weg abgebrochen!')
  end
end

-- Macro fuer einen einzelnen Schritt
-- args: Einzelschritt aus Wegliste, dieser wird verarbeitet
local function geheSchritt(step)
  if type(step)=='function' then
    step = step()
    logger.debug('dynamischer Schritt lieferte: '..step)
  else
    logger.debug('verarbeite Schritt '..step)
  end

  -- Schritte mit /dopath: ersetzt /dopath ... durch Liste von cmds
  if step:sub(1,8) == '/dopath ' then
    local step,rest = dopathExpansion(step)
    if step ~= nil then
      table.insert(active_path, 1, rest)
      table.insert(active_path, 1, step)
    end

  -- process trigger commands
  elseif step:sub(1,1) == '/' then
    local cmd,arg = string.match(step,'(/[a-z_]+) *(.*)')
    local handler = wege_handler[cmd]
    if type(handler) ~= 'function' then
      logger.error('Handler fehlt fuer: '..cmd)
    else
      logger.debug('starte trigger typ \''..cmd..'\' mit arg: '..arg)
      if handler(arg) then
        continue_stutter_step = step
      end
    end
    ist_wegverarbeitung_unterbrochen = true

  else
    client.send(step)
  end
end

-- geht den aktuellen globalen Weg, gegeben durch active_path und active_wp_list
local function continue(skip_stutter)
  if continue_stutter_step ~= nil and not skip_stutter then
    table.insert(active_path, 1, continue_stutter_step)
    continue_stutter_step = nil
  end
  client.send('ultrakurz')
  ist_wegverarbeitung_unterbrochen = false
  while not istWegBeendet() and not ist_wegverarbeitung_unterbrochen do
    -- ggf. naechsten Teilweg aus den Wegpunkten erstellen
    if #active_path == 0 then
      local reaching_wp = active_wp_list[1]
      table.remove(active_wp_list,1)
      logger.debug('Wegesystem erreicht Wegpunkt \''..reaching_wp..'\'')
      if not erzeugeNaechstenTeilweg(reaching_wp) then
        client.send('lang')
        return
      end
    end
    if #active_path > 0 then
      local _w=active_path[1]
      table.remove(active_path, 1)
      geheSchritt(_w)
    end
  end
  if ist_wegverarbeitung_unterbrochen then
    logger.debug('Ausstieg aus Wegverarbeitung')
  elseif last_start_wp ~= nil or prio_rueckweg ~= nil then
    logger.info('Rueckweg mit M-7 moeglich (nach '..last_start_wp..')')
  end
  client.send('lang')
end


-- Sucht einen Weg zwischen Wegpunkten
-- returns: list of wp (start ->) wp1 -> wp2 -> ... ziel (ohne start)
local function erzeugeWegpunktListe(start,ziel,map)
  logger.debug('create_wp_list mit start '..start..', ziel '..ziel)
  local weg = {}
  local wp = map[start]
  while wp ~= ziel do
    weg[#weg+1] = wp
    wp = map[wp]
  end
  weg[#weg+1] = ziel
  logger.debug('create_wp_list erzeugt weg '..table.concat(weg,','))
  return weg
end


local function preNodes(dest)
  local pre_nodes = pre[dest] or {}
  local nodes = {}
  for i,n in pairs(pre_nodes) do
    nodes[i] = n
  end
  return nodes
end


-- sucht weg von einem dynamischen Wegpunkt zu einem anderen (rueckwaerts)
-- Ueber eine Rueckwaertssuche wird eine Folge von Wegpunkten gesucht,
-- zwischen denen Wege bekannt sind.
--
-- args: startpunkt zielpunkt
-- returns: List von Wegpunkten (start ->) wp1 -> wp2 -> ... -> ziel (ohne start)
local function sucheWegpunktListeZwischen(_start, _ziel)
  if _start == _ziel then
    return {}
  end
  local reachable = { _ziel = true }
  local reachable_nodes_todo= { _ziel }
  -- map wp -> wp (wp1 -> ziel, wp2 -> wp1, start -> wp2)
  local reachable_map = {}
  while (#reachable_nodes_todo> 0) do
    -- wie kann _tmpziel erreicht werden?
    local tmpziel = reachable_nodes_todo[1]
    table.remove(reachable_nodes_todo, 1)
    logger.debug('erstelle_teilweg pruefe Wegpunkt '..tmpziel)
    local punkte = preNodes(tmpziel)
    logger.debug('erstelle_teilweg pre von '..tmpziel..' ist '..table.concat(punkte,','))
    if tools.listContains(punkte,_start) then
      logger.debug('erstelle_teilweg Startknoten fuer Teilweg nach '.._ziel..' gefunden!')
      reachable_map[_start] = tmpziel
      return erzeugeWegpunktListe(_start, _ziel, reachable_map)
    end
    while (#punkte > 0) do
      local p = punkte[1]
      table.remove(punkte, 1)
      if not reachable[p] then
        reachable[p] = true
        reachable_nodes_todo[#reachable_nodes_todo + 1] = p
        reachable_map[p] = tmpziel
      end
    end
  end
end


-- Weg-Ermittlung ausgehend von startpunkt ueber angegebene Wegpunkte.
-- Es wird jeweils der Weg zum naechsten Wegpunkt ermittelt und an den
-- bisherigen Gesamtweg angehaengt (so der Gesamtweg aufgebaut).
--
-- args: <startpunkt>, <Liste von Wegpunkten (in dieser Reihenfolge zu besuchen)>
-- return: Liste von Wegpunkten, zwischen denen Wege existieren (inklusive Startpunkt)
local function sucheWegUeberWegpunkte(wp_list)
  logger.debug('Wegsuche ueber Wegpunkte '..table.concat(wp_list,','))
  local _start = table.remove(wp_list, 1)
  local weg = {_start}
  while #wp_list > 0 do
    local _ziel = room.getWegpunktNachAliasErsetzung(wp_list[1])
    table.remove(wp_list, 1)
    logger.debug('Wegsuche von '.._start..' nach '.._ziel)
    local teilweg = sucheWegpunktListeZwischen(_start, _ziel)
    if teilweg == nil then
      logger.error('Weg nicht gefunden (von \''.._start..'\' nach \''.._ziel..'\').')
      return nil
    end
    tools.tableConcat(weg, teilweg)
    _start = _ziel
  end
  logger.debug('Ermittelter Weg: '..table.concat(weg, ','))
  return weg
end


-- ---------------------------------------------------------------------------
-- Interface der Engine (Teil 2)

local function geheWeg(wp_list)
  logger.debug('Gehe Weg: '..table.concat(wp_list, ','))

  -- vollstaendige wp-liste erzeugen ausgehend von active_wp
  active_wp_list = sucheWegUeberWegpunkte(wp_list)
  if active_wp_list == nil then
    logger.error('Keinen Weg ueber Wegpunkte gefunden!')
    active_path = {}
    return
  end
  base.raiseEvent('ways.start.way')
  logger.info('Ermittelter Weg: '..table.concat(active_wp_list, ','))
  
  continue()
end

-- args: src pfad_als_wp_liste
local function geheWegpunkteAb(src, wp_list)
  if src == nil then
    logger.error('Fehlender Startpunkt, Abbruch!')
    return
  end
  last_start_wp = src
  local wp_list_mit_src = {table.unpack(wp_list)}
  table.insert(wp_list_mit_src, 1, src)
  geheWeg(wp_list_mit_src)
end

-- Mit diesem Kommando ist es moeglich, ab dem aktuellen Wegpunkt eine Reihe von
-- Wegpunkten abzulaufen. Zwischen den angegebenen Wegpunkten werden Wege gesucht.
-- args: pfad_als_wp_liste
local function geheWegpunkte(wp_list)
  local aktWp = ermittleAktuellenStartpunkt()
  if aktWp == nil then
    logger.error('Aktueller Wegpunkt unbekannt, Abbruch!')
    return
  end
  geheWegpunkteAb(aktWp, wp_list)
end

-- args: <startwegpunkt> <zielwegpunkt>
local function geheVonZuWegpunkt(src, dest)
  if not istWegBeendet() then
    brecheAktuellenWegAb()
  end
  if src == nil then
    logger.error('Fehlender Startpunkt, Abbruch!')
    return
  end
  if dest == nil then
    logger.error('Fehlendes Ziel, Abbruch!')
    return
  end
  logger.debug('gehe von '..src..' nach '..dest)
  last_start_wp = src
  geheWeg({src, dest})
end

-- args: <wegpunkt>
local function geheZuWegpunkt(dest)
  if dest == '-x' then
    brecheAktuellenWegAb()
    return
  end
  local aktWp = ermittleAktuellenStartpunkt()
  if aktWp == nil then
    logger.error('Aktueller Wegpunkt nicht bekannt!')
    return
  end
  geheVonZuWegpunkt(aktWp, dest)
end


local function geheZurueck()
  if last_start_wp == nil then
    logger.info('kein Rueckweg bekannt!')
  elseif istWegBeendet() and prio_rueckweg ~= nil then
    logger.info('zurueck ueber definierten Rueckweg')
    brecheAktuellenWegAb(true)
    local weg = prio_rueckweg
    prio_rueckweg = nil
    geheWeg(weg)
  elseif ermittleAktuellenStartpunkt() == nil then
    logger.info('aktueller Wegpunkt unbekannt, zurueck nicht moeglich')
  elseif istWegBeendet() or os.difftime(os.time(), last_back_ack_time) <= 5 then
    logger.info('zurueck nach \''..last_start_wp..'\'')
    brecheAktuellenWegAb(true)
    geheZuWegpunkt(last_start_wp)
  else
    logger.info('erneut: Abbruch und zurueck von \''..ermittleAktuellenStartpunkt()..'\' nach \''..last_start_wp..'\'')
    last_back_ack_time = os.time()
  end
end


local function setPrioRueckweg(weg)
  prio_rueckweg = weg
end


local function showStatus()
  local wegstatus = 'Weg NICHT beendet'
  if istWegBeendet() then
    wegstatus = 'Weg beendet'
  end
  logger.info(
    'Wegpunkt: '..(ermittleAktuellenStartpunkt() or '')
      .. '  |  M-7: ' .. (last_start_wp or '')
      .. '  |  '..wegstatus)
end


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.M_7 = geheZurueck


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('go',  2, geheVonZuWegpunkt)
client.createStandardAlias('go',  1, geheZuWegpunkt)
client.createStandardAlias('go',  0, continue)


-- ---------------------------------------------------------------------------
-- module definition

return {
  go = geheZuWegpunkt,
  continue = continue,
  geheWegpunkte = geheWegpunkte,
  setPrioRueckweg = setPrioRueckweg,
  showStatus = showStatus,
  def = definiereWeg,
  defx = definiereWegUndRueckweg,
  rmWeg = entferneWeg,
  defHandler = defHandler,
}
