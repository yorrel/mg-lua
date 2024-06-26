-- Tanjian

local base   = require 'base'
local inv    = require 'inventory'
local timer  = require 'timer'
local kampf  = require 'battle'

local logger = client.createLogger('tanjian')

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
-- Statuszeile




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
  -- Statuszeile -------------------------------------------------------------
  local tanjianStatusConf =
    '{meditation:1} {gesinnung:1} {kokoro:2} {tegatana:2} {hayai:2} {akshara:2}'
  base.statusConfig(tanjianStatusConf)

  self:createRegexTrigger(
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

  base.addResetHook(
    function()
      client.send(
        'tanjianreport TANJIANREPORT: %ME %Ca %Ko %Te %Ha %Ak#%lf',
        'tanjianreport an'
      )
    end
  )

  -- Trigger -----------------------------------------------------------------
  self:createSubstrTrigger('Die Ausfuehrung Deines vorbereiteten Spruches wird verzoegert.', nil, {'<cyan>'})
  self:createSubstrTrigger('Du bist derzeit in der Parallelwelt.', nil, {'<blue>'})
  self:createRegexTrigger('^Du bist derzeit in Parallelwelt Nr\\. (\\d*)\\.', nil, {'<blue>'})
  self:createSubstrTrigger('Es mangelt Dir an Konzentrationspunkten.', nil, {'<magenta>'})

  -- meditation
  self:createSubstrTrigger('Du beendest Deine Meditation.', nil, {'<green>'})
  self:createSubstrTrigger('Deine Konzentrationsfaehigkeit laesst langsam nach.', nil, {'<magenta>'})
  self:createSubstrTrigger('Deine Umgebung scheint sich auf Deine Meditation auszuwirken.', nil, {'<cyan>'})
  self:createSubstrTrigger('Du solltest mal wieder meditieren.', nil, {'<magenta>'})
  self:createSubstrTrigger('Du spuerst noch die Wirkung der letzten Meditation.', nil, {'<blue>'})

  -- kokoro
  self:createSubstrTrigger('Die Dunkelheit loest sich von Deinem Geist.', nil, {'<green>'})
  self:createSubstrTrigger('Die Membran schwingt doch noch!', nil, {'<green>'})
  self:createSubstrTrigger('Die Energien des Kokoro versiegen.', nil, {'<red>'})

  -- tegatana, omamori, hayai
  self:createRegexTrigger('^Du konzentrierst Dich (?:doch bereits )?auf den Kampf\\.$', nil, {'<green>'})
  self:createSubstrTrigger('Deine Kampf-Konzentration laesst nach.', nil, {'<red>'})
  self:createRegexTrigger('^Du konzentrierst Dich (?:doch bereits )?auf (?:die|Deine) Abwehr\\.$', nil, {'<green>'})
  self:createRegexTrigger('^Du konzentrierst Dich derzeit auf (?:Deine Abwehr|den Kampf)\\.$', nil, {'<magenta>'})
  self:createSubstrTrigger('Deine Abwehr-Konzentration laesst nach.', nil, {'<red>'})
  self:createSubstrTrigger('Der Zeitfluss veraendert sich', nil, {'<green>'})
  self:createSubstrTrigger('Du konzentrierst Dich bereits auf den Zeitfluss.', nil, {'<green>'})
  self:createSubstrTrigger('Die Kontrolle ueber den Zeitfluss entgleitet Dir.', nil, {'<red>'})

  self:createRegexTrigger(
    '^Deine Haende fangen ploetzlich an, .* zu leuchten.',
    function()
      timer.enqueue(
        150,
        function()
          logger.info('Akshara wieder moeglich')
        end
      )
    end,
    {'<green>'})
  self:createSubstrTrigger('Du verlaesst den Pfad des Lichtes.', nil, {'<red>'})

  -- Clan Nekekami
  self:createSubstrTrigger('Du huellst Dich in einen schuetzenden Nebel.', nil, {'<green>'})
  self:createSubstrTrigger('Du bist noch in einen Nebel gehuellt.', nil, {'<green>'})
  self:createSubstrTrigger('Der Nebel loest sich auf.', nil, {'<red>'})

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5 = createFunctionMitGegner('samusa')
  keymap.S_F5 = createFunctionMitGegner('kshira')
  keymap.F6 = createFunctionMitGegner('kaminari')
  keymap.S_F6 = 'kshira alle'
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
  client.createStandardAlias(
    'quests', 0, function() client.send('tm siamil aufgaben') end
  )
  client.createStandardAlias('cs', 1, tanjian_set_kamischaden)
  client.createStandardAlias('cs', 0, tanjian_set_kamischaden)
  client.createStandardAlias('akh', 1, setAksharaHandschuhe)
end


return Tanjian
