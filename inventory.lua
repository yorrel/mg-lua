-- Inventar / Items verwalten

--  - Verwaltung der Ausruestung eines Chars
--  - effizientes Umruesten
--  - konfigurierbare Abkürzungen für alle Item-Typen
--
-- Container
--  - man kann jederzeit frei neue Container mit einem Kürzel einführen und verwenden
--  - Zu einigen Standard-Containern sind zusätzliche Funktionen vorhanden, z.B. wird
--    der Standard-Container für Waffen für das Waffenwechseln verwendet.
--  - Die Standard-Container sind:
--    default, tmp, waffen, zauberkompos, chaoskompos
--  - Auf die Standard-Container kann auch über die Modul-API zugegriffen werden.

local base   = require 'base'
local itemdb = require 'itemdb'
local tools  = require 'utils.tools'

local logger = client.createLogger('inv')
local keymap = base.keymap
local ME     = require 'gmcp-data'


-- listener fuer andere module
local waffenwechsel_listener = {}
local function add_waffenwechsel_listener(id, f)
   waffenwechsel_listener[id] = f
end


local init_done = false
local function init_inventar()
  if init_done then
    return
  end
  local state = base.getPersistentTable('items')
  state.ruestung = state.ruestung or {}
  state.configkeys = state.configkeys or {}
  state.config = state.config or {}
  state.waffe_haende = state.waffe_haende or 1
  state.freehands = state.freehands or false
  init_done = true
end

-- zustand des packages
local function state()
  init_inventar()
  return base.getPersistentTable('items')
end


-- ---------------------------------------------------------------------------
-- Container

local function container()
  return base.getPersistentTable('container')
end

local container_std_abk = {
   g = 'guertel',
   k = 'koecher',
   v = 'bovist',
   wg = 'waffenguertel',
   t = 'truhe',
   ko = 'kommode',
   sp = 'spind',
   ks = 'kleiderschrank',
   wt = 'waffentruhe',
   ws = 'waffenschrank',
   zk = 'zauberkiste',
}

-- auf diese Container wird auch von aussen zugegriffen
local standard_container = {
  default = 'r',
  tmp = 'b',
  waffen = 'w',
  chaoskompos = 'c',
  zauberkompos = 'z',
}

local itemDefaultContainer = function() end

local function setItemDefaultContainer(f)
  itemDefaultContainer = f
end

local function cont(id)
  local std = standard_container.default
  return container()[id] or container_std_abk[id] or container()[std]
end

local function containerWechseln(id, neuerContainer)
  local vorigerContainer = cont(id)
  logger.info('Container \''..id..'\' wechseln auf \''..neuerContainer..'\'')
  container()[id] = neuerContainer
  if vorigerContainer ~= nil then
    client.send('stecke alles aus '..vorigerContainer..' in '..neuerContainer)
  end
end

local function standardCont(typ)
  return cont(standard_container[typ])
end

local function setStandardCont(typ, newVal)
  local id = standard_container[typ]
  container()[id] = newVal
end

-- fuer spezielle items koennen eigene default container definiert werden
local function getItemContainer(item, id)
  local itemCont = itemDefaultContainer(item)
  if id == standard_container.default and itemCont ~= nil then
    return itemCont
  else
    return cont(id)
  end
end

-- allgemeines move von ggst.
-- '-' bedeutet 'in mir'
local function moveItem(von, nach, item)
  if von ~= '-' and nach == '-' then
    local vonCont = getItemContainer(item, von)
    client.send('nimm '..item..'  aus '..vonCont)
  elseif von == '-' and nach ~= '-' then
    local nachCont = getItemContainer(item, nach)
    client.send('stecke '..item..' in '..nachCont)
  else
    local vonCont = getItemContainer(item, von)
    local nachCont = getItemContainer(item, nach)
    client.send('stecke '..item..' aus '..vonCont..' in '..nachCont)
  end
end

