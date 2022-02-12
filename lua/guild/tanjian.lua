-- Tanjian

local base   = require 'base'
local inv    = require 'inventory'
local timer  = require 'timer'
local kampf  = require 'battle'

local logger = client.createLogger('tanjian')
local keymap = base.keymap


local function state()
  return base.getPersistentTable('tanjian')
end


-- ---------------------------------------------------------------------------
-- Reboot

base.addResetHook('tanjianreport ein')


-- ---------------------------------------------------------------------------
-- Skills

local kamiSchaeden = {
  te = 'angst',
  ma = 'magie',
  sa = 'saeure',
  kr = 'laerm',
  bl = 'blitz',
  ei = 'eis',
  fe = 'feuer',
  gi = 'gift',
  wa = 'wasser',
  lu = 'wind',
}

local function tanjian_set_kamischaden(id)
  local art = kamiSchaeden[id] or id
  state().kamischaden = art
  logger.info('Kami-Schaden: '..(art or ''))
end

-- schadensart-ermittlung fuer kami
local function get_kami_schaden()
  -- explizit konfiguriert
  local art = state().kamischaden
  if art ~= nil and art ~= '' and art ~= '*' then
    return art
  end
  -- vom Waffenschaden abgeleitet
  for _,art in pairs(inv.waffenschaden()) do
    if kamiSchaeden[art] ~= nil then
      return kamiSchaeden[art]
    end
  end
  return nil
end

local function angriff_kami()
  local art = get_kami_schaden()
  client.send('kami '..(art or '')..' '..kampf.getGegner())
end


local function tanjian_kiri()
  inv.doWithHands(2, 'kiri', 3)
end


local akshara_aktiv = false

local function toggle_akshara()
  local hs_a = state().akshara_handschuhe
  local hs = inv.ruestung.handschuhe()
  if not akshara_aktiv then
    inv.wechselWaffe(nil)
    if hs ~= nil and hs ~= hs_a then
      client.send('ziehe '..hs..' aus')
    end
    if hs_a ~= nil and hs ~= hs_a then
      client.send('nimm '..hs_a..' aus '..inv.cont.default())
      client.send('trage '..hs_a)
    end
    client.send('akshara')
  else
    if hs_a ~= nil and hs ~= hs_a then
      client.send('stecke '..hs_a..' in '..inv.cont.default())
    end
    if hs ~= nil and hs ~= hs_a then
      client.send('trage '..hs)
    end
    inv.zueckeDefaultWaffe()
  end
  akshara_aktiv = not akshara_aktiv
end

local function setAksharaHandschuhe(item)
  state().akshara_handschuhe = item
end

-- ---------------------------------------------------------------------------
-- Trigger

client.createSubstrTrigger('Die Ausfuehrung Deines vorbereiteten Spruches wird verzoegert.', nil, {'cyan'})

client.createSubstrTrigger('Du bist derzeit in der Parallelwelt.', nil, {'blue'})
client.createRegexTrigger('Du bist derzeit in Parallelwelt Nr\\. (\\d*)\\.', nil, {'blue'})

-- meditation
client.createSubstrTrigger('Du beendest Deine Meditation.', nil, {'green'})
client.createSubstrTrigger('Deine Konzentrationsfaehigkeit laesst langsam nach.', nil, {'yellow'})
client.createSubstrTrigger('Deine Umgebung scheint sich auf Deine Meditation auszuwirken.', nil, {'green'})
client.createSubstrTrigger('Du solltest mal wieder meditieren.', nil, {'red'})
client.createSubstrTrigger('Du spuerst noch die Wirkung der letzten Meditation.', nil, {'blue'})

-- kokoro
client.createSubstrTrigger('Die Dunkelheit loest sich von Deinem Geist.', nil, {'green'})
client.createSubstrTrigger('Die Membran schwingt doch noch!', nil, {'green'})
client.createSubstrTrigger('Die Energien des Kokoro versiegen.', nil, {'red'})

