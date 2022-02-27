-- Tanjian

local base   = require 'base'
local inv    = require 'inventory'
local timer  = require 'timer'
local kampf  = require 'battle'

local logger = client.createLogger('tanjian')
local trigger = {}

local function state()
  return base.getPersistentTable('tanjian')
end


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

trigger[#trigger+1] = client.createSubstrTrigger('Die Ausfuehrung Deines vorbereiteten Spruches wird verzoegert.', nil, {'<cyan>'})

trigger[#trigger+1] = client.createSubstrTrigger('Du bist derzeit in der Parallelwelt.', nil, {'<blue>'})
trigger[#trigger+1] = client.createRegexTrigger('Du bist derzeit in Parallelwelt Nr\\. (\\d*)\\.', nil, {'<blue>'})

-- meditation
trigger[#trigger+1] = client.createSubstrTrigger('Du beendest Deine Meditation.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Deine Konzentrationsfaehigkeit laesst langsam nach.', nil, {'<yellow>'})
trigger[#trigger+1] = client.createSubstrTrigger('Deine Umgebung scheint sich auf Deine Meditation auszuwirken.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Du solltest mal wieder meditieren.', nil, {'<red>'})
trigger[#trigger+1] = client.createSubstrTrigger('Du spuerst noch die Wirkung der letzten Meditation.', nil, {'<blue>'})

-- kokoro
trigger[#trigger+1] = client.createSubstrTrigger('Die Dunkelheit loest sich von Deinem Geist.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Die Membran schwingt doch noch!', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Die Energien des Kokoro versiegen.', nil, {'<red>'})

-- tegatana, omamori, hayai
trigger[#trigger+1] = client.createSubstrTrigger('Du konzentrierst Dich auf den Kampf.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Deine Kampf-Konzentration laesst nach.', nil, {'<red>'})
trigger[#trigger+1] = client.createSubstrTrigger('Du konzentrierst Dich auf die Abwehr.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Deine Abwehr-Konzentration laesst nach.', nil, {'<red>'})
trigger[#trigger+1] = client.createSubstrTrigger('Der Zeitfluss veraendert sich', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Die Kontrolle ueber den Zeitfluss entgleitet Dir.', nil, {'<red>'})

trigger[#trigger+1] = client.createRegexTrigger(
  'Deine Haende fangen ploetzlich an, .* zu leuchten.',
  function()
    timer.enqueue(
      150,
      function()
        logger.info('Akshara wieder moeglich')
      end
    )
  end,
  {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Du verlaesst den Pfad des Lichtes.', nil, {'<red>'})

-- Clan Nekekami
trigger[#trigger+1] = client.createSubstrTrigger('Du huellst Dich in einen schuetzenden Nebel.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Du bist noch in einen Nebel gehuellt.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Der Nebel loest sich auf.', nil, {'<red>'})


-- ---------------------------------------------------------------------------
-- Statuszeile

local tanjianStatusConf =
  '{meditation:1} {gesinnung:1} {kokoro:2} {tegatana:2} {hayai:2} {akshara:2}'

trigger[#trigger+1] = client.createRegexTrigger(
  '^TANJIANREPORT: (.) (.) (..) (..) (..) (..)#',
  function(m)
    base.statusUpdate(
      {'meditation', m[1]},
      {'gesinnung', m[2]},
      {'kokoro', m[3]},
      {'tegatana', m[4]},
      {'hayai', m[5]},
      {'akshara', m[6]}
    )
  end,
  {'g'}
)


client.disableTrigger(trigger)

local function createFunctionMitGegner(cmd)
  return
    function()
      client.send(cmd..' '..kampf.getGegner())
    end
end


-- ---------------------------------------------------------------------------
-- Guild class Tanjian

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Tanjian = class(Guild)

function Tanjian:identifiziere(item)
  client.send('koryoku '..item)
end

function Tanjian:schaetz(item)
  client.send('koryoku '..item)
end

function Tanjian:info()
  logger.info('Kami-Schaden  [#cs] : '..(get_kami_schaden() or ''))
  logger.info('Akshara-Hdsch.[#akh]: '..(state().akshara_handschuhe or ''))
  client.send('tanjiantest')
end

function Tanjian:entsorgeLeiche()
  client.send('entsorge leiche')
end

function Tanjian:enable()
  -- Standardfunktionen ------------------------------------------------------
  base.addResetHook(
    function()
      client.send(
        'tanjianreport TANJIANREPORT: %ME %Ca %Ko %Te %Ha %Ak#%lf',
        'tanjianreport an'
      )
    end
  )
  base.statusConfig(tanjianStatusConf)

  -- Trigger -----------------------------------------------------------------
  client.enableTrigger(trigger)

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
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

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills',
    0,
    function()
      client.send('tm siamil faehigkeiten', 'tm siamil waffenfaehigkeiten')
    end
  )
  client.createStandardAlias('quests', 0, 'tm siamil aufgaben')
  client.createStandardAlias('cs', 1, tanjian_set_kamischaden)
  client.createStandardAlias('cs', 0, tanjian_set_kamischaden)
  client.createStandardAlias('akh', 1, setAksharaHandschuhe)
end


return Tanjian