-- item aus container ablegen, args: cont_id, item
local function itemAblegen(id, item)
  local idCont = getItemContainer(item, id)
  client.send('lege '..item..' aus '..idCont..' ab')
end
local function containerInfo(id)
  client.send('unt '..cont(id))
end
local function containerOeffnen(id)
  client.send('oeffne '..cont(id))
end
local function containerSchliessen(id)
  client.send('schliesse '..cont(id))
end

local function is_waffe_aktiv()
  return state().waffe_haende > 0 and state().waffe ~= nil
end
local function is_schild_aktiv()
  return state().waffe_haende < 2 and state().schild ~= nil
end


-- Pruefung ob Items in Container verschoben bzw. abgegeben werden koennen
local sticky = itemdb.isSticky


-- BELEGUNG DER HAENDE -------------------------------------------------------

local function waffe_zuecken()
  if is_waffe_aktiv() then
    client.send('zuecke '..state().waffe)
  end
end

local function waffe_wegstecken()
  if is_waffe_aktiv() then
    client.send('stecke '..state().waffe..' zurueck')
  end
end

local function schild_tragen()
  if is_schild_aktiv() then
    client.send('trage '..state().schild)
  end
end

local function schild_ausziehen()
  if is_schild_aktiv() then
    client.send('ziehe '..state().schild..' aus')
  end
end


local function haendeToggle(optFreeHands)
  if optFreeHands == state().freehands then
    return
  end
  state().freehands = not state().freehands
  if state().freehands then
    waffe_wegstecken()
    schild_ausziehen()
  else
    schild_tragen()
    waffe_zuecken()
  end
end


-- HAENDE KURZ FREIMACHEN ----------------------------------------------------

local doWithHandsAktiv = false
local doHandSperreBis = os.time() - 100
local schildBetroffen = false

local function defaultHerstellenNachDoHands()
  logger.debug('doWithHand zueck-pruefung')
  if os.time() >= doHandSperreBis then
    if schildBetroffen then
      schild_tragen()
    end
    waffe_zuecken()
    doWithHandsAktiv = false
  else
    client.createTimer(1, defaultHerstellenNachDoHands)
  end
end

-- macht n haende frei und fuehrt cmd aus
-- cmd ist function oder string (der gesendet wird)
-- optDelay: Anzahl sec Pause bis Aktivierung Waffe/Schild nach cmd
local function doWithHands(n, cmd, optDelay)
  if type(cmd) == 'string' then
    logger.debug('doWithHands mit '..n..' Haenden: '..cmd)
  end
  if state().freehands then
    base.eval(cmd)
    return
  end

  -- schild erst nicht betroffen, erst bei 2. aufruf
  if doWithHandsAktiv and not schildBetroffen and n==2 then
    schildBetroffen = true
    schild_ausziehen()
  end

  if not doWithHandsAktiv then
    waffe_wegstecken()
    schildBetroffen = n==2
    if schildBetroffen then
      schild_ausziehen()
    end
  end

  doWithHandsAktiv = true
  base.eval(cmd)

  if optDelay ~= nil then
    doHandSperreBis = math.max(doHandSperreBis, os.time()+optDelay)
  end

  defaultHerstellenNachDoHands()
end


-- ----------------------------------------------------------------------
-- WAFFEN WECHSELN

local zueck_funktionen = {
  koecher = {
    wegstecken = function(w) end,
    holeUndZuecke = function(w) client.send('kzueck '..w) end
  },
  kriegerbeutel = {
    wegstecken = function(w) end,
    holeUndZuecke = function(w) client.send('zueck '..w..' aus kb') end
  },
  kb = {
    wegstecken = function(w) end,
    holeUndZuecke = function(w) client.send('zueck '..w..' aus kb') end
  }
}

local defaultZueckFunktion = {
  wegstecken = function(w)
    client.send('stecke '..w..' in mir in '..standardCont('waffen'))
  end,
  holeUndZuecke = function(w)
    client.send('nimm '..w..' aus '..standardCont('waffen'))
    client.send('zuecke '..w)
  end
}

