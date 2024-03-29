-- Chaoten
--
-- der Default-Container wird für Dämonenausrüstung verwendet

local base   = require 'base'
local itemdb = require 'itemdb'
local inv    = require 'inventory'
local tools  = require 'utils.tools'
local timer  = require 'timer'
local kampf  = require 'battle'
local gmcp   = require 'gmcp-data'

local logger = client.createLogger('chaos')

local function state()
  return base.getPersistentTable('chaos')
end


-- nicht-persistenter Zustand
local aktDaemon = nil
local aktKampfDaemon = nil
local aktDaemonenWaffe = nil


local cont = inv.cont


-- ---------------------------------------------------------------------------
-- Skills

local function requiresAktKampfDaemon(f)
  if aktKampfDaemon == nil then
    logger.warn('Kein aktueller Kampfdaemon bekannt!')
  else
    f()
  end
end

-- chaospeitsche: schnell für daemonen
-- * heißt hier mit der hand bzw. peitsche wenn aktuelle Waffe eine ist
local function chaos_peitsche_daemon()
  requiresAktKampfDaemon(
    function()
      local schadenarten = inv.waffenschaden()
      if tools.listContains(schadenarten, 'pe') then
        client.send('peitsche '..aktKampfDaemon)
      else
        inv.doWithHands(1, 'peitsche '..aktKampfDaemon)
      end
    end
  )
end

local arten_magisch = {
  gi = 'gift', ei = 'eis', fe = 'feuer', st = 'sturm', lu = 'sturm',
  bl = 'blitz', bo = 'boese', kr = 'krach', wa = 'wasser',
  ma = 'magie', sa = 'saeure', te = 'terror',
}

local arten_physikalisch = {
  pe = 'peitsche', qu = 'quetschen', ex = 'explosion', wi = 'widerhaken',
  me = 'messer', pf = 'pfeil', fn = 'felsen',
}

local LCSCHADEN = { ch = 'chaos' }
tools.tableJoin(LCSCHADEN, arten_magisch)
tools.tableJoin(LCSCHADEN, arten_physikalisch)

local function damage(id)
  return LCSCHADEN[id] or ''
end

local function chaos_chaosschaden(id)
  client.send('chaosschaden '..damage(id))
end
local function chaos_chaoskontrolle(id1, id2)
  client.send('chaoskontrolle '..damage(id1)..' und '..damage(id2))
end

-- Erzeugt zu den Schadensarten der aktuellen Waffe einen Vorschlag fue
-- chaoskontrolle
-- return: art_magisch, art_physikalisch
local function _chaoten_schadens_vorschlag()
  local schadensArten = inv.waffenschaden() or {}
  local art_magisch = nil
  local art_physikalisch = nil
  for id,_ in pairs(arten_magisch) do
    if tools.listContains(schadensArten, id) then
      art_magisch = id
      break
    end
  end
  for id,_ in pairs(arten_physikalisch) do
    if tools.listContains(schadensArten, id) then
      art_physikalisch = id
      break
    end
  end
  return art_magisch, art_physikalisch
end

local function chaosschaden_auto()
  local artMagisch, _ = _chaoten_schadens_vorschlag()
  if artMagisch ~= nil then
    chaos_chaosschaden(artMagisch)
  end
end

local function chaoskontrolle_auto()
  local artMagisch, artPhysikalisch = _chaoten_schadens_vorschlag()
  if artMagisch ~= nil and artPhysikalisch ~= nil then
    chaos_chaoskontrolle(artMagisch, artPhysikalisch)
  end
end


-- ---------------------------------------------------------------------------
-- Dämonen

local daemonen = {}

-- lvl wird nur fuer kampfdaemonen angegeben
-- args: id langname [lvl]
local function _chaos_conf_add_daemon(id, name, lvl)
  daemonen[id] = { name = name, lvl = lvl }
end

-- Kampfdaemonen: id name daemonen_lvl zielstaerke
_chaos_conf_add_daemon('n', 'Nurchak', 12)
_chaos_conf_add_daemon('i', 'Irkitis', 15)
_chaos_conf_add_daemon('h', 'Harkuhu',  5)
_chaos_conf_add_daemon('g', 'Graiop',  12)
_chaos_conf_add_daemon('f', 'Flaxtri', 18)
_chaos_conf_add_daemon('t', 'Tutszt',  22)
_chaos_conf_add_daemon('y', 'Yrintri', 24)
-- andere Daemonen
_chaos_conf_add_daemon('s', 'Intarbir')
_chaos_conf_add_daemon('k', 'Kruftur')
_chaos_conf_add_daemon('b', 'Bhuturih')
_chaos_conf_add_daemon('ty', 'Tyoorthok')
_chaos_conf_add_daemon('o', 'Ombatis')
_chaos_conf_add_daemon('z', 'Haut')


