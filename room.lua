-- room.lua - raumspezifische Funktionen
--
-- #rid      : ID für Raum global setzen
-- #ralias   : Char-spezifischen Raum-Alias setzen
-- #rnote    : In-Game-Notizen
-- #rnpc     : Default-NPC
-- #rkraut   : pflueckbares Kraut (M-6)
-- #raktion1 : Aktion (M-5)
-- #raktion2 : Aktion (M-6)
-- #rexit    : Kommando statt o/w/n/s/ob/u
-- #rfr      : raumspezifische Fluchtrichtung

local base   = require 'base'
local ME     = require 'gmcp-data'
local tools  = require 'utils.tools'

local keymap = base.keymap
local logger = client.createLogger('room')

local wp_alias = {}


-- ---------------------------------------------------------------------------
-- common state - room specific properties

local function getOrCreateRoomProperties()
  local state = base.getCommonPersistentTable('room')
  local id = ME.raum_id
  state[id] = state[id] or {}
  return state[id]
end

local function setRoomProperty(key, val)
  local props = getOrCreateRoomProperties()
  props[key] = val
  base.setCommonPersistentTableDirty()
end

local function addToRoomProperty(key, val)
  local props = getOrCreateRoomProperties()
  props[key] = props[key] or {}
  local values = props[key]
  values[#values+1] = val
  base.setCommonPersistentTableDirty()
end

local function getRoomProperty(key)
  local state = base.getCommonPersistentTable('room')
  local props = state[ME.raum_id]
  if props == nil then
    return nil
  end
  return props[key]
end


-- ---------------------------------------------------------------------------
-- char specific state

local function charSpecificState()
  return base.getPersistentTable('room')
end

local function definiereRaumAlias(alias, original)
  wp_alias[alias] = original
end

local function getPersonalWpAliases()
  charSpecificState().aliases = charSpecificState().aliases or {}
  return charSpecificState().aliases
end

local function getRaumWegpunkt()
  return getRoomProperty('wp')
end

local function createPersoenlichenWegpunktAlias(alias)
  local wp = getRaumWegpunkt()
  if wp == nil then
    logger.severe('Aktueller Wegpunkt nicht bekannt!')
    return
  end
  local wegesystemState = charSpecificState()
  wegesystemState.aliases = wegesystemState.aliases or {}
  wegesystemState.aliases[alias] = wp
  logger.info('Setze persoenlichen Alias '..alias..' fuer Wegpunkt '..wp)
end

-- sorgt fuer alias-Ersetzung, alle von aussen kommenden Wegpunkte muessen ueber
-- diese Funktion ersetzt werden
local function getWegpunktNachAliasErsetzung(wp)
  local personalAliases = getPersonalWpAliases()
  wp = personalAliases[wp] or wp
  return wp_alias[wp] or wp
end

local function getRaumIdZuWP(wegpunkt)
  local state = base.getCommonPersistentTable('room')
  for raumId,props in pairs(state) do
    if wegpunkt == props['wp'] then
      return raumId
    end
  end
  return nil
end

-- Speichert die RaumId fuer den angegebenen Wegpunkt
local function speichereRaumId(wp)
  if wp == nil then
    logger.info('Loesche Wegpunkt fuer aktuellen Raum!')
    setRoomProperty('wp', nil)
    return
  end
  -- RaumID zum Wegpunkt speichern
  local raumId = ME.raum_id
  local alterRaumName = getRaumWegpunkt()
  local vorhandenerRaumMitWp = getRaumIdZuWP(wp)
  if raumId == vorhandenerRaumMitWp then
    logger.info('Wegpunkt '..wp..' ist bereits fuer diesen Raum gesetzt.')
    return
  end
  if vorhandenerRaumMitWp ~= nil and raumId ~= vorhandenerRaumMitWp then
    logger.warn('Wegpunkt '..wp..' war bereits fuer Raum '..vorhandenerRaumMitWp..' gesetzt, entferne ihn dort!')
    base.getCommonPersistentTable('room')[vorhandenerRaumMitWp]['wp'] = nil
  end
  if alterRaumName ~= wp then
    setRoomProperty('wp', wp)
    if alterRaumName == nil then
      logger.info('Raum '..raumId..' hat jetzt Wegpunkt '..wp)
    else
      logger.warn('Raum '..raumId..' hat jetzt Wegpunkt '..wp..' (vorher '..alterRaumName..')!')
    end
  end
end

-- ausloggen der RaumIds aktivieren
local boolean logRaumIdsAktiv = false
local function logRaumIds()
  if not logRaumIdsAktiv then
    logRaumIdsAktiv = true
    base.registerEventHandler(
      'gmcp.MG.room.info',
      function()
        logger.info('Raum: ' .. (ME.raum_id or ''))
      end
    )
  end
end


-- ---------------------------------------------------------------------------
-- raumabhaengiger Standard-NPC

local function setzeRaumNPC(npc)
  setRoomProperty('npc', npc)
end

local function getRaumNPC()
  return getRoomProperty('npc')
end


-- ---------------------------------------------------------------------------
-- raumabhaengiges Label

local function setzeRaumLabel(label)
  setRoomProperty('label', label)
end

local function getRaumLabel()
  return getRoomProperty('label')
end


-- ---------------------------------------------------------------------------
-- raumabhaengige Fluchtrichtung

local function ergaenzeFlucht(flucht)
  addToRoomProperty('fr', flucht)
end

local function loescheFlucht()
  setRoomProperty('fr', nil)
end

local function getRaumFlucht()
  return getRoomProperty('fr')
end


-- ---------------------------------------------------------------------------
-- raumabhaengige Ausgaenge

local function setzeRaumSpezifischenAusgang(dir, cmd)
  local exitTable = getRoomProperty('e')
  if exitTable == nil then
    exitTable = {}
    setRoomProperty('e', exitTable)
  end
  exitTable[dir] = cmd
  base.setCommonPersistentTableDirty()
end

local function loescheRaumSpezifischeAusgaenge()
  setRoomProperty('e', nil)
end

local function getRaumspezifischenAusgang(dir)
  local exitTable = getRoomProperty('e')
  if exitTable ~= nil then
    return exitTable[dir]
  else
    return nil
  end
end

local function getRaumAusgaengeView()
  local exitTable = getRoomProperty('e')
  if exitTable == nil then
    return nil
  end
  local v = ''
  for dir,cmd in pairs(exitTable) do
    if v ~= '' then
      v = v..'+'
    end
    v = v..dir
  end
  return v
end


-- ---------------------------------------------------------------------------
-- in-game Raumnotizen

local function ergaenzeRaumNotiz(notiz)
  addToRoomProperty('n', notiz)
end

local function loescheRaumNotizen()
  setRoomProperty('n', nil)
end

local function getRaumNotizen()
  return getRoomProperty('n')
end


-- ---------------------------------------------------------------------------
-- in-game Raumaktionen

local function execAktionen(aktionen)
  if aktionen ~= nil then
    base.eval(aktionen)
  else
    logger.info('Keine Raumaktion fuer diesen Raum vorhanden.')
  end
end

local function ergaenzeRaumAktion1(aktion)
  addToRoomProperty('a1', aktion)
end

local function loescheRaumAktionen1()
  setRoomProperty('a1', nil)
end

local function getRaumAktionen1()
  return getRoomProperty('a1')
end

local function executeRaumAktionen1()
  execAktionen(getRaumAktionen1())
end

local function ergaenzeRaumAktion2(aktion)
  addToRoomProperty('a2', aktion)
end

local function loescheRaumAktionen2()
  setRoomProperty('a2', nil)
end

local function getRaumAktionen2()
  return getRoomProperty('a2')
end

local function executeRaumAktionen2()
  execAktionen(getRaumAktionen2())
end


-- ---------------------------------------------------------------------------
-- in-game Kraeuter-Infos

local function setzeRaumKraut(kraut)
  setRoomProperty('k', kraut)
end

local function loescheRaumKraut()
  setRoomProperty('k', nil)
end

local function getRaumKraut()
  return getRoomProperty('k')
end


-- ---------------------------------------------------------------------------
-- Room-Info-Ausgabe

local function addRoomInfoHelper(msg, key, data)
  if data ~= nil then
    if string.len(msg) > 0 then msg = msg .. ' / ' end
    local data_string = data
    if type(data) == 'table' then
      data_string = tools.listJoin(data, '; ')
    end
    msg = msg .. key .. ': ' .. data_string
  end
  return msg
end

local function roomInfo()
  local msg = ''
  local wp = getRaumWegpunkt()
  if wp ~= nil then
    msg = 'WP \''..wp..'\''
  end
  msg = addRoomInfoHelper(msg, 'FR', getRaumFlucht())
  msg = addRoomInfoHelper(msg, 'A1', getRaumAktionen1())
  msg = addRoomInfoHelper(msg, 'A2', getRaumAktionen2())
  msg = addRoomInfoHelper(msg, 'K', getRaumKraut())
  msg = addRoomInfoHelper(msg, 'N', getRaumNotizen())
  msg = addRoomInfoHelper(msg, 'E', getRaumAusgaengeView())
  if string.len(msg) > 0 then
    logger.info(msg)
  end
end

base.registerEventHandler('gmcp.MG.room.info', roomInfo)


local function showStatus()
  local msg = 'Region: '..ME.raum_region..' / Raum-Id: '..(ME.raum_id_short or '')
  local label = getRaumLabel()
  if label ~= nil then
    msg = msg..' / Label: '..label
  end
  logger.info(msg)
  local notizen = getRaumNotizen()
  if notizen ~= nil then
    local notizenMsg = addRoomInfoHelper('', 'Notiz', notizen)
    logger.info(notizenMsg)
  end
end


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.M_5 = executeRaumAktionen1
keymap.M_6 = executeRaumAktionen2


-- ---------------------------------------------------------------------------
-- Aliases

-- Raum-ID setzen
client.createStandardAlias('rid', 1, speichereRaumId)
client.createStandardAlias('ridrm', 0, speichereRaumId)
-- persoenlichen Raum-Alias für aktuellen Raum setzen
client.createStandardAlias('ralias', 1, createPersoenlichenWegpunktAlias)
-- raumspezifische Ausgaenge
client.createStandardAlias('rexit', 2, setzeRaumSpezifischenAusgang)
client.createStandardAlias('rexitrm', 0, loescheRaumSpezifischeAusgaenge)
-- raumspezifische Fluchtrichtung
client.createStandardAlias('rfr', 1, ergaenzeFlucht)
client.createStandardAlias('rfrrm', 0, loescheFlucht)
-- NPC
client.createStandardAlias('rnpc', 1, setzeRaumNPC)
client.createStandardAlias('rnpcrm', 0, setzeRaumNPC)
-- Label
client.createStandardAlias('rlabel', 1, setzeRaumLabel)
client.createStandardAlias('rlabelrm', 0, setzeRaumLabel)
-- Raumnotiz
client.createStandardAlias('rnote', 1, ergaenzeRaumNotiz)
client.createStandardAlias('rnoterm', 0, loescheRaumNotizen)
-- Raumaktion
client.createStandardAlias('raktion1', 1, ergaenzeRaumAktion1)
client.createStandardAlias('raktion1rm', 0, loescheRaumAktionen1)
client.createStandardAlias('raktion2', 1, ergaenzeRaumAktion2)
client.createStandardAlias('raktion2rm', 0, loescheRaumAktionen2)
-- Raum-Kraut
client.createStandardAlias('rkraut', 1, setzeRaumKraut)
client.createStandardAlias('rkrautrm', 0, loescheRaumKraut)
-- RaumIds ausloggen
client.createStandardAlias('rlog', 0, logRaumIds)


-- ---------------------------------------------------------------------------
-- module definition

return {
  getWegpunktNachAliasErsetzung = getWegpunktNachAliasErsetzung,
  getRaumWegpunkt = getRaumWegpunkt,
  getRaumIdZuWP = getRaumIdZuWP,
  roomAlias = definiereRaumAlias,
  execAction1 = executeRaumAktionen1,
  execAction2 = executeRaumAktionen2,
  getCmdForExit = getRaumspezifischenAusgang,
  getEscape = getRaumFlucht,
  getHerb = getRaumKraut,
  getLabel = getRaumLabel,
  getNPC = getRaumNPC,
  showStatus = showStatus,
}