local function getZueckFunktion()
  local zueckFunktion = zueck_funktionen[standardCont('waffen')]
  if zueckFunktion ~= nil then
    return zueckFunktion
  end
  return defaultZueckFunktion
end

-- Hilfsfunktion um aktuelle Waffe wieder aufzunehmen und zu zuecken
local function waffenAufnehmen()
  client.send('nimm '..state().waffe)
  if not state().freehands then
    client.send('zuecke '..state().waffe)
  end
end


-- Variablen zur aktuellen default Waffe setzen (items.waffe usw.)
-- Dabei kann <waffe> eine definierte ID sein (dann wird die Anzahl Haende
-- sowie Schadensarten aus der Waffenliste genommen), oder ein beliebiger Name
-- optional gefolgt von der Anzahl Haende.
-- Die Anzahl Haende kann auch bei bekannten Waffen aus der Waffenliste mit
-- angegeben werden und wird dann anstatt der Standardanzahl verwendet.
-- arg: id_oder_langname anzahl_haende_als_number
local function setDefaultWaffe(id, optHaende)
  if not id then
    state().waffe_default = nil
    state().waffe_haende = 0
    state().waffe_damage = {}
  else
    local werte = itemdb.waffe(id)
    if werte ~= nil then
      state().waffe_default = werte.long
      state().waffe_damage = werte.damage
      state().waffe_haende = optHaende or werte.hands
    else
      state().waffe_default = id
      state().waffe_damage = {}
      state().waffe_haende = optHaende or 2
    end
  end
  logger.info('default waffe: '..(state().waffe_default or '')..', '..state().waffe_haende..'h')
  for _,f in pairs(waffenwechsel_listener) do
    f()
  end
end


-- Wechselt auf die angegebene Waffe, die eingestellte default-Waffe
-- ist von diesem Wechsel nicht beeinflusst.
-- Schild und Anzahl noetiger Haende werden nicht beruecksichtigt.
-- args: waffenname (* steht fuer default-Waffe, nil fuer Hand als Waffe)
local function wechselAufWaffe(waffeNeu)
  local waffeAlt = state().waffe
  if waffeNeu == '*' then
    waffeNeu = state().waffe_default
  end
  if waffeNeu == waffeAlt then
    return
  end

  local waffeGezueckt = not state().freehands
  local zueckFunktion = getZueckFunktion()
  local stickyAlt = waffeAlt ~= nil and sticky(waffeAlt)
  local stickyNeu = waffeNeu ~= nil and sticky(waffeNeu)
  if waffeAlt ~= nil then
    if (not waffeGezueckt or waffeNeu == nil or stickyNeu) and not stickyAlt then
      defaultZueckFunktion.wegstecken(waffeAlt)
    elseif waffeGezueckt and stickyAlt then
      client.send('stecke '..waffeAlt..' zurueck')
    else
      zueckFunktion.wegstecken(waffeAlt)
    end
  end
  if waffeNeu ~= nil then
    if waffeGezueckt and stickyNeu then
      client.send('zuecke '..waffeNeu)
    elseif waffeGezueckt and not stickyNeu then
      zueckFunktion.holeUndZuecke(waffeNeu)
    elseif not waffeGezueckt and not stickyNeu then
      client.send('nimm '..waffeNeu..' aus '..standardCont('waffen'))
    end
  end
  state().waffe = waffeNeu
end

local function wechselAufDefaultWaffe()
  wechselAufWaffe(state().waffe_default)
end

local function aktuellesSchildWegstecken()
  if not sticky(state().schild) and state().waffe_haende<2 and state().schild ~= nil then
    client.send('stecke '..state().schild..' in mir in '..standardCont('default'))
  elseif state().waffe_haende<2 and state().schild ~= nil then
    client.send('ziehe '..state().schild..' aus')
  end
end