local function set_daemon(id)
  local werte = daemonen[id]
  if werte ~= nil then
    aktDaemon = werte.name
    if werte.lvl then
      aktKampfDaemon = werte.name
    end
  end
end

local function chaos_beschwoere(id)
  set_daemon(id)
  if aktDaemon ~= nil then
    inv.doWithHands(2, aktDaemon..' leise')
  end
end

local function chaos_binde(id)
  set_daemon(id)
  if aktKampfDaemon ~= nil then
    client.send('binde '..aktKampfDaemon)
  end
end

local function chaos_verbanne(id)
  if id == nil then
    client.send('verbanne')
  else
    set_daemon(id)
    client.send('verbanne '..aktDaemon)
  end
end

-- DAEMONEN BEFEHLEN
--  folge, stop, folge leise, toete <name>, verschwinde, schweig,
--  sprich, wirf <objekt> weg  -  <objekt> waffe/ruestungen/alles
local function chaos_befehle(id, cmd)
  set_daemon(id)
  client.send('befehle '..aktDaemon..' '..cmd)
end

local function chaos_unt_daemon(id)
  if id ~= nil then
    set_daemon(id)
  end
  if aktKampfDaemon ~= nil then
    client.send('unt '..aktKampfDaemon)
  end
end

local chaosteamReihe1 = false
local function chaosteam()
  requiresAktKampfDaemon(
    function()
      client.send('chaosteam '..aktKampfDaemon)
      client.send('befehle '..aktKampfDaemon..' reihe 1')
      if chaosteamReihe1 then
        client.send('team reihe 1')
      else
        client.send('team reihe 2')
      end
      chaosteamReihe1 = not chaosteamReihe1
    end
  )
end

local function chaos_blutopfer()
  requiresAktKampfDaemon(
    function() client.send('blutopfer '..aktKampfDaemon) end
  )
end

local function chaos_friss_leiche()
  requiresAktKampfDaemon(
    function() client.send('befehle '..aktKampfDaemon..' friss leiche') end
  )
end

-- Aktuellen Daemon ruesten/entruesten mit Panzer/Stiefel/Helm.
local function chaos_druest(id)
  if id ~= nil and id ~= '-' then
    set_daemon(id)
  end
  if aktKampfDaemon == nil then
    logger.warn('Kein aktueller Kampfdaemon bekannt!')
    return
  end
  if id == '-' then
    client.send('befehle '..aktKampfDaemon..' wirf alles weg')
  else
    client.send('gib daemonenpanzer aus '..cont.default()..' an '..aktKampfDaemon)
    client.send('gib lederkleidung aus '..cont.default()..' an '..aktKampfDaemon)
    client.send('gib daemonenhelm aus '..cont.default()..' an '..aktKampfDaemon)
    client.send('gib daemonenstiefel aus '..cont.default()..' an '..aktKampfDaemon)
  end
end

-- waffenwechseln fuer daemonen (funktioniert evtl. nur bei tutszt):
-- gibt man tutszt eine neue waffe, wirft er automatisch die alte weg
local function chaos_dww(waffe)
  client.send('gib daemonenhandschuhe aus '..cont.default()..' an '..aktKampfDaemon)
  local _w = itemdb.waffenName(waffe)
  if (_w == nil) then
    _w = waffe
  end
  logger.info(aktKampfDaemon..' umruesten: '..(aktDaemonenWaffe or '')..' -> '..(_w or ''))
  if _w ~= nil then
    client.send('gib '.._w..' aus '..cont.default()..' an '..aktKampfDaemon)
  else
    client.send('befehle '..aktKampfDaemon..' wirf waffe weg')
  end
  client.send('befehle '..aktKampfDaemon..' wirf daemonenhandschuhe weg')
  aktDaemonenWaffe = _w
end

local CHAOTEN_DAEMON_STOP = false
local function daemon_stop_folge()
  if aktDaemon ~= nil then
    if CHAOTEN_DAEMON_STOP then
      client.send('befehle '..aktDaemon..' folge leise')
    else
      client.send('befehle '..aktDaemon..' stop')
    end
    CHAOTEN_DAEMON_STOP = not CHAOTEN_DAEMON_STOP
  end
end

local function bhuturih_finde(ziel)
  client.send('befehle bhuturih finde '..ziel)
end

local function ombatis_folge(ziel)
  client.send('befehle ombatis folge '..ziel)
end

