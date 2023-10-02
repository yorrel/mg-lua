-- Kleriker

local base   = require 'base'
local inv    = require 'inventory'
local kampf  = require 'battle'

local logger = client.createLogger('klerus')


local function kleriker_begrabe_leiche()
  client.send('nimm 1 leichentuch aus ' .. inv.cont.default())
  client.send('nimm 1 weihwasser aus ' .. inv.cont.default())
  client.send('begrabe leiche')
end
local function angriff_goetterzorn()
  client.send('goetterzorn '..kampf.getGegner())
end
local function angriff_erloese()
  inv.doWithHands(2, 'erloese '..kampf.getGegner())
end
local function angriff_blitz()
  inv.doWithHands(1, 'blitz '..kampf.getGegner())
end
local function angriff_wunder()
  inv.doWithHands(1, 'wunder')
end

local function kleriker_heiltrank()
  inv.doWithHands(1, 'heiltrank')
end

local bete_arten = {
  an = 'andaechtig',
  i = 'inbruenstig',
  a = 'ausdauernd',
  au = 'aufopferungsvoll',
}

local function kleriker_bete(id)
  if kampf.istImKampf() then
    logger.error('Ignoriere bete im Kampf!')
  else
    client.send('bete '..bete_arten[id or 'i'])
  end
end

local function kleriker_entfluche(ziel)
  inv.doWithHands(1, 'entfluche '..(ziel or ''))
end

local function kleriker_segne(ziel)
  inv.doWithHands(2, 'segne '..(ziel or ''))
end


local elementdb = {
  er = 'erde',
  fe = 'feuer',
  ei = 'kaelte',
  wa = 'wasser',
  lu = 'luft',
  sa = 'saeure',
}
elementdb['-'] = 'aus'

local function kleriker_elementarsphaere(element)
  client.send('elementarsphaere '..(elementdb[element] or element))
end

local last_element = nil
local function kleriker_elementarschild(element)
  last_element = elementdb[element] or element or last_element
  client.send('elementarschild '..last_element)
end

local function kleriker_weihe(ziel)
  if (ziel ~= nil) then
    client.send('weihe '..ziel)
  else
    client.send('weihe '..inv.waffe())
  end
end

-- Talisman Status
local tali_status_trigger = {}
tali_status_trigger[#tali_status_trigger+1] = client.createMultiLineRegexTrigger(
  '^Der adamantene Ring steht fuer die Bestaendigkeit der Schoepfung>< Lembolds, der goldene Ring fuer den Wert der Heilgaben Saphinas und der eiserne Ring fuer die Durchsetzungskraft Kandris\\.',
  nil,
  {'g'}
)
tali_status_trigger[#tali_status_trigger+1] = client.createMultiLineRegexTrigger(
  '^Der Talisman ist an einem ledernen Band befestigt>< und laesst sich um den Hals haengen\\.',
  function()
    client.disableTrigger(tali_status_trigger)
  end,
  {'g'}
)
tali_status_trigger[#tali_status_trigger+1] = client.createMultiLineRegexTrigger(
  '^Der (.*) Talisman besteht aus drei ineinander>< verwobenen metallenen Ringen, durch die die drei Gottheiten des Heiligen Ordens repraesentiert werden\\.',
  function(m)
    logger.info('Talisman: '..m[1]:sub(1,-2))
  end,
  {'g'}
)
client.disableTrigger(tali_status_trigger)


-- ---------------------------------------------------------------------------
-- Statuszeile

local function statusUpdate(id, optVal)
  return
    function()
      base.statusUpdate({id, optVal})
    end
end


-- ---------------------------------------------------------------------------
-- Guild class Klerus

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Klerus = class(Guild)

function Klerus:talismanStatus()
  client.enableTrigger(tali_status_trigger)
  client.send('unt talisman in mir')
end

function Klerus:info()
  client.send(
    'reibe adamantenen ring',
    'reibe eisernen ring kraeftig'
  )
  self:talismanStatus()
end

