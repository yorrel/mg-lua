-- zauberer

local base    = require 'base'
local inv     = require 'inventory'
local kampf   = require 'battle'

local logger  = client.createLogger('zauberer')

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

-- schaden fuer verletze einstellen
local function verletzeSchaden(schaden)
  local typ = verletze_typen[schaden] or schaden
  client.send('verletzungstyp ' .. typ)
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
-- Statuszeile

local function convert(flag, to)
  return flag == 'J' and to or ' '
end

local function statusZeile1(m)
  local gesundheit =
    convert(m[5],'G')..convert(m[6],'B')
    ..convert(m[7],'T')..convert(m[8],'F')
  base.statusUpdate(
    {'skp', m[3]},
    {'gesinnung', m[4]},
    {'gesundheit', gesundheit}
  )
end

local function statusZeile2(m)
  base.statusUpdate(
    {'hand', m[1]},
    {'extrahand', m[2]},
    {'wille', m[3]},
    {'sz', m[4]},
    {'ba', m[5]},
    {'er', m[6]}
  )
end


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


-- ---------------------------------------------------------------------------
-- Guild class Zauberer

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Zauberer = class(Guild)

function Zauberer:info()
  client.send('stabinfo')
  client.send('verletzungstyp')
  client.send('ginhalt')
end

function Zauberer:entsorgeLeiche()
  client.send('entsorge leiche')
end

function Zauberer:enable()
  -- Statuszeile -------------------------------------------------------------
  local statusConf =
    'SKP:{skp:3} {hand:1} {extrahand:1} {wille:1} {sz:1} {ba:1}'
    ..'{er:1} {gesinnung:1} {gesundheit:4}'
  base.statusConfig(statusConf)

  -- Trigger fuer Status -----------------------------------------------------
  self:createRegexTrigger('^STATUS1: ([0-9]+) ([0-9]+) ([0-9]+) (.) (.) (.) (.) (.)', statusZeile1, {'g'})
  self:createRegexTrigger('^STATUS2: (.) (.) (.) (.) (.) (.) ([0-9]+) (.+)', statusZeile2, {'g'})

  base.addResetHook(
    function()
      client.send(
        'stabreport STATUS1: %la %ma %sa %Al %gi %bl %ta %fr %lfSTATUS2: %Fh %Xh %Wi %Sz %Ba %Er %vo %fl %lf',
        'stabreport ein'
      )
    end
  )

  -- Trigger fuer Highlighting -----------------------------------------------
  self:createSubstrTrigger(base.charName()..' loest sich in Luft auf.', nil, {'<red>'})

  self:createRegexTrigger('ist nun von einer (feurigen|eisigen|verschwommenen|magischen|giftgruenen|durchscheinenden|roetlichen|flimmernden|funkelnden) Aura eingehuellt.', nil, {'<green>'})
  self:createRegexTrigger('^Die Aura um Dein.* schwindet.', nil, {'<red>'})

  self:createSubstrTrigger('Die Ausfuehrung Deines vorbereiteten Spruches wird verzoegert.', nil, {'<cyan>'})
  self:createSubstrTrigger('Dir fehlen die noetigen Materialien!', nil, {'B','<magenta>'})

  self:createSubstrTrigger('Deine Haende beginnen', nil, {'<green>'})
  self:createSubstrTrigger('Die Verzauberung Deiner Haende laesst langsam nach.', nil, {'<red>'})

  self:createSubstrTrigger('Du konzentrierst Deinen Willen auf Deinen Schutz.', nil, {'<green>'})
  self:createSubstrTrigger('Dein Wille laesst nach.', nil, {'<red>'})

  self:createSubstrTrigger('Ploetzlich loest sich Dein Schatten von Dir.', nil, {'<green>'})

  self:createSubstrTrigger('Du hast jetzt eine zusaetzliche Hand zur Verfuegung.', nil, {'<green>'})
  self:createSubstrTrigger('Deine Extrahand loest sich auf.', nil, {'<red>'})

  self:createSubstrTrigger('Du wirst allmaehlich wieder langsamer.', nil, {'<red>'})

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
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

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills', 0, function() client.send('tm llystrathe faehigkeiten') end
  )
  client.createStandardAlias(
    'quests', 0, function() client.send('tm llystrathe anforderungen') end
  )

  client.createStandardAlias('ruesten', 0, ruesten)
  client.createStandardAlias('cs', 1, verletzeSchaden)   -- analog chaoten
  client.createStandardAlias('vs', 1, verletzeSchaden)
  client.createStandardAlias('zs', 1, stabschaden)
  client.createStandardAlias('as', 2, spruchstaerke)
end


return Zauberer