local function tyoorthok_heile(ziel)
  client.send('befehle tyoorthok hilf '..ziel)
end

local function tyoorthok_untersuche(ziel)
  client.send('befehle tyoorthok untersuche '..ziel)
end

local function yrintri_wandel(art)
  client.send('befehle yrintri wandel dich zu '..damage(art))
end


-- ---------------------------------------------------------------------------
-- Statuszeile

local cs_arten = {}
cs_arten['harte Felsbrocken'] = 'fn'
cs_arten['rotierende Messer'] = 'me'
cs_arten['eherne Pfeile'] = 'pf'
cs_arten['wirbelnde Peitschenhiebe'] = 'pe'
cs_arten['gemeine Widerhaken'] = 'wi'
cs_arten['Daumenschrauben'] = 'qu'
cs_arten['explosive Magierschaedel'] = 'ex'

cs_arten['lodernde Flammenkugeln'] = 'fe'
cs_arten['frostige Eiswolken'] = 'ei'
cs_arten['aetzende Saeureregen'] = 'sa'
cs_arten['fuerchterliche Blitze'] = 'bl'
cs_arten['todbringende Stuerme'] = 'lu'
cs_arten['ueble Wasserstrahlen'] = 'wa'
cs_arten['konzentrierte Gifte'] = 'gi'
cs_arten['schrille Kampfschreie'] = 'kr'
cs_arten['magische Strahlen'] = 'ma'
cs_arten['hinterhaeltige Terrorattacken'] = 'te'
cs_arten['satanische Flueche'] = 'bo'

local ck_mag = {}
ck_mag['brennende'] = 'fe'
ck_mag['eisige'] = 'ei'
ck_mag['aetzende'] = 'sa'
ck_mag['blitzende'] = 'bl'
ck_mag['stuermische'] = 'lu'
ck_mag['fluessige'] = 'wa'
ck_mag['giftige'] = 'gi'
ck_mag['schreiende'] = 'kr'
ck_mag['magische'] = 'ma'
ck_mag['grauenvolle'] = 'te'
ck_mag['satanische'] = 'bo'

local ck_phy = {}
ck_phy['Felsbrocken'] = 'fn'
ck_phy['Messerschnitte'] = 'me'
ck_phy['Pfeile'] = 'pf'
ck_phy['Peitschenhiebe'] = 'pe'
ck_phy['Widerhaken'] = 'wi'
ck_phy['Daumenschrauben'] = 'qu'
ck_phy['Magierschaedel'] = 'ex'

local function chaoskontrolle_einstellung(m)
  local anzahl = m[1]
  local full = (m[2]=='' and m[2] or m[2]..' ') .. m[3]
  local art = cs_arten[full] or ck_mag[m[2]]..'+'..ck_phy[m[3]]
  local schadenKuerzel = anzahl..' '..art
  base.statusUpdate({'chaosball', schadenKuerzel})
end


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

-- schaetz (intarbir)
local intarbir_anwesend = false
local intarbir_trigger_an
local intarbir_trigger_aus
local intarbir_cmd = nil

intarbir_trigger_an = client.createSubstrTrigger(
  'Intarbir kommt an.',
  function()
    intarbir_anwesend = true
    client.disableTrigger(intarbir_trigger_an)
    client.enableTrigger(intarbir_trigger_aus)
    if intarbir_cmd ~= nil then
      client.send(intarbir_cmd)
    end
    intarbir_cmd = nil
  end
)
intarbir_trigger_aus = client.createSubstrTrigger(
  'Intarbir verlaesst diese Welt.',
  function()
    intarbir_anwesend = false
    client.disableTrigger(intarbir_trigger_aus)
  end
)
client.disableTrigger(intarbir_trigger_an)
client.disableTrigger(intarbir_trigger_aus)

local function chaos_schaetz(ziel)
  intarbir_cmd = 'befehle intarbir schaetz '..ziel..' ein'
  if intarbir_anwesend then
    client.send(intarbir_cmd)
    intarbir_cmd = nil
  else
    client.enableTrigger(intarbir_trigger_an)
    client.send('intarbir leise')
  end
end

-- identifiziere (kruftur)
local kruftur_anwesend = false
local kruftur_trigger_an
local kruftur_trigger_aus
local kruftur_cmd = nil