-- tegatana, omamori, hayai
client.createSubstrTrigger('Du konzentrierst Dich auf den Kampf.', nil, {'green'})
client.createSubstrTrigger('Deine Kampf-Konzentration laesst nach.', nil, {'red'})
client.createSubstrTrigger('Du konzentrierst Dich auf die Abwehr.', nil, {'green'})
client.createSubstrTrigger('Deine Abwehr-Konzentration laesst nach.', nil, {'red'})
client.createSubstrTrigger('Der Zeitfluss veraendert sich', nil, {'green'})
client.createSubstrTrigger('Die Kontrolle ueber den Zeitfluss entgleitet Dir.', nil, {'red'})

client.createRegexTrigger(
  'Deine Haende fangen ploetzlich an, .* zu leuchten.',
  function()
    timer.enqueue(
      150,
      function()
        logger.info('Akshara wieder moeglich')
      end
    )
  end,
  {'green'})
client.createSubstrTrigger('Du verlaesst den Pfad des Lichtes.', nil, {'red'})

-- Clan Nekekami
client.createSubstrTrigger('Du huellst Dich in einen schuetzenden Nebel.', nil, {'green'})
client.createSubstrTrigger('Du bist noch in einen Nebel gehuellt.', nil, {'green'})
client.createSubstrTrigger('Der Nebel loest sich auf.', nil, {'red'})


-- ---------------------------------------------------------------------------
-- Statuszeile

base.statusAdd('meditation', '_', true)
base.statusAdd('gesinnung', '_', true)
base.statusAdd('kokoro', '__', true)
base.statusAdd('tegatana', '__', true)
base.statusAdd('hayai', '__', true)
base.statusAdd('akshara', '__', true)
base.statusAdd('rest', '____', true)

local function statusZeile1(m)
  base.statusUpdate('meditation', m[4], true)
  base.statusUpdate('gesinnung', m[3], true)
  base.statusUpdate('kokoro', m[5], true)
  base.statusUpdate('tegatana', m[6], true)
  base.statusUpdate('hayai', m[7], true)
  base.statusUpdate('akshara', m[8], true)
end

local function statusZeile2(m)
  base.statusUpdate('rest', m[1], true)
end

client.createRegexTrigger('^STATUS1: ([0-9]*) ([0-9]*) (.) (.) (..) (..) (..) (..)', statusZeile1, {'g'})
client.createRegexTrigger('^STATUS2: (....) ([0-9]+) (.+)', statusZeile2, {'g'})


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

local function tanjian_info()
  logger.info('Kami-Schaden  [#cs] : '..(get_kami_schaden() or ''))
  logger.info('Akshara-Hdsch.[#akh]: '..(state().akshara_handschuhe or ''))
  client.send('tanjiantest')
end

base.gilde.info = tanjian_info
base.gilde.schaetz = 'koryoku'
base.gilde.identifiziere = 'koryoku'
base.gilde.entsorgeLeiche = 'entsorge leiche'


-- ---------------------------------------------------------------------------
-- Tastenbelegung

local function createFunctionMitGegner(cmd)
  return
    function()
      client.send(cmd..' '..kampf.getGegner())
    end
end

keymap.F5 = createFunctionMitGegner('samusa')
keymap.S_F5 = createFunctionMitGegner('kshira')
keymap.F6 = createFunctionMitGegner('kaminari')
keymap.F7 = createFunctionMitGegner('arashi')
keymap.F8 = angriff_kami

keymap.M_k = 'kokoro'
keymap.M_t = 'tegatana'
keymap.M_v = 'omamori'
keymap.M_m = tanjian_kiri
keymap.M_x = 'hayai'
keymap.M_r = toggle_akshara

keymap.M_z = 'meditation'


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias(
  'skills',
  0,
  function()
    client.send('tm siamil faehigkeiten')
    client.send('tm siamil waffenfaehigkeiten')
  end
)
client.createStandardAlias('quests', 0, 'tm siamil aufgaben')

client.createStandardAlias('cs', 1, tanjian_set_kamischaden)
client.createStandardAlias('cs', 0, tanjian_set_kamischaden)
client.createStandardAlias('akh', 1, setAksharaHandschuhe)