-- wechsel schild
local function aktuellesSchildTragen(newSchild)
  state().schild = newSchild
  if state().schild ~= nil and not sticky(state().schild) and state().waffe_haende<2 then
    client.send('nimm '..state().schild..' aus '..standardCont('default'))
  end
  if state().schild ~= nil and not state().freehands then
    client.send('trage '..state().schild)
  end
end

-- wechsel schild
local function entferneSchild()
  logger.info('entferne Schild')
  aktuellesSchildWegstecken()
  state().schild = nil
end

-- wechsel schild
local function wechselSchild(id)
  local newSchild = itemdb.schild(id) or id
  logger.info('wechsel schild auf '..id..' -> '..(newSchild or ''))
  aktuellesSchildWegstecken()
  aktuellesSchildTragen(newSchild)
end


local function wechselItemFallsNoetig(typ, item, force)
  local actval = state().ruestung[typ] or ''
  if item ~= nil then
    item = itemdb.item(typ, item)
    if item == nil then
      return
    end
  end
  local newval = item or ''
  if actval == newval and not force then
    logger.info('Umruesten '..typ..': ('..actval..')')
    return
  end
  if actval ~= '' then
    if sticky(actval) then
      client.send('ziehe '..actval..' aus')
    else
      client.send('stecke '..actval..' in mir in '..standardCont('default'))
    end
  end
  if newval ~= '' then
    if not sticky(newval) then
      client.send('nimm '..newval..' aus '..standardCont('default'))
    end
    client.send('trage '..newval)
  end
  state().ruestung[typ] = newval
  logger.info('Umruesten '..typ..' : '..actval..' -> '..newval)
end

-- wechsel Waffe (erst schild, dann waffe wg. 1/2 h Waffen wie SpMS)
-- es gibt ggf. Sonderfaelle (z.B. wenn Koecher verwendet wird)
-- hier wird die default-Waffe neu gesetzt und auf sie gewechselt
local function wechselWaffe(id, optHaende)
  local _h_alt = state().waffe_haende
  setDefaultWaffe(id, optHaende)
  local schild = state().schild
  if schild ~= nil and _h_alt<2 and state().waffe_haende==2 then
    if not sticky(schild) then
      client.send('stecke '..schild..' in mir in '..standardCont('default'))
    else
      client.send('ziehe '..schild..' aus')
    end
  end
  wechselAufWaffe(state().waffe_default)
  if schild ~= nil and _h_alt==2 and state().waffe_haende<2 then
    if not sticky(schild) then
      client.send('nimm '..schild..' aus '..standardCont('default'))
    end
    if not state().freehands then
      client.send('trage '..schild)
    end
  end
end

local function wechselWaffeUI(s)
  local args, flags = tools.parseArgs(s)
  local haende = flags[1] == '-1' and 1 or flags[1] == '-2' and 2
  local waffe = tools.listJoin(args, ' ')
  wechselWaffe(waffe, haende)
end


-- ---------------------------------------------------------------------------
-- Info

local function freehands_tostring()
  if state().freehands then
    return '[-]'
  else
    return '[+]'
  end
end

local function printWaffenStatus()
  local waffe = state().waffe or ''
  local waffenhaende = state().waffe_haende or '?'
  local schild = state().schild or ''
  local schadenstring = ''
  if state().waffe_damage ~= nil then
    schadenstring = table.concat(state().waffe_damage, '+')
  end
  logger.info('Waffe         [#ww] : '..freehands_tostring()..' '..waffe..', '..waffenhaende..'h')
  logger.info('      Schadensarten   '..schadenstring)
  logger.info('Schild:       [#ws] : '..freehands_tostring()..' '..schild)
end

