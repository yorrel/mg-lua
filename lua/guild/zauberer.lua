-- zauberer

local base   = require 'base'
local inv    = require 'inventory'
local itemdb = require 'itemdb'
local kampf  = require 'battle'
local ME     = require 'gmcp-data'

local logger = client.createLogger('zauberer')
local keymap = base.keymap


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

base.gilde.entsorgeLeiche = 'entsorge leiche'


-- ---------------------------------------------------------------------------
-- Zauber

local zaubererhandschuhe = {
  feuersteinhandschuhe = 'feuer',
  schlangenlederhandschuhe = 'feuer',
  wandlerhandschuhe = '*',
}

local function hand(art)
  local handschuhart = art or 'feuer'
  local handschuhe = inv.ruestung.handschuhe()
  if handschuhe ~= nil and handschuhe ~= ''
    and zaubererhandschuhe[handschuhe] ~= '*'
    and zaubererhandschuhe[handschuhe] ~= handschuhart
  then
    client.send('ziehe '..handschuhe..' aus')
  end
  client.send('hand '..(art or ''))
end

local function rueste(item)
  client.send('rueste '..item)
end

local items_ruesten
local rueste_next_index = 1

local function rueste_next_item()
  local item = items_ruesten[rueste_next_index]
  rueste_next_index = rueste_next_index + 1
  rueste(item)
end

