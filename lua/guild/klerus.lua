-- Kleriker

local base   = require 'base'
local inv    = require 'inventory'
local kampf  = require 'battle'

local logger = client.createLogger('klerus')
local keymap = base.keymap


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

base.statusAdd('heiligenschein','  ',true)
base.statusAdd('Esc','  ')
base.statusAdd('Esp','  ')


local function statusUpdate(id, optVal)
  return
    function()
      base.statusUpdate({id, optVal})
    end
end

local function statusAn(id)
  return
    function()
      base.statusAdd(id)
    end
end

local function statusAus(id)
  return
    function()
      base.statusRemove(id)
    end
end

-- Heiligenschein
client.createSubstrTrigger('Lembold erhoert Dich. Ueber Deinem Haupt erscheint ein Heiligenschein.', statusUpdate('heiligenschein','Hs'), {'<green>'})
client.createSubstrTrigger('Dein Heiligenschein flackert.', nil, {'<yellow>'})
client.createSubstrTrigger('Dein Heiligenschein verglimmt.', statusUpdate('heiligenschein','  '), {'<red>'})

-- Goettermacht
client.createSubstrTrigger('Eine goettliche Aura huellt Dich ein.', nil, {'<green>'})
client.createSubstrTrigger('Die goettliche Aura verlaesst Dich wieder.', nil, {'<red>'})

-- Elementarschild
client.createSubstrTrigger('Die Erde zu Deinen Fuessen woelbt sich und bricht auf. Ein irdener Schild', statusUpdate('Esc','er'), {'<green>'})
client.createSubstrTrigger('Eine Stichflamme schiesst vor Dir aus dem Boden und umgibt Dich mit einem', statusUpdate('Esc','fe'), {'<green>'})
client.createSubstrTrigger('Klirrende Kaelte umgibt Dich auf einmal schuetzend.', statusUpdate('Esc','ei'), {'<green>'})
client.createSubstrTrigger('Ein ploetzlicher Regenschauer prasselt hernieder, ohne Dich jedoch zu', statusUpdate('Esc','wa'), {'<green>'})
client.createSubstrTrigger('Ein starker Wind umtost Dich auf einmal und bildet so einen luftigen Schild.', statusUpdate('Esc','lu'), {'<green>'})
client.createSubstrTrigger('Eine Wolke aus Saeuregasen bildet sich um Dich herum. Einige Blitze erden sich', statusUpdate('Esc','sa'), {'<green>'})
client.createSubstrTrigger('Dein Elementarschild wird duenner.', nil, {'<yellow>'})
client.createSubstrTrigger('Der Elementarschild zerfaellt.', statusUpdate('Esc','  '), {'<red>'})

-- Elementarsphaere
client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Erde. Dann wird Deine', statusUpdate('Esp','er'), {'<green>'})
client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristallinem Feuer. Dann wird Deine', statusUpdate('Esp','fe'), {'<green>'})
client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Kaelte. Dann wird Deine', statusUpdate('Esp','ei'), {'<green>'})
client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristallinem Wasser. Dann wird Deine', statusUpdate('Esp','wa'), {'<green>'})
client.createSubstrTrigger('um Dich herum erscheint ein Blase aus kristalliner Luft. Dann wird Deine', statusUpdate('Esp','lua'), {'<green>'})
client.createSubstrTrigger('Die Elementarsphaere loest sich auf.', statusUpdate('Esp','  '), {'<green>'})

-- Messerkreis
client.createSubstrTrigger('Kandri erfasst Dich mit ihrer Macht! Du beginnst zu gluehen! Das Gluehen', statusAn('Mk'), {'<green>'})
client.createSubstrTrigger('Der Kreis wirbelnder Messer verschwindet wieder.', statusAus('Mk'), {'<red>'})

-- Weihe
client.createSubstrTrigger('Du sprichst ein kurzes, inbruenstiges Gebet.', statusAn('We'), {'<green>'})
client.createSubstrTrigger('Der Heilige Zorn Lembolds ist verraucht.', statusAus('We'), {'<red>'})

-- Spaltung
client.createSubstrTrigger('Ein Abbild Duraths loest sich in Wohlgefallen auf.', nil, {'<red>'})

-- Giftschwaechung
client.createSubstrTrigger('Vergiftungen wirken nun nicht mehr so schnell bei Dir.', statusAn('Gs'), {'<green>'})
client.createSubstrTrigger('Die Wirkung der Giftschwaechung ist nun ganz abgeklungen.', statusAus('Gs'), {'<red>'})


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

local function klerus_info()
  client.send('reibe adamantenen ring')
  client.send('reibe eisernen ring kraeftig')
  client.send('unt talisman in mir')
end

base.gilde.info = klerus_info


-- ---------------------------------------------------------------------------
-- Tastenbelegung

-- F5-F8: Angriffs-Zauber
keymap.F5 = angriff_goetterzorn
keymap.S_F5 = angriff_wunder
keymap.F6 = angriff_erloese
keymap.F7 = 'donner'
keymap.F8 = angriff_blitz

-- M-*
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


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('be',  1, kleriker_bete)
client.createStandardAlias('efl', 1, kleriker_entfluche)
client.createStandardAlias('sg',  1, kleriker_segne)
client.createStandardAlias('esp', 1, kleriker_elementarsphaere)
client.createStandardAlias('esc', 1, kleriker_elementarschild)
client.createStandardAlias('we',  1, kleriker_weihe)


-- ---------------------------------------------------------------------------
-- module definition

return {
  segne = kleriker_segne,
  heiltrank = kleriker_heiltrank,
  entfluche = kleriker_entfluche,
}