local function printItemStatus()
  logger.info('--------Items-----------------------------------------------')
  local waffe = state().waffe or ''
  local waffenhaende = state().waffe_haende or '?'
  local schild = state().schild or ''
  logger.info('Waffe:        [#ww] : '..freehands_tostring()..' '..waffe..', '..waffenhaende..'h')
  logger.info('Schild:       [#ws] : '..freehands_tostring()..' '..schild)
  for _, typ in ipairs(itemdb.typen()) do
    local typName = itemdb.typLangname(typ) or ''
    local typNameFixLength = string.sub(typName..'                  ',1,13)
    logger.info(typNameFixLength..' [#w '..typ..']: '..(state().ruestung[typ] or ''))
  end
  logger.info('  Item-Konfigs: '..table.concat(state().configkeys, ','))
  logger.info('  [#k waehlen / #wi diese Anzeige / #kl Konfigs zeigen]')
end

local function wechselItemUI(s)
  local args, flags = tools.parseArgs(s)
  if flags[1] == '-l' then
    printItemStatus()
  else
    local typ = table.remove(args, 1) or ''
    if not itemdb.typLangname(typ) then
      logger.warn('Typ \''..typ..'\' unbekannt!')
    else
      local item = tools.listJoin(args, ' ')
      wechselItemFallsNoetig(typ, item, true)
    end
  end
end


-- ---------------------------------------------------------------------------
-- Kampf-Konfigurationen
-- Konfiguration von Items mit einer ID versehen