-- ruestet nacheinander alle ruestungsteile
local function ruesten()
  items_ruesten = inv.alleRuestungen()
  rueste_next_index = 1
  rueste_next_item()
  client.createTimer(3, rueste_next_item, #items_ruesten-1)
end


local einstellbare_zauber = {
  gp='giftpfeil', g='giftpfeil',
  fb='feuerball', f='feuerball',
  bl='blitz', b='blitz',
}
local zauber_staerken = {
  k='klein',
  m='mittel',
  g='gross',
}
zauber_staerken['1'] = 'klein'
zauber_staerken['2'] = 'mittel'
zauber_staerken['3'] = 'gross'

local function spruchstaerke(spruch, staerke)
  spruch = einstellbare_zauber[spruch] or spruch
  staerke = zauber_staerken[staerke] or staerke
  client.send('spruchstaerke '..spruch..' '..staerke)
end

-- blitz nur fuer stabschaden
local verletze_typen = {
  fe='feuer', ei='eis', wa='wasser', ma='magie',
  gi='gift', lu='wind', sa='saeure', kr='laerm',
  bl='blitz', er='erde',
}

verletzeSchaden = nil

-- schaden fuer verletze einstellen
local function verletzeSchaden(schaden)
  verletzeSchaden = verletze_typen[schaden] or schaden
  client.send('verletzungstyp '..verletzeSchaden)
end

local function getVerletzeSchaden()
  return verletzeSchaden
end

local function stabschaden(schaden)
  if schaden == 'he' then
    client.send('weihe zauberstab')
  elseif schaden == 'bo' then
    client.send('verfluche zauberstab')
  else
    schaden = verletze_typen[schaden] or schaden
    client.send('stabschaden '..schaden)
  end
end


-- ---------------------------------------------------------------------------
-- Trigger fuer Highlighting

client.createRegexTrigger('ist nun von einer (feurigen|eisigen|verschwommenen|magischen|giftgruenen|durchscheinenden|roetlichen|flimmernden|funkelnden) Aura eingehuellt.', nil, {'<green>'})
client.createRegexTrigger('Die Aura um Dein.* schwindet.', nil, {'<red>'})

client.createSubstrTrigger('Die Ausfuehrung Deines vorbereiteten Spruches wird verzoegert.', nil, {'<cyan>'})
client.createSubstrTrigger('Dir fehlen die noetigen Materialien!', nil, {'B','<red>'})

client.createSubstrTrigger('Deine Haende beginnen', nil, {'<green>'})
client.createSubstrTrigger('Die Verzauberung Deiner Haende laesst langsam nach.', nil, {'<red>'})

client.createSubstrTrigger('Du konzentrierst Deinen Willen auf Deinen Schutz.', nil, {'<green>'})
client.createSubstrTrigger('Dein Wille laesst nach.', nil, {'<red>'})

client.createSubstrTrigger('Ploetzlich loest sich Dein Schatten von Dir.', nil, {'<green>'})
client.createSubstrTrigger(ME.name..' loest sich in Luft auf.', nil, {'<red>'})

client.createSubstrTrigger('Du hast jetzt eine zusaetzliche Hand zur Verfuegung.', nil, {'<green>'})
client.createSubstrTrigger('Deine Extrahand loest sich auf.', nil, {'<red>'})

client.createSubstrTrigger('Du wirst allmaehlich wieder langsamer.', nil, {'<red>'})


-- ---------------------------------------------------------------------------
-- Statuszeile

base.statusAdd('SKP', '   ')
base.statusAdd('gesinnung', ' ',true)
base.statusAdd('hand', ' ', true)
base.statusAdd('extrahand', ' ', true)
base.statusAdd('wille', ' ', true)
base.statusAdd('sz', ' ', true)
base.statusAdd('ba', ' ', true)
base.statusAdd('er', ' ', true)
base.statusAdd('gesundheit', '    ',true)

local function convert(flag, to)
  if flag == 'J' then
    return to
  else
    return ' '
  end
end

local function statusZeile1(m)
  base.statusUpdate('SKP', m[3])
  base.statusUpdate('gesinnung', m[4], true)
  local gesundheit = convert(m[5],'G')..convert(m[6],'B')..convert(m[7],'T')..convert(m[8],'F')
  base.statusUpdate('gesundheit', gesundheit, true)
end

local function statusZeile2(m)
  base.statusUpdate('hand', m[1], true)
  base.statusUpdate('extrahand', m[2], true)
  base.statusUpdate('wille', m[3], true)
  base.statusUpdate('sz', m[4], true)
  base.statusUpdate('ba', m[5], true)
  base.statusUpdate('er', m[6], true)
end

client.createRegexTrigger('^STATUS1: ([0-9]+) ([0-9]+) ([0-9]+) (.) (.) (.) (.) (.)', statusZeile1, {'g'})
client.createRegexTrigger('^STATUS2: (.) (.) (.) (.) (.) (.) ([0-9]+) (.+)', statusZeile2, {'g'})


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

local function zauberer_info()
  client.send('stabinfo')
  client.send('verletzungstyp')
  client.send('ginhalt')
end

base.gilde.info = zauberer_info


-- ---------------------------------------------------------------------------
-- Tasten

local function createFunctionMitGegner(cmd)
  return
    function()
      client.send(cmd..' '..kampf.getGegner())
    end
end

local function createFunctionMitHands(n, cmd)
  return
    function()
      inv.doWithHands(n, cmd)
    end
end

keymap.F5   = function() hand('feuer') end
keymap.S_F5 = function() hand('eis') end
keymap.F6   = function() hand('saeure') end
keymap.S_F6 = createFunctionMitGegner('giftpfeil')
keymap.F7   = createFunctionMitGegner('feuerball')
keymap.S_F7 = createFunctionMitGegner('blitz')
keymap.F8   = createFunctionMitGegner('verletze')
keymap.S_F8 = createFunctionMitGegner('entkraefte')

keymap.M_a = 'vorahnung'
keymap.M_b = 'erdbeben'
keymap.M_d = 'zauberschild'
keymap.M_e = 'nachtsicht schwach'
keymap.M_f = createFunctionMitGegner('irritiere')
keymap.M_g = createFunctionMitGegner('schmerzen')
keymap.M_i = 'wille'
keymap.M_j = createFunctionMitHands(2, 'extrahand')
keymap.M_k = 'schattenkaempfer'
keymap.M_l = 'licht'
keymap.M_m = 'schutzhuelle'
keymap.M_p = 'befriede'
keymap.M_r = 'schutzzone'
keymap.M_t = 'teleport'
keymap.M_v = 'schutz'
keymap.M_y = hand
keymap.M_x = 'schnell'
keymap.M_z = 'erschoepfung'


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('skills', 0, 'tm llystrathe faehigkeiten')
client.createStandardAlias('quests', 0, 'tm llystrathe anforderungen')

client.createStandardAlias('ruesten', 0, ruesten)
client.createStandardAlias('cs', 1, verletzeSchaden)
client.createStandardAlias('zs', 1, stabschaden)
client.createStandardAlias('as', 2, spruchstaerke)


-- ---------------------------------------------------------------------------
-- module definition

return {
  getVerletzeSchaden = getVerletzeSchaden,
  setVerletzeSchaden = verletzeSchaden,
}
