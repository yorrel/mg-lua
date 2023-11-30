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
local function kleriker_elementarschild(arg)
  local element = arg and elementdb[arg] or arg or last_element or 'erde'
  last_element = element ~= 'aus' and element or last_element
  client.send('elementarschild '..element)
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
  self:createRegexTrigger('^Lembold erhoert Dich\\. Ueber Deinem Haupt erscheint ein Heiligenschein\\.$', statusUpdate('heiligenschein','Hs'), {'<green>'})
  self:createRegexTrigger('^Dein Heiligenschein flackert\\.$', nil, {'<yellow>'})
  self:createRegexTrigger('^Dein Heiligenschein verglimmt\\.$', statusUpdate('heiligenschein'), {'<red>'})

  -- Goettermacht
  self:createSubstrTrigger('Eine goettliche Aura huellt Dich ein.', nil, {'<green>'})
  self:createSubstrTrigger('Die goettliche Aura verlaesst Dich wieder.', nil, {'<red>'})

  -- Elementarschild
  local function eleschild(typ)
    return
      function()
        client.cecho('<bold><green>Elementarschild: '..typ..'<reset>')
        local typKurz = typ:lower():sub(1,2)
        base.statusUpdate({'eleschutz', typKurz})
      end
  end
  self:createMultiLineRegexTrigger('^Die Erde zu Deinen Fuessen woelbt sich und bricht auf\\. Ein irdener>< Schild schiesst empor und umgibt Dich\\.$', eleschild('Erde'), {'g'})
  self:createMultiLineRegexTrigger('^Eine Stichflamme schiesst vor Dir aus dem Boden und umgibt Dich mit>< einem feurigen Schild\\.$', eleschild('Feuer'), {'g'})
  self:createRegexTrigger('^Klirrende Kaelte umgibt Dich auf einmal schuetzend\\.$', eleschild('Eis'), {'g'})
  self:createMultiLineRegexTrigger('^Ein ploetzlicher Regenschauer prasselt hernieder, ohne Dich jedoch>< zu durchnaessen\\. Statt dessen umgibt Dich nun ein Schild aus Wasser\\.$', eleschild('Wasser'), {'g'})
  self:createRegexTrigger('^Ein starker Wind umtost Dich auf einmal und bildet so einen luftigen Schild\\.$', eleschild('Luft'), {'g'})
  self:createMultiLineRegexTrigger('^Eine Wolke aus Saeuregasen bildet sich um Dich herum. Einige Blitze>< erden sich durch die leitfaehigen gruenen Schwaden ab, einer haette Dich beinahe in den Fuss getroffen!$', eleschild('Saeure'), {'g'})
  self:createRegexTrigger('^Dein Elementarschild wird duenner\\.$', nil, {'<yellow>'})
  self:createRegexTrigger('^Der Elementarschild zerfaellt\\.$', statusUpdate('eleschutz'), {'<red>'})

  -- Elementarsphaere
  self:createMultiLineRegexTrigger(
    '^Ein Reissen geht durch Deinen Koerper, und die Welt um Dich herum>< scheint zu verschwimmen\\. Kandri bedient sich der Grundlagen von Lembolds Schoepfung, und um Dich herum erscheint ein Blase aus kristalline[mr] (\\w+)\\. Dann wird Deine Wahrnehmung wieder scharf\\.$',
    function(m)
      local typ = m[1]
      client.cecho('<bold><green>Elementarsphaere: '..typ..'<reset>')
      local typKurz = typ == 'Kaelte' and 'ei' or m[1]:lower():sub(1,2)
      base.statusUpdate({'elesphaere',typKurz})
    end,
    {'g'}
  )
  self:createRegexTrigger('^Deine Elementarsphaere bekommt duenne Stellen\\.$', nil, {'<yellow>'})
  self:createRegexTrigger('^Die Elementarsphaere loest sich auf\\.$', statusUpdate('elesphaere'), {'<red>'})

  -- Messerkreis
  self:createMultiLineRegexTrigger('^Kandri erfasst Dich mit ihrer Macht! Du beginnst zu gluehen! Das Gluehen>< weitet sich langsam aus und verdichtet sich zu einem leuchtenden Kreis um Deinen Koerper\\. Aus dem Leuchten heraus kondensieren auf einmal wirbelnde Messer, die jeder Bewegung Deines Koerpers folgen\\.', statusUpdate('messerkreis','Mk'), {'<green>'})
  self:createSubstrTrigger('Die wirbelnden Messer werden langsamer.', statusUpdate('messerkreis','Mk'), {'<yellow>'})
  self:createSubstrTrigger('Der Kreis wirbelnder Messer verschwindet wieder.', statusUpdate('messerkreis'), {'<red>'})

  -- Weihe
  self:createMultiLineRegexTrigger(
    '^Du sprichst ein kurzes, inbruenstiges Gebet\\.>< Ein\\w* (.*) leuchtet kurz auf, als Lembold Dein Gebet erhoert und die Waffe mit seinem Heiligen Zorn versieht\\.$',
    function(m)
      client.cecho('<bold><green>Weihe: '..m[1]..'<reset>')
      base.statusUpdate({'weihe','We'})
    end,
    {'g'}
  )
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