-- aktuelle Konf. unter angegebenem Namen speichern
local function itemConfigSave(id)
  logger.info('Kampfkonfiguration speichern unter '..id)
  local copy = {}
  for k,v in pairs(state().ruestung) do
    copy[k] = v
  end
  if state().config[id] == nil then
    state().configkeys[#state().configkeys + 1] = id
  end 
  state().config[id] = copy
end

-- auf angegebene Konf. umruesten
local function itemConfigSwitch(id)
  logger.info('Kampfkonfiguration wechseln auf '..id)
  local _k = state().config[id]
  if _k ~= nil then
    for typ,value in pairs(_k) do
      wechselItemFallsNoetig(typ, value)
    end
  else
    logger.error('Kampfkonfiguration '..id..' nicht vorhanden!')
  end
end

-- angegebene Konf. loeschen
local function itemConfigRemove(id)
  state().config[id] = nil
  for i,e in ipairs(state().configkeys) do
    if e == id then
      table.remove(state().configkeys, i)
      return
    end
  end
end

-- alle gespeicherten Konfigurationen anzeigen
local function itemConfigShow()
  logger.info('Kampfkonfiguration-Keys: '..table.concat(state().configkeys, ','))
end

local function itemConfigUI(s)
  local args, flags = tools.parseArgs(s)
  local configName = tools.listJoin(args, ' ')
  local cmd = flags[1]
  if not cmd then
    itemConfigSwitch(configName)
  elseif cmd == '-w' then
    itemConfigSave(configName)
  elseif cmd == '-rm' then
    itemConfigRemove(configName)
  elseif cmd == '-l' then
    itemConfigShow()
  end
end


-- ---------------------------------------------------------------------------
-- Zugriff auf aktuelle Items

local function getWaffe()
  return state().waffe
end

local function getSchild()
  if state().waffe_haende < 2 then
    return state().schild
  end
  return nil
end

local function getWaffenschaden()
  return state().waffe_damage
end

local function getRuestung(typ)
  return state().ruestung[typ]
end

local function getRuestungen(typen)
  local items = {}
  for _,typ in pairs(typen) do
    local item = getRuestung(typ)
    if item ~= nil then
      items[#items+1] = item
    end
  end
  return items
end

local function getAlleRuestungen()
  return getRuestungen(itemdb.typen())
end


-- ---------------------------------------------------------------------------
-- reboot / reset

local function reset()
  for k,_ in pairs(container()) do
    container()[k] = nil
  end
  local state = state()
  state.waffe = nil
  state.waffe_default = nil
  state.waffe_haende = 1
  state.waffe_damage = {}
  state.freehands = true
  state.schild = nil
  state.ruestung = {}
  state.configkeys = {}
  state.config = {}
end

base.addResetHook(reset)


-- ---------------------------------------------------------------------------
-- Tastenbelegung

-- waffe+schild an/aus
keymap.F11 = haendeToggle


-- ---------------------------------------------------------------------------
-- Aliases

-- waffe und ruestungen
client.createStandardAlias('ww', 1,  wechselWaffeUI)
client.createStandardAlias('ww', 0,  wechselWaffe)
client.createStandardAlias('ws', 1,  wechselSchild)
client.createStandardAlias('ws', 0,  entferneSchild)
client.createStandardAlias('w', 1,  wechselItemUI)

-- konfigs
client.createStandardAlias('k', 1, itemConfigUI)

-- container-handling
client.createStandardAlias('c', 3,   moveItem)
client.createStandardAlias('cl', 2,  itemAblegen)
client.createStandardAlias('ci', 1,  containerInfo)
client.createStandardAlias('co', 1,  containerOeffnen)
client.createStandardAlias('cc', 1,  containerSchliessen)
client.createStandardAlias('cont', 2, containerWechseln)

-- items bewegen
client.createStandardAlias('bn', 1,  function(item) moveItem('b', '-', item) end)
client.createStandardAlias('bs', 1,  function(item) moveItem('-', 'b', item) end)
client.createStandardAlias('bl', 1,  function(item) itemAblegen('b', item) end)
client.createStandardAlias('rn', 1,  function(item) moveItem('r', '-', item) end)
client.createStandardAlias('rs', 1,  function(item) moveItem('-', 'r', item) end)
client.createStandardAlias('rl', 1,  function(item) itemAblegen('r', item) end)
client.createStandardAlias('tn', 1,  function(item) moveItem('t', '-', item) end)
client.createStandardAlias('ts', 1,  function(item) moveItem('-', 't', item) end)
client.createStandardAlias('gn', 1,  function(item) moveItem('g', '-', item) end)
client.createStandardAlias('gs', 1,  function(item) moveItem('-', 'g', item) end)

client.createStandardAlias('b2r', 1,  function(item) moveItem('b', 'r', item) end)
client.createStandardAlias('r2b', 1,  function(item) moveItem('r', 'b', item) end)
client.createStandardAlias('b2t', 1,  function(item) moveItem('b', 't', item) end)
client.createStandardAlias('t2b', 1,  function(item) moveItem('t', 'b', item) end)
client.createStandardAlias('r2t', 1,  function(item) moveItem('r', 't', item) end)
client.createStandardAlias('t2r', 1,  function(item) moveItem('t', 'r', item) end)

local function stdContGetSetFunc(typ)
  return
    function(newVal)
      if newVal ~= nil then
        setStandardCont(typ, newVal)
      end
      return standardCont(typ)
    end
end

local function getRuestungFunction(id)
  return
    function()
      return getRuestung(id)
    end
end

return {
  cont = {
    default      = stdContGetSetFunc('default'),
    tmp          = stdContGetSetFunc('tmp'),
    waffen       = stdContGetSetFunc('waffen'),
    zauberkompos = stdContGetSetFunc('zauberkompos'),
    chaoskompos  = stdContGetSetFunc('chaoskompos')
  },
  setItemDefaultContainer = setItemDefaultContainer,
  waffe = getWaffe,
  schild = getSchild,
  ruestung = {
    helm       = getRuestungFunction('k'),
    handschuhe = getRuestungFunction('h'),
    umhang     = getRuestungFunction('u'),
    schuhe     = getRuestungFunction('s'),
  },
  ruestungen = getRuestungen,
  alleRuestungen = getAlleRuestungen,
  waffenschaden = getWaffenschaden,
  addWaffenwechselListener = add_waffenwechsel_listener,
  wechselWaffe = wechselAufWaffe,
  zueckeDefaultWaffe = wechselAufDefaultWaffe,
  waffenAufnehmen = waffenAufnehmen,
  waffenStatus = printWaffenStatus,
  doWithHands = doWithHands,
  freeHands = function() haendeToggle(true) end,
}