function Klerus:enable()
  -- Statuszeile -------------------------------------------------------------
  local statusConf =
    '{heiligenschein:2} Esc:{eleschutz:2} Esp:{elesphaere:2}'
    ..' {messerkreis:2} {weihe:2} {giftschwaechung:2}'
  base.statusConfig(statusConf)

  -- Trigger -----------------------------------------------------------------
  -- Heiligenschein
  self:createSubstrTrigger('Lembold erhoert Dich. Ueber Deinem Haupt erscheint ein Heiligenschein.', statusUpdate('heiligenschein','Hs'), {'<green>'})
  self:createSubstrTrigger('Dein Heiligenschein flackert.', nil, {'<yellow>'})
  self:createSubstrTrigger('Dein Heiligenschein verglimmt.', statusUpdate('heiligenschein'), {'<red>'})

  -- Goettermacht
  self:createSubstrTrigger('Eine goettliche Aura huellt Dich ein.', nil, {'<green>'})
  self:createSubstrTrigger('Die goettliche Aura verlaesst Dich wieder.', nil, {'<red>'})

  -- Elementarschild
  self:createSubstrTrigger('Die Erde zu Deinen Fuessen woelbt sich und bricht auf. Ein irdener Schild', statusUpdate('eleschutz','er'), {'<green>'})
  self:createSubstrTrigger('Eine Stichflamme schiesst vor Dir aus dem Boden und umgibt Dich mit einem', statusUpdate('eleschutz','fe'), {'<green>'})
  self:createSubstrTrigger('Klirrende Kaelte umgibt Dich auf einmal schuetzend.', statusUpdate('eleschutz','ei'), {'<green>'})
  self:createSubstrTrigger('Ein ploetzlicher Regenschauer prasselt hernieder, ohne Dich jedoch zu', statusUpdate('eleschutz','wa'), {'<green>'})
  self:createSubstrTrigger('Ein starker Wind umtost Dich auf einmal und bildet so einen luftigen Schild.', statusUpdate('eleschutz','lu'), {'<green>'})
  self:createSubstrTrigger('Eine Wolke aus Saeuregasen bildet sich um Dich herum. Einige Blitze erden sich', statusUpdate('eleschutz','sa'), {'<green>'})
  self:createSubstrTrigger('Dein Elementarschild wird duenner.', nil, {'<yellow>'})
  self:createSubstrTrigger('Der Elementarschild zerfaellt.', statusUpdate('eleschutz'), {'<red>'})

  -- Elementarsphaere
  self:createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Erde. Dann wird Deine', statusUpdate('elesphaere','er'), {'<green>'})
  self:createSubstrTrigger('um Dich herum erscheint ein Blase aus kristallinem Feuer. Dann wird Deine', statusUpdate('elesphaere','fe'), {'<green>'})
  self:createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Kaelte. Dann wird Deine', statusUpdate('elesphaere','ei'), {'<green>'})
  self:createSubstrTrigger('um Dich herum erscheint ein Blase aus kristallinem Wasser. Dann wird Deine', statusUpdate('elesphaere','wa'), {'<green>'})
  self:createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Luft. Dann wird Deine', statusUpdate('elesphaere','lua'), {'<green>'})
  self:createSubstrTrigger('Die Elementarsphaere loest sich auf.', statusUpdate('elesphaere'), {'<green>'})

  -- Messerkreis
  self:createMultiLineRegexTrigger('^Kandri erfasst Dich mit ihrer Macht! Du beginnst zu gluehen! Das Gluehen>< weitet sich langsam aus und verdichtet sich zu einem leuchtenden Kreis um Deinen Koerper\\. Aus dem Leuchten heraus kondensieren auf einmal wirbelnde Messer, die jeder Bewegung Deines Koerpers folgen\\.', statusUpdate('messerkreis','Mk'), {'<green>'})
  self:createSubstrTrigger('Die wirbelnden Messer werden langsamer.', statusUpdate('messerkreis','Mk'), {'<yellow>'})
  self:createSubstrTrigger('Der Kreis wirbelnder Messer verschwindet wieder.', statusUpdate('messerkreis'), {'<red>'})

  -- Weihe
  self:createSubstrTrigger('Du sprichst ein kurzes, inbruenstiges Gebet.', statusUpdate('weihe','We'), {'<green>'})
  self:createSubstrTrigger('Der Heilige Zorn Lembolds ist verraucht.', statusUpdate('weihe'), {'<red>'})

  -- Spaltung
  self:createSubstrTrigger('Ein Abbild ' .. base.charName() .. 's loest sich in Wohlgefallen auf.', nil, {'<red>'})

  -- Giftschwaechung
  self:createSubstrTrigger('Vergiftungen wirken nun nicht mehr so schnell bei Dir.', statusUpdate('giftschwaechung','Gs'), {'<green>'})
  self:createSubstrTrigger('Die Wirkung der Giftschwaechung ist nun ganz abgeklungen.', statusUpdate('giftschwaechung'), {'<red>'})

    -- Beten
  self:createRegexTrigger(
    '^Du (legst die Geissel beiseite und )?beendest Dein Gebet',
    function() self:talismanStatus() end,
    {'<cyan>'}
  )

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  -- F5-F8: Angriffs-Zauber
  keymap.F5 = angriff_goetterzorn
  keymap.S_F5 = angriff_wunder
  keymap.F6 = angriff_erloese
  keymap.F7 = 'donner'
  keymap.F8 = angriff_blitz
  
  keymap.M_b = kleriker_begrabe_leiche
  keymap.M_e = kleriker_weihe
  keymap.M_k = 'spaltung'
  keymap.M_j = 'entlasse abbild'
  keymap.M_p = 'frieden'
  keymap.M_t = 'messerkreis'
  keymap.M_v = 'heiligenschein'
  keymap.M_l = 'leuchten'
  keymap.M_m = kleriker_elementarschild
  keymap.M_r = 'goettermacht'
  keymap.M_x = 'goettermacht'
  keymap.M_z = kleriker_bete

  -- HP-spell:
  keymap.M_a = kleriker_heiltrank

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias('be',  1, kleriker_bete)
  client.createStandardAlias('efl', 1, kleriker_entfluche)
  client.createStandardAlias('sg',  1, kleriker_segne)
  client.createStandardAlias('esp', 1, kleriker_elementarsphaere)
  client.createStandardAlias('esc', 1, kleriker_elementarschild)
  client.createStandardAlias('we',  1, kleriker_weihe)
end


return Klerus
