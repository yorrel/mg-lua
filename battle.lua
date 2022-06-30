-- Kampfspezifischer Code

local base  = require 'base'
local ME    = require 'gmcp-data'
local room  = require 'room'

local logger = client.createLogger('battle')
local keymap = base.keymap

local function state()
  return base.getPersistentTable('utils')
end


-- ---------------------------------------------------------------------------
-- Kampferkennung

local lastKampfAktion = os.time() - 10

-- global: wird auch von tf aus aufgerufen
local function kampfAktionErkannt()
  lastKampfAktion = os.time()
end

local function istImKampf()
  return os.difftime(os.time(), lastKampfAktion) <= 4
end

local PRIO_KAMPF_ERKENNUNG = 5000

client.createRegexTrigger('^  Du greifst .* mit .* an\\.$', kampfAktionErkannt, {'F'}, PRIO_KAMPF_ERKENNUNG)
client.createRegexTrigger('^  .* greift Dich mit .* an\\.$', kampfAktionErkannt, {'F'}, PRIO_KAMPF_ERKENNUNG)
client.createRegexTrigger('^  Du (verfehlst|kitzelst|kratzt|triffst|schlaegst|zerschmetterst|pulverisierst|zerstaeubst|atomisierst|vernichtest) ', kampfAktionErkannt, {'F'}, PRIO_KAMPF_ERKENNUNG)
client.createRegexTrigger('^  .* (verfehlt|kitzelt|kratzt|trifft|schlaegt|zerschmettert|pulverisiert|zerstaeubt|atomisiert|vernichtet) Dich', kampfAktionErkannt, {'F'}, PRIO_KAMPF_ERKENNUNG)


-- ---------------------------------------------------------------------------
-- Vorsicht / Flucht durch Client

local letzteFlucht = os.time() - 10

local function fluechte()
  local raumSpezifischeFlucht = room.getEscape()
  if raumSpezifischeFlucht == nil then
    client.send(state().fluchtrichtung)
  else
    base.eval(raumSpezifischeFlucht)
  end
end

local function utilsKampfLpKpListener()
  local vs = state().vorsicht
  if istImKampf() and vs ~= nil and ME.lp <= vs then
    local now = os.time()
    if os.difftime(now, letzteFlucht) >= 8 then
      logger.info('Flucht! (Fluchtsperre 8 sec)')
      fluechte()
      letzteFlucht = now
    end
  end
end

base.registerEventHandler('gmcp.MG.char.vitals', utilsKampfLpKpListener)

local function setVorsicht(vorsicht)
  vorsicht = vorsicht or 0
  logger.info('Vorsicht: '..vorsicht)
  state().vorsicht = tonumber(vorsicht)
  base.raiseEvent('gmcp.MG.char.wimpy')
end

local function setFluchtrichtung(flucht)
  flucht = flucht or ''
  logger.info('Flucht: '..flucht)
  state().fluchtrichtung = flucht
  base.raiseEvent('gmcp.MG.char.wimpy')
end

local last_vorsicht = nil

local function checkMudWimpyState()
  if not istImKampf() then
    last_vorsicht = ME.vorsicht
  end
  if istImKampf() and last_vorsicht ~= nil and ME.vorsicht ~= last_vorsicht then
    logger.warn('Vorsicht manipuliert -> setze zurueck auf ' .. last_vorsicht)
    client.send('vorsicht ' .. last_vorsicht)
  end
end

base.registerEventHandler('gmcp.MG.char.wimpy', checkMudWimpyState)


-- ---------------------------------------------------------------------------
-- Fokus

local gegner

local function fokus_reset_gegner()
  gegner = nil
end

local function fokus_set_gegner(npc)
  gegner = npc
  logger.info('Fokus: '..gegner)
end

local function getGegner()
  return gegner or room.getNPC() or ''
end

local function untersucheFokusGegner()
  client.send ('unt '..getGegner())
end


-- ---------------------------------------------------------------------------
-- Info

local function printKampfStatus()
  logger.info('Fokus         [#f]  : '..(getGegner() or ''))
end

  
-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.M_0 = untersucheFokusGegner


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('vs', 1, setVorsicht)
client.createStandardAlias('fr', 1, setFluchtrichtung)
client.createStandardAlias('f',  0, fokus_reset_gegner)
client.createStandardAlias('f',  1, fokus_set_gegner)


-- ---------------------------------------------------------------------------
-- module definition

return {
  setVorsicht = setVorsicht,
  setFluchtrichtung = setFluchtrichtung,
  getGegner = getGegner,
  istImKampf = istImKampf,
  kampfStatus = printKampfStatus,
}