kruftur_trigger_an = client.createRegexTrigger(
  '^(Kruftur kommt an\\.|Du beschwoerst magische Kraefte, doch da Kruftur schon da ist, passiert|Kannst Du nicht mehr zaehlen\\?|Was willst Du mit zwei Daemonen\\?|Bist Du blind oder senil\\? Du hast doch Kruftur schon beschworen\\.|Kruftur ist doch schon da!)',
  function()
    kruftur_anwesend = true
    client.disableTrigger(kruftur_trigger_an)
    client.enableTrigger(kruftur_trigger_aus)
    if kruftur_cmd ~= nil then
      client.send(kruftur_cmd)
    end
    kruftur_cmd = nil
  end
)
kruftur_trigger_aus = client.createSubstrTrigger(
  'Kruftur verschwindet als Inspirationspartikel.',
  function()
    kruftur_anwesend = false
    client.disableTrigger(kruftur_trigger_aus)
  end
)
client.disableTrigger(kruftur_trigger_an)
client.disableTrigger(kruftur_trigger_aus)

local function chaos_identifiziere(ziel)
  kruftur_cmd ='befehle kruftur identifiziere '..ziel
  if kruftur_anwesend then
    client.send(kruftur_cmd)
    kruftur_cmd = nil
  else
    client.enableTrigger(kruftur_trigger_an)
    client.send('kruftur leise')
  end
end


-- ---------------------------------------------------------------------------
-- Helper

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

local function createFunctionSchutzMitStaerke(staerke)
  return
    function()
      inv.doWithHands(1, 'schutz '..staerke)
    end
end


-- ---------------------------------------------------------------------------
-- Guild class Chaos

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Chaos = class(Guild)

function Chaos:identifiziere(item)
  chaos_identifiziere(item)
end

function Chaos:schaetz(item)
  chaos_schaetz(item)
end

function Chaos:info()
  client.send('chaoswer in para')
end

