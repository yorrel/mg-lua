-- Kleriker

local base   = require 'base'
local inv    = require 'inventory'
local kampf  = require 'battle'

local logger = client.createLogger('klerus')
local trigger = {}


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
  client.send('bete '..bete_arten[id or 'i'])
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


-- ---------------------------------------------------------------------------
-- Statuszeile / Trigger

local statusConf =
  '{heiligenschein:2} Esc:{eleschutz} Esp:{elesphaere:2}'
  ..' {messerkreis:2} {weihe:2} {giftschwaechung:2}'

local function statusUpdate(id, optVal)
  return
    function()
      base.statusUpdate({id, optVal})
    end
end

-- Heiligenschein
trigger[#trigger+1] = client.createSubstrTrigger('Lembold erhoert Dich. Ueber Deinem Haupt erscheint ein Heiligenschein.', statusUpdate('heiligenschein','Hs'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Dein Heiligenschein flackert.', nil, {'<yellow>'})
trigger[#trigger+1] = client.createSubstrTrigger('Dein Heiligenschein verglimmt.', statusUpdate('heiligenschein'), {'<red>'})

-- Goettermacht
trigger[#trigger+1] = client.createSubstrTrigger('Eine goettliche Aura huellt Dich ein.', nil, {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Die goettliche Aura verlaesst Dich wieder.', nil, {'<red>'})

-- Elementarschild
trigger[#trigger+1] = client.createSubstrTrigger('Die Erde zu Deinen Fuessen woelbt sich und bricht auf. Ein irdener Schild', statusUpdate('eleschutz','er'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Eine Stichflamme schiesst vor Dir aus dem Boden und umgibt Dich mit einem', statusUpdate('eleschutz','fe'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Klirrende Kaelte umgibt Dich auf einmal schuetzend.', statusUpdate('eleschutz','ei'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Ein ploetzlicher Regenschauer prasselt hernieder, ohne Dich jedoch zu', statusUpdate('eleschutz','wa'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Ein starker Wind umtost Dich auf einmal und bildet so einen luftigen Schild.', statusUpdate('eleschutz','lu'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Eine Wolke aus Saeuregasen bildet sich um Dich herum. Einige Blitze erden sich', statusUpdate('eleschutz','sa'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Dein Elementarschild wird duenner.', nil, {'<yellow>'})
trigger[#trigger+1] = client.createSubstrTrigger('Der Elementarschild zerfaellt.', statusUpdate('eleschutz'), {'<red>'})

-- Elementarsphaere
trigger[#trigger+1] = client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Erde. Dann wird Deine', statusUpdate('elesphaere','er'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristallinem Feuer. Dann wird Deine', statusUpdate('elesphaere','fe'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Kaelte. Dann wird Deine', statusUpdate('elesphaere','ei'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristallinem Wasser. Dann wird Deine', statusUpdate('elesphaere','wa'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Luft. Dann wird Deine', statusUpdate('elesphaere','lua'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Die Elementarsphaere loest sich auf.', statusUpdate('elesphaere'), {'<green>'})

-- Messerkreis
trigger[#trigger+1] = client.createSubstrTrigger('Kandri erfasst Dich mit ihrer Macht! Du beginnst zu gluehen! Das Gluehen', statusUpdate('messerkreis','Mk'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Der Kreis wirbelnder Messer verschwindet wieder.', statusUpdate('messerkreis'), {'<red>'})

-- Weihe
trigger[#trigger+1] = client.createSubstrTrigger('Du sprichst ein kurzes, inbruenstiges Gebet.', statusUpdate('weihe','We'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Der Heilige Zorn Lembolds ist verraucht.', statusUpdate('weihe'), {'<red>'})

-- Spaltung
trigger[#trigger+1] = client.createSubstrTrigger('Ein Abbild Duraths loest sich in Wohlgefallen auf.', nil, {'<red>'})

-- Giftschwaechung
trigger[#trigger+1] = client.createSubstrTrigger('Vergiftungen wirken nun nicht mehr so schnell bei Dir.', statusUpdate('giftschwaechung','Gs'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Die Wirkung der Giftschwaechung ist nun ganz abgeklungen.', statusUpdate('giftschwaechung'), {'<red>'})

client.disableTrigger(trigger)


-- ---------------------------------------------------------------------------
-- Guild class Klerus

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Klerus = class(Guild)

function Klerus:info()
  client.send('reibe adamantenen ring')
  client.send('reibe eisernen ring kraeftig')
  client.send('unt talisman in mir')
end

function Klerus:enable()
  -- Standardfunktionen ------------------------------------------------------
  base.statusConfig(statusConf)

  -- Trigger -----------------------------------------------------------------
  client.enableTrigger(trigger)

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