function Chaos:enable()
  -- Statuszeile -------------------------------------------------------------
  local statusConf = 'CB:{chaosball:11}  {schutz:2}'
  base.statusConfig(statusConf)

  self:createRegexTrigger(
    '^Die naechsten ([0-9]+) Chaosbaelle sind: ([a-z]+)? ?([A-Z][a-z]+)\\.$',
    chaoskontrolle_einstellung
  )

  -- ---------------------------------------------------------------------------
  -- Zauber

  -- schutz
  self:createRegexTrigger(
    '^Deine Chaoshaut schuetzt Dich jetzt (etwas|wesentlich) besser\\.',
    function(m)
      local schutz = m[1] == 'wesentlich' and 'S+' or 'S'
      base.statusUpdate({'schutz', schutz})
    end,
    {'<green>'}
  )
  self:createSubstrTrigger('Der magische Schutz Deiner Chaoshaut wird gleich verschwinden!', nil, {'<yellow>'})
  self:createSubstrTrigger(
    'Der magische Schutz der Chaoshaut verschwindet.',
    function(m)
      base.statusUpdate({'schutz'})
    end,
    {'<red>'}
  )

  -- nachtsicht
  self:createSubstrTrigger('Du veraenderst magisch Deine Augen.', nil, {'<green>'})
  self:createSubstrTrigger('Die Magie Deiner Augen laesst nach und verschwindet.', nil, {'<red>'})

  -- finsternis
  self:createRegexTrigger(
    '^Du huellst .* in eine Wolke aus Finsternis ein\\.',
    function()
      timer.enqueue(
        120,
        function()
          logger.info('finsternis wieder moeglich (120 sec)')
        end
      )
    end,
    {'<cyan>'}
  )

  -- daemonenpeitsche
  self:createRegexTrigger(
    '^(Yrintri|Tutszt|Flaxtri|Graiop|Nurchak|Harkuhu|Irkitis) steigert sich in wilde Raserei!',
    nil,
    {'<green>'}
  )
  self:createRegexTrigger(
    '^(Yrintri|Tutszt|Flaxtri|Graiop|Nurchak|Harkuhu|Irkitis) hat die letzte Zuechtigung noch nicht verkraftet\\.',
    nil,
    {'<blue>'}
  )

  -- blutopfer
  self:createSubstrTrigger('Mit einem grimmigen Aufschrei, rammst Du', nil, {'<green>'})
  self:createSubstrTrigger('naehrt sich an Deinem Blut.', nil, {'<cyan>'})
  self:createSubstrTrigger('will Dein Opfer nicht mehr.', nil, {'<red>'})

  -- dimensionsriss
  self:createSubstrTrigger(
    'durch einen winzigen Dimensionsriss gesaugt',
    function()
      logger.warn('AUSRUESTUNG WURDE ZUR CHAOSGILDE (Chaosteleporter) teleportiert!')
    end,
    {'<red>','B'})

  -- Lernerfolg
  self:createSubstrTrigger('Die Macht des Chaos durchstroemt Dich und macht Dich staerker.', nil, {'<magenta>'})

  -- Chaoshaut ---------------------------------------------------------------

  self:createSubstrTrigger(
    'DER DAEMON IN DEINER HAUT WIRD GLEICH VERSUCHEN SICH ZU BEFREIEN!!!',
    function()
      client.send('kontrolle')
    end,
    {'<magenta>','B'}
  )
  self:createSubstrTrigger('Du erlangst die Kontrolle ueber die Chaos-Ruestung zurueck.', nil, {'<green>'})

  -- Daemonenausruestung -----------------------------------------------------
  local function zeug_retten()
    client.send('stecke daemonenpanzer in '..cont.default())
    client.send('stecke lederkleidung in '..cont.default())
    client.send('stecke daemonenhelm in '..cont.default())
    client.send('stecke daemonenstiefel in '..cont.default())
    if aktDaemonenWaffe ~= nil then
      client.send('stecke '..aktDaemonenWaffe..' in '..cont.default())
    end
  end

  self:createSubstrTrigger('Yrintri beendet seine Daseinsform.', zeug_retten)
  self:createSubstrTrigger('Tutszt bildet einen grossen Blutfleck.', zeug_retten)
  self:createSubstrTrigger('Flaxtri verschwindet brodelnd im Erdreich.', zeug_retten)
  self:createSubstrTrigger('Graiop verschwindet in einer Feuerexplosion.', zeug_retten)
  self:createSubstrTrigger('Nurchak zerfaellt zu einem Haufen Eiskristalle.', zeug_retten)
  self:createSubstrTrigger('Harkuhu verschwindet in einem Lichtblitz.', zeug_retten)
  self:createSubstrTrigger('Irkitis oeffnet eine unsichtbare Tuer und verschwindet.', zeug_retten)

  self:createRegexTrigger(
    '^(Yrintri|Tutszt|Flaxtri|Graiop|Nurchak|Harkuhu|Irkitis) laesst.* (\\w+) fallen\\.',
    function(m)
      if m[1] == aktKampfDaemon then
        client.send('stecke '..m[2]..' in '..cont.default())
      end
    end
  )

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5   = chaosteam
  keymap.S_F5 = daemon_stop_folge
  keymap.F6   = chaos_blutopfer
  keymap.S_F6 = chaos_friss_leiche
  keymap.F7   = createFunctionMitGegner('verbanne')
  keymap.S_F7 = 'dimensionsriss'
  keymap.F8   =
    function()
      local cmd = gmcp.guild_level >= 5 and 'chaosball' or 'chaoswolke'
      client.send(cmd..' '..kampf.getGegner())
    end
  keymap.S_F8 = chaoskontrolle_auto

  keymap.M_k = chaos_unt_daemon
  keymap.M_v = createFunctionSchutzMitStaerke('stark')
  keymap.M_m = createFunctionSchutzMitStaerke('')
  keymap.M_b = createFunctionSchutzMitStaerke('schwach')
  keymap.M_f = createFunctionMitGegner('finsternis')
  keymap.M_x = chaos_peitsche_daemon

  keymap.M_l = 'nachtsicht'
  keymap.M_d = 'dunkelheit'
  keymap.M_y = chaosschaden_auto
  keymap.M_z = chaos_binde

  keymap.M_p = createFunctionMitHands(2, 'chaosruestung')
  keymap.M_i = 'kontrolle'
  keymap.M_r = chaos_druest
  keymap.M_e = function() chaos_druest('-') end

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills', 0, function() client.send('tm kruuolq faehigkeiten') end
  )
  client.createStandardAlias(
    'quests', 0, function() client.send('tm hutschat aufgaben') end
  )
  client.createStandardAlias('cs', 1, chaos_chaosschaden)
  client.createStandardAlias('ck', 2, chaos_chaoskontrolle)

  client.createStandardAlias('d',  1, chaos_beschwoere)
  client.createStandardAlias('b',  1, chaos_binde)
  client.createStandardAlias('v',  1, chaos_verbanne)
  client.createStandardAlias('bef', 2, chaos_befehle)
  client.createStandardAlias('u',  1, chaos_unt_daemon)
  client.createStandardAlias('druest', 1, chaos_druest)
  client.createStandardAlias('dww', 1, chaos_dww)
  client.createStandardAlias('dfi', 1, bhuturih_finde)
  client.createStandardAlias('dnerv', 1, ombatis_folge)
  client.createStandardAlias('dheile', 1, tyoorthok_heile)
  client.createStandardAlias('dunt', 1, tyoorthok_untersuche)
  client.createStandardAlias('dcs', 1, yrintri_wandel)
end


return Chaos
