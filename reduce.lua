
local regex = client.regex

-- basiert urspruenglich auf reduce.tf aus TinyMacros:
-- https://github.com/jexp/TinyMacros
-- (dem Nachfolger von Ringors legendaerem kampfmeldungen.tf)

-- BEDEUTUNG DER AUSGABE
-- ---------------------
--  ________ Rueckendeckung
-- | _______ Parade / Schildparade
-- || ______ Waffe
-- ||| _____ Schild
-- |||| ____ Panzer / Umhang
-- ||||| ___ Amulett
-- |||||| __ Helm
-- ||||||| _ Ring
-- ||||||||
-- R*******  Ziel bekommt Rueckendeckung von einem Spieler.
-- 2*******  Ziel bekommt Rueckendeckung von zwei Spielern. 3-n analog dazu ;-)
-- *P******  Ziel hat den Schlag mit Waffenparade abgewehrt (magenta=selber, gelb=Gegner)
-- *S******  Ziel hat den Schlag mit Schildparade abgewehrt
-- *2******  Parade mit Schild und Waffe
-- **S*****  SMS-Abwehr (Schwert oder Speer)
-- **M*****  der Magiewesenzahn zieht MP
-- **L*****  der Magiewesenzahn zieht LP
-- ***K****  Kieferknochen
-- ***D****  Drachenschuppe(Abwehr)
-- ***H****  Drachenschuppe(Heilung)
-- ***1****  Skillschild faengt mit niedrigster Stufe
-- ***5****  Skillschild faengt mit maximaler Stufe
-- ****R***  Paracelsus' gruene Robe
-- ****U***  Bambis Umhang
-- ****T***  Tsunamis Toga heilt
-- ****E***  Eistrollschamanenpanzer
-- ****G***  Panzer der Gier hat gesaugt
-- ****M***  Robe der Magie gibt KP zurueck
-- ****A***  Aura der Delfen
-- ****Z***  Zauberschild
-- ****2***  2 von diesen Items (auch 3 usw.)
-- *****G**  Silvanas Gluecksbringer
-- *****K**  Morgoths Himmelkreuz oder das Kreuz aus der Gruft
-- *****N**  Nonnes Nixenhaaar
-- *****A**  Grummelbeisseramuletit
-- *****O**  Obsidianamulett von Ananas
-- ******T*  Toeters Totenschaedel
-- ******H*  Morgoths Eishelm
-- ******P*  Tillys Pudelmuetze
-- ******M*  Tsunamis Myrthenkranz
-- ******C*  Tillys Chaosball
-- ******A*  Die Maske von Patryns Riesen
-- ******F*  Feuerhelm
-- ******2*  2 von diesen Items (auch 3 usw.)
-- *******D  Paracelsus' Drachenring
-- *******A  AFR oder AER
-- *******R  so ein roetlich leuchtender Ring
-- *******E  der oktarine Ring aus Para-Moulokin saugt einem Feind Energie
-- *******S  der oktarine Ring aus Para-Moulokin saugt einem selbst Energie
-- *Xxxxx**  Ziel hat mit einer Karatetechnik abgewehrt. Bei eigener Abwehr
--           bedeutet 'magenta' eine gelungene und 'rot' eine misslungene
--           Abwehr. Analog dazu werden die Farben 'gelb' und 'blau' fuer
--           Karate-Abwehr von Gegnern benutzt.
-- *Auswe**  ein Karateka oder Kaempfer weicht Magie aus
-- *DeSch**  Schutzschild der Dunkelelfen


local debug_flag = false
local damage_threshold = 0

local RE_SICHER
local RE_ART
local RE_ART_COLOR
local RE_WFUNC
local RE_ANGREIFER
local RE_FLAECHE_ART
local RE_FLAECHE_ANGREIFER
local RE_FLAECHE_ZEIT = 0
local RE_WAFFE
local RE_OPFER
local RE_RICHTUNG
local RE_ABWEHR
local RE_SCHADEN
local RE_SCHADEN_SUB
local RE_KARATE
local RE_KARATE_ABWEHR
local RE_ABWEHR
local RE_ABWEHR_COLOR
local RE_TMP_TRENNER

local RE_ANGRIFFSWAFFEN_MERKER = {}

local RE_SCHADENLISTE = {}
local RE_COLORLISTE = {}

local outputListener = nil

local function config(val, text, color)
  RE_SCHADENLISTE[val] = text..'<reset>'
  RE_COLORLISTE[val] = color or '<reset>'
  if val > 1 and val < 14 then
    RE_SCHADENLISTE[val+100] = (color or '<reset>')..'Maximum!<reset>'
    RE_COLORLISTE[val+100] = color or '<reset>'
  end
end

config(0, 'DEFEND', nil)
config(1, 'verfehlt', nil)
config(2, 'gekitzelt', '<green>')
config(3, 'gekratzt', '<green>')
config(4, 'getroffen', '<yellow>')
config(5, 'hart', '<yellow>')
config(6, 'sehr hart', '<yellow>')
config(7, 'Krachen', '<magenta>')
config(8, 'Schmettern', '<magenta>')
config(9, 'zu Brei', '<red>')
config(10, 'Pulver', '<red>')
config(11, 'zerstaeubt', '<bgred>')
config(12, 'atomisiert', '<bgred>')
config(13, 'vernichtet', '<bgmagenta>')
config(15, 'Fehler!', nil)

-- Trigger, die weitere Trigger zur Schadenserkennung aktivieren
local PRIO_AKT = 300
-- Standard fuer einzelne Trigger und temporaere Trigger zur Schadenserkennung
local PRIO_DEFAULT = 200
-- Normalangriff erst nach den spezifischeren Triggern
local PRIO_NORMALANGRIFF = 100

local FLAECHE_DELAY = 4

local RE_STYLE
if debug_flag then
  RE_STYLE = {'<cyan>'}
else
  RE_STYLE = {'g'}
end

local logger = client.createLogger('reduce')


-- map triggerId -> Zeitpunkt der Entfernung
local timed_triggers = {}

-- helper: id oder table von ids angebbar
-- optionaler parameter secs: nach dieser Zeit wird der trigger entfernt
local function enableTrigger(ids, secs)
  if secs ~= nil then
    local triggerEndTime = os.time() + secs
    if type(ids) == 'table' and ids[1] then
      for _,id in ipairs(ids) do
        timed_triggers[id] = triggerEndTime
      end
    else
      timed_triggers[ids] = triggerEndTime
    end
  end
  client.enableTrigger(ids)
end

local disableTrigger = client.disableTrigger


local reduce_trigger = {}

local function createSubstrTrigger(pattern, f, prio, style)
  local id = client.createSubstrTrigger(pattern, f, style or RE_STYLE, prio or PRIO_DEFAULT)
  reduce_trigger[#reduce_trigger+1] = id
  return id
end

local function createRegexTrigger(pattern, f, prio, style)
  local id = client.createRegexTrigger(pattern, f, style or RE_STYLE, prio or PRIO_DEFAULT)
  reduce_trigger[#reduce_trigger+1] = id
  return id
end

local function createMultiLineRegexTrigger(pattern, f, prio, style)
  local id = client.createMultiLineRegexTrigger(pattern, f, style or RE_STYLE, prio or PRIO_DEFAULT)
  reduce_trigger[#reduce_trigger+1] = id
  return id
end

local function remove_reduce()
  client.killTrigger(reduce_trigger)
  client.cecho('<red>>>> Entferne Paket: <yellow>reduce.lua<reset>')
end

-- Variablen, die jede Kampfrunde geloescht werden
local function re_loeschen()
  RE_ART = 'normal'
  RE_ART_COLOR = nil
  RE_SICHER = true
  RE_WAFFE = '???'
  RE_ANGREIFER = '???'
  RE_OPFER = '???'
  RE_RICHTUNG = nil
  RE_SCHADEN = nil
  RE_SCHADEN_SUB = 0
  RE_KARATE = 0
  RE_KARATE_ABWEHR = ''
  RE_ABWEHR = {}
  RE_ABWEHR_COLOR = {
    RDECKUNG = '<magenta>',
    PARADE = '<magenta>',
    WAFFE = '<green>',
    SCHILD = '<green>',
    RUESTUNG = '<green>',
    AMULETT = '<magenta>',
    HELM = '<magenta>',
    RING = '<magenta>'
  }
  RE_TMP_TRENNER = nil
end
re_loeschen()

local function abwehr_helfer(typ, val, farbe)
  local akt = RE_ABWEHR[typ]
  if akt == nil then
    RE_ABWEHR[typ] = val
  elseif type(val) == 'number' then
    RE_ABWEHR[typ] = val+1
  else
    RE_ABWEHR[typ] = 2
  end
  if farbe ~= nil then
    RE_ABWEHR_COLOR[typ] = farbe
  end
end

local function trenner_helfer(symbol, color)
  RE_TMP_TRENNER = color..symbol..'<reset>'
end

local function pad(s, length)
  s = s or ''
  local s_without_color = string.gsub(s, '<[^>]*>', '')
  local n = length - s_without_color:len()
  return string.rep('_', n)
end

local function colorBlue(name, flag)
  if flag and name ~= '???' and not string.match(name, '<') then
    return '<blue>' .. name .. '<reset>'
  end
  return name
end

local function getSchadenRichtung()
  if RE_RICHTUNG == 'out' then
    return '<green>-><reset>'
  elseif RE_RICHTUNG == 'in' then
    if RE_TMP_TRENNER ~= nil then
      return '<red><'..RE_TMP_TRENNER
    else
      return '<red><-<reset>'
    end
  else
    return '--'
  end
end

local function re_leerzeichenkuerzen(name)
  name = string.gsub(name, '-', '')
  name = string.gsub(name, ' ', '')
  return name
end

local function re_genitiv_loeschen(name)
  if name == 'Deiner' then
    return 'Du'
  end
  if string.match(name, '.*s$') or string.match(name, '.*\'$') then
    name = name:sub(1, -2)
  end
  return name
end

local RE_ARTIKEL = regex('^(:?[Dd](:?e(:?[rsmn]|in(:?e[srnm]?)?)|ie|as)|[Ee]in(e[srmn]?)?) ')
local function re_artikelkuerzen(name)
  name = name or ''
  local name_short = RE_ARTIKEL:replace(name, '')
  return name_short
end

local function re_namekuerzen(name, length)
  if length == nil then
    local teilname_gross = string.match(name, '[A-Z].*')
    if teilname_gross ~= nil then
      return teilname_gross
    else
      return name
    end
  end
  if name:len() > length+3 then
    local teilname_gross = string.match(name, '[A-Z].*')
    if teilname_gross ~= nil then
      name = teilname_gross
    end
    if name:len() > length+3 then
      name = re_leerzeichenkuerzen(name)
    end
  end
  return name:sub(1, length)
end

local function abwehr(typ, is_eigener_schaden)
  local val = RE_ABWEHR[typ]
  if val == nil then
    return '*'
  end
  if is_eigener_schaden then
    local color = RE_ABWEHR_COLOR[typ] or '<reset>'
    return color..val..'<reset>'
  else
    return val
  end
end

local function getAbwehr(is_eigener_schaden)
  local mitte = ''
  if RE_KARATE > 0 then
    local abwehr_karate = RE_KARATE_ABWEHR:sub(1,5)
    local abwehr_karate = abwehr_karate:sub(1,5) .. '<reset>'
      .. string.rep('*', 5-abwehr_karate:len())
    local color = ''
    if RE_KARATE == 4 then
      color = '<magenta>'  -- eigene Abwehr gelungen
    elseif RE_KARATE == 3 then
      color = '<yellow>'   -- fremde Abwehr gelungen
    elseif RE_KARATE == 2 then
      color = '<red>'      -- eigene Abwehr misslungen
    else
      color = '<blue>'     -- fremde Abwehr misslungen
    end
    mitte = color .. abwehr_karate
  else
    mitte = abwehr('PARADE',is_eigener_schaden)
      .. abwehr('WAFFE', is_eigener_schaden) .. abwehr('SCHILD', is_eigener_schaden)
      .. abwehr('RUESTUNG', is_eigener_schaden) .. abwehr('AMULETT', is_eigener_schaden)
  end
  return abwehr('RDECKUNG', is_eigener_schaden)
    .. mitte
    .. abwehr('HELM', is_eigener_schaden)
    .. abwehr('RING', is_eigener_schaden)
end

local function getSchaden()
  if RE_SCHADEN == nil then
    return ''
  end
  local RE_SCHADEN_OUT
  if RE_SCHADEN >= 0 and RE_SCHADEN < 14 then
    RE_SCHADEN_OUT = RE_SCHADENLISTE[RE_SCHADEN]
    local RE_SUBSCHADEN = ''
    if RE_SCHADEN_SUB < 0 then
      RE_SCHADEN_OUT = RE_SCHADEN_OUT:sub(1,7)
      RE_SUBSCHADEN = '(-)'
    elseif RE_SCHADEN_SUB > 0 then
      RE_SCHADEN_OUT = RE_SCHADEN_OUT:sub(1,7)
      RE_SUBSCHADEN = '(+)'
    end
    RE_SCHADEN_OUT = RE_SCHADEN_OUT..RE_SUBSCHADEN
  elseif RE_SCHADEN > 100 and RE_SCHADEN < 114 then
    RE_SCHADEN_OUT = RE_SCHADENLISTE[RE_SCHADEN]
  else
    RE_SCHADEN_OUT = RE_SCHADENLISTE[15]
  end
  return (RE_COLORLISTE[RE_SCHADEN] or '<reset>')..RE_SCHADEN_OUT..'<reset>'
end

local art_color_table = {
  normal = '<green>',
  extra = '<magenta>',
  Magie = '<magenta>',
  Chaos = '<magenta>',
  Zauberei = '<magenta>',
  Klerus = '<magenta>',
  Tanjian = '<magenta>',
  Delfen = '<magenta>',
  Artillerie = '<blue>'
}

local function re_ausgabe_zeile()
  local is_eigener_schaden = RE_RICHTUNG == 'in' or RE_RICHTUNG == 'out'
  local art_color = ''
  if is_eigener_schaden then
    art_color = RE_ART_COLOR or art_color_table[RE_ART] or '<green>'
  end
  local art = art_color..RE_ART..'<reset>'
  local opfer = re_namekuerzen(RE_OPFER, 13)
  local angreifer = re_namekuerzen(RE_ANGREIFER, 13)
  local waffe = re_namekuerzen(RE_WAFFE, 12)
  local sichere_erkennung = '<reset>/'
  if not RE_SICHER then
    sichere_erkennung = '<red>/<reset>'
  end
  local output =
    ':: ' .. pad(art,10) .. art
    .. sichere_erkennung .. colorBlue(waffe, is_eigener_schaden) .. pad(waffe, 12)
    .. ' ' .. colorBlue(angreifer, is_eigener_schaden) .. pad(angreifer, 13)
    .. ' : ' .. colorBlue(opfer, is_eigener_schaden) .. pad(opfer, 13)
    .. ' ' .. getAbwehr(is_eigener_schaden)
    .. ' ' .. getSchadenRichtung()
    .. ' ' .. getSchaden()
    .. '<reset>'
  if RE_SCHADEN ~= nil and RE_SCHADEN >= damage_threshold then
    client.cecho(output)
  end
  return output
end

local RE_REGEXP_SELF = regex('^D(:?u|i(:?ch|r)|ein(:?e[nmr]?)?)$')

local function re_ausgabe_vorbereiten()
  RE_ANGREIFER = re_artikelkuerzen(RE_ANGREIFER)
  RE_OPFER = re_artikelkuerzen(RE_OPFER)
  if RE_REGEXP_SELF:match(RE_ANGREIFER) then
    RE_ANGREIFER = 'Du'
    RE_RICHTUNG = 'out'
  elseif RE_REGEXP_SELF:match(RE_OPFER) then
    RE_OPFER = 'Dich'
    RE_RICHTUNG = 'in'
  else
    RE_RICHTUNG = 'other'
  end
  if RE_WFUNC ~= nil then
    RE_ART = RE_WFUNC
    RE_WFUNC = nil
  end
end

local function re_waffe_geraten()
  RE_SICHER = false
end

local function re_waffe_restaurieren()
  logger.debug('restauriere Waffe fuer Angreifer "' .. RE_ANGREIFER .. '"')
  local merker = RE_ANGRIFFSWAFFEN_MERKER[RE_ANGREIFER]
  if merker ~= nil then
    RE_WAFFE = merker.waffe
    RE_ART = merker.art
    RE_ART_COLOR = merker.color
    re_waffe_geraten()
  end
end

local function re_ausgabe()
  re_ausgabe_vorbereiten()
  if RE_WAFFE == '???' then
    if RE_ANGREIFER == RE_FLAECHE_ANGREIFER and (os.time() - RE_FLAECHE_ZEIT) < FLAECHE_DELAY then
      RE_WAFFE = RE_FLAECHE_WAFFE
      RE_ART = RE_FLAECHE_ART
      re_waffe_geraten()
    else
      RE_FLAECHE_ANGREIFER = nil
      re_waffe_restaurieren()
    end
  end
  -- zeitlich begrenzte Trigger loeschen
  if #timed_triggers > 0 then
    for id,t in pairs(timed_triggers) do
      if os.time() > t then
        timed_triggers[id] = nil
      end
    end
  end
  local output = re_ausgabe_zeile()
  re_loeschen()
  if outputListener ~= nil then
    outputListener(output)
  end
end

local function re_macro(meldung_vor, meldung_nach, line)
  if string.match(meldung_nach, '^sehr.*$') then
    RE_SCHADEN = 6
  elseif meldung_nach == 'hart' then
    RE_SCHADEN = 5
  elseif string.match(meldung_nach, '^mit dem.*$') then
    RE_SCHADEN = 7
  elseif meldung_nach == 'zu Brei' then
    RE_SCHADEN = 9
  elseif string.match(meldung_vor, '^verfehl.*$') then
    RE_SCHADEN = 1
  elseif string.match(meldung_vor, '^kitzel.*$') then
    RE_SCHADEN = 2
  elseif string.match(meldung_vor, '^kratzt.*$') then
    RE_SCHADEN = 3
  elseif string.match(meldung_vor, '^triff.*$') then
    RE_SCHADEN = 4
  elseif string.match(meldung_vor, '^zerschmetter.*$') then
    RE_SCHADEN = 8
  elseif string.match(meldung_vor, '^pulverisier.*$') then
    RE_SCHADEN = 10
  elseif string.match(meldung_vor, '^zerstaeub.*$') then
    RE_SCHADEN = 11
  elseif string.match(meldung_vor, '^atomisier.*$') then
    RE_SCHADEN = 12
  elseif string.match(meldung_vor, '^vernichte.*$') then
    RE_SCHADEN = 13
  else
    logger.debug('Fehler bei Standard-Schaden, meldung_vor: '..meldung_vor)
    re_loeschen()
    client.cecho(line)
  end
  re_ausgabe()
end

local KARATE_ABKUERZUNGEN = {}

local function karate_ausnahme(lang, kurz)
  KARATE_ABKUERZUNGEN[lang] = kurz
end

karate_ausnahme('Awase-zuki', 'Awz')
karate_ausnahme('Fumikomi-geri', 'Fog')
karate_ausnahme('Hasami-zuki', 'Haz')
karate_ausnahme('Kagi-zuki', 'Kaz')
karate_ausnahme('Kizami-zuki', 'Kiz')
karate_ausnahme('Mae-geri-keage', 'Mgka')
karate_ausnahme('Mawashi-geri', 'Mag')
karate_ausnahme('Heito-uke', 'Htu')
karate_ausnahme('Kakiwake-uke', 'Kiu')
karate_ausnahme('Keito-uke', 'Keu')
karate_ausnahme('Morote-tsukami-uke', 'Motsu')
karate_ausnahme('Shuto-uke', 'Shu')
karate_ausnahme('Soto-sukui-uke', 'Ssuu')
karate_ausnahme('Uchi-sukui-uke', 'Usuu')

local function re_karatekuerzen(technik)
  local abkuerzung = KARATE_ABKUERZUNGEN[technik]
  if abkuerzung ~= nil then
    return abkuerzung
  end
  abkuerzung = ''
  local index = 0
  while index ~= nil do
    abkuerzung = abkuerzung .. technik:sub(index+1, index+1)
    index = string.find(technik, '-', index+1)
  end
  KARATE_ABKUERZUNGEN[technik] = abkuerzung
  return abkuerzung
end


-- ---------------------------------------------------------------------------
-- trigger utils

-- last spell triggers: table of trigger ids
local last_spell_tmp_triggers

local function enableTriggers_sd(ids)
  if last_spell_tmp_triggers ~= nil then
    disableTrigger(last_spell_tmp_triggers)
  end
  last_spell_tmp_triggers = ids
  enableTrigger(ids)
end


-- spell defend (reduce.tf ruft re_loeschen auf)
createRegexTrigger(
  '^([A-Z].*) (wehrt|wehrst) (Deinen|den) (Spruch|Zauber) ab\\.',
  function(m)
    RE_SCHADEN = 0
    if last_spell_tmp_triggers ~= nil then
      disableTrigger(last_spell_tmp_triggers)
      last_spell_tmp_triggers = nil
    end
    if RE_OPFER == '???' then
      RE_OPFER = m[1]
    end
    if RE_WAFFE == '???' then
      RE_WAFFE = 'Spell'
    end
    re_ausgabe()
  end
)


-- ---------------------------------------------------------------------------
-- Statusauswertung
-- ---------------------------------------------------------------------------

local status_map = {}

local RE_STATUS_ATTR = {
  _100 = '<blue>',
  _90 = '<blue>',
  _80 = '<green>',
  _70 = '<green>',
  _60 = '<yellow>',
  _50 = '<yellow>',
  _40 = '<magenta>',
  _30 = '<magenta>',
  _20 = '<red>',
  _10 = '<red>',
  _0 = '<reset>'
}

local function substring_ab(s, pattern)
  local index = string.find(s, pattern)
  if index then
    return s:sub(index+2)
  else
    return s
  end
end

local function ausgabe_status(name, status)
  local name_kurz = re_namekuerzen(re_artikelkuerzen(substring_ab(name, ': ')))
  local color = RE_STATUS_ATTR['_'..status]
  client.cecho('<blue>'..name_kurz..': '..color..status..'%<reset>')
end

local function ermittle_status(status_meldung)
  for pattern,status in pairs(status_map) do
    local index = string.find(status_meldung, pattern, 1, true)
    if index then
      local name = status_meldung:sub(1, index-2)
      ausgabe_status(name, status)
      return
    end
  end
end

local function def_status(meldung, val, createTrigger)
  status_map[meldung] = val
  if createTrigger then
    createSubstrTrigger(
      meldung,
      function(m)
        ermittle_status(m.line)
      end
    )
  end
end

def_status('ist absolut fit.', 100, true)
def_status('ist leicht geschwaecht.', 90, true)
def_status('fuehlte sich auch schon besser.', 80, true)
def_status('ist leicht angekratzt.', 70, true)
def_status('ist nicht mehr taufrisch.', 60, true)
def_status('sieht recht mitgenommen aus.', 50, true)
def_status('wankt bereits bedenklich.', 40, true)
def_status('ist in keiner guten Verfassung.', 30, true)
def_status('braucht dringend einen Arzt.', 20, true)
def_status('steht auf der Schwelle des Todes.', 10, true)
-- Karateka
def_status('ist schon etwas geschwaecht.', 90, true)
def_status('fuehlte sich heute schon besser.', 80, true)
def_status('ist leicht angeschlagen.', 70, true)
def_status('sieht nicht mehr taufrisch aus.', 60, true)
def_status('macht einen mitgenommenen Eindruck.', 50, true)
-- Rest wird durch zentrale Trigger mit Prefix abgehandelt
def_status('ist schon ein wenig schwaecher.', 90)
def_status('fuehlte sich heute auch schon besser.', 80)
def_status('sieht ein wenig angekratzt aus.', 70)
def_status('ist deutlich angekratzt.', 60)
def_status('schwankt und wankt.', 40)
def_status('war auch schon in besserer Verfassung.', 30)
def_status('war auch schon mal besserer drauf.', 30)
def_status('war auch schon mal deutlich besser drauf.', 30)
def_status('braucht dringend aerztliche Behandlung.', 20)
def_status('ist schon so gut wie bei Lars.', 10)
def_status('steht auf der Schwelle zu einer besseren Welt.', 10)
def_status('braucht den beruehmten Arzt.', 20)
def_status('hats mit der Verfassung.', 30)
def_status('wankt und schwankt. Sieht gut fuer uns aus :-)', 40)
def_status('sieht zum Mitnehmen aus.', 50)
def_status('ist nicht mehr frisch. Und wie Tau schon gar nicht!', 60)
def_status('hat schon einige Kratzer abbekommen.', 70)
def_status('fuehlte sich auch schon schlechter.', 80)
def_status('ist ganz ganz leicht angeschwaechlicht.', 90)
def_status('ist absolut fit. Was immer das heissen mag...', 100)

local function ermittle_status_kampfinfo(m)
  ermittle_status(m[1])
end

-- Kampfinfo der Matrix
createRegexTrigger(
  '^Matrix: (.*)',
  ermittle_status_kampfinfo
)

-- Daemonen
createRegexTrigger(
  '^(Tutszt|Harkuhu|Graiop|Yrintri|Irkitis|Flaxtri|Nurchak) teilt Dir mit: (.*)',
  ermittle_status_kampfinfo
)


-- ---------------------------------------------------------------------------
-- Gilden
-- ---------------------------------------------------------------------------

-- hilfsfunktion
local function addGroupedTrigger(group, pattern, f, triggerFactory)
  group[#group+1] = triggerFactory(
    pattern,
    function(m)
      f(m)
      disableTrigger(group)
      re_ausgabe()
    end
  )
end

-- Gruppen von Triggern: jeder deaktiviert die ganze Gruppe und ruft re_ausgabe() auf
local function addGroupedSubstrTrigger(group, pattern, f)
  addGroupedTrigger(group, pattern, f, createSubstrTrigger)
end
local function addGroupedRegexTrigger(group, pattern, f)
  addGroupedTrigger(group, pattern, f, createRegexTrigger)
end
local function addGroupedMultiLineRegexTrigger(group, pattern, f)
  addGroupedTrigger(group, pattern, f, createMultiLineRegexTrigger)
end


local schaden_functions = {}
local function schaden(n)
  if schaden_functions[n] == nil then
    schaden_functions[n] =
      function()
        RE_SCHADEN = n
      end
  end
  return schaden_functions[n]
end


-- Blitzmeldungen, die von einigen Gilden gebraucht werden:
local blitz_tmp_triggers = {}

function re_blitzschaden()
  enableTrigger(blitz_tmp_triggers)
end

addGroupedRegexTrigger(
  blitz_tmp_triggers,
  '^  ([A-Z].+) Blitz laesst (.+) (etwas|hell|kurz) (aufleuchten|glimmen|auflodern)\\.',
  function(m)
    RE_OPFER = m[2]
    if m[4] == 'auflodern' then
      RE_SCHADEN = 9
    elseif m[3] == 'etwas' or m[3] == 'kurz' then
      RE_SCHADEN = 5
    elseif m[3] == 'hell' then
      RE_SCHADEN = 6
    end
  end
)
addGroupedRegexTrigger(
  blitz_tmp_triggers,
  '^  [A-Z].+ (laesst|verschmort|verbrennt|braet|zerreisst|zerfetzt|atomisiert|vernichtet) (.+) (die Haare zu Berge stehen|Haut|Haut russig schwarz|durch|vollstaendig)\\.$',
  function(m)
    RE_OPFER = m[2]
    local p1 = m[1]
    if p1 == 'vernichtet' then
      RE_SCHADEN = 13
    elseif p1 == 'atomisiert' then
      RE_SCHADEN = 12
    elseif p1 == 'zerfetzt' then
      RE_SCHADEN = 11
    elseif p1 == 'zerreisst' and m[3] == 'vollstaendig' then
      RE_SCHADEN = 10
    elseif p1 == 'braet' then
      RE_SCHADEN = 8
    elseif p1 == 'verschmort' then
      RE_OPFER = re_genitiv_loeschen(RE_OPFER)
      RE_SCHADEN = 7
    elseif p1 == 'verbrennt' then
      RE_OPFER = re_genitiv_loeschen(RE_OPFER)
      RE_SCHADEN = 7
    elseif p1 == 'laesst' then
      RE_SCHADEN = 1
    end
  end
)
addGroupedRegexTrigger(
  blitz_tmp_triggers,
  '^  ([A-Z].+) zucks?t (leicht |)unter .* Blitz zusammen\\.$',
  function(m)
    if m[2] == 'leicht ' then
      RE_SCHADEN = 2
    else
      RE_SCHADEN = 3
    end
    RE_OPFER = m[1]
  end
)
addGroupedRegexTrigger(
  blitz_tmp_triggers,
  '^  [A-Z].+ Blitz schiesst ins Leere\\.$',
  schaden(1)
)
addGroupedRegexTrigger(
  blitz_tmp_triggers,
  '^  [A-Z].+ Blitz zerreisst (.+)\\.$',
  function(m)
    RE_OPFER = m[1]
    RE_SCHADEN = 9
  end
)
disableTrigger(blitz_tmp_triggers)

-- KARATE

local function re_karate_abwehr(m)
  RE_KARATE_ABWEHR = re_karatekuerzen(m[2])
  if m[1] == 'Du' then
    RE_KARATE = 4
  else
    RE_KARATE = 3
  end
end

createRegexTrigger(
  '^  ([^ ].+) wehrs?t .+ Angriff mit einem (.+) ab\\.$',
  re_karate_abwehr
)

local function re_karate_abwehr2(m)
  RE_KARATE_ABWEHR = re_karatekuerzen(m[2])
  if m[1] == 'Du' then
    RE_KARATE = 2
  else
    RE_KARATE = 1
  end
end

createRegexTrigger(
  '^  ([^ ].+) versuchs?t,? .+ Angriff mit einem (.+) abzuwehren\\.$',
  re_karate_abwehr2
)

-- CHAOS

-- Chaosball
local function re_chaos_cb(m)
  if string.match(m[1], 'magischen Pfeil$') then
    RE_ART = 'Magie'
    RE_WAFFE = 'Magie'
  else
    RE_ART = 'Chaos'
    local RE_PHYS = false
    if string.match(m[1], 'Fluch$') then
      RE_WAFFE = 'Boese'
    elseif string.match(m[1], 'Terrorattacke$') then
      RE_WAFFE = 'Terror'
    elseif string.match(m[1], 'Wasserstrahl$') then
      RE_WAFFE = 'Wasser'
    elseif string.match(m[1], 'Flammenkugel$') then
      RE_WAFFE = 'Feuer'
    elseif string.match(m[1], 'Strahl$') then
      RE_WAFFE = 'Magie'
    elseif string.match(m[1], 'Eiswolke$') then
      RE_WAFFE = 'Eis'
    elseif string.match(m[1], 'Kampfschrei$') then
      RE_WAFFE = 'Krach'
    elseif string.match(m[1], 'Saeureregen$') then
      RE_WAFFE = 'Saeure'
    elseif string.match(m[1], 'Sturm$') then
      RE_WAFFE = 'Sturm'
    elseif string.match(m[1], 'Gift$') then
      RE_WAFFE = 'Gift'
    elseif string.match(m[1], 'Blitz$') then
      RE_WAFFE = 'Blitz'
    elseif string.match(m[1], 'Daumenschraube') then
      RE_PHYS = true
      RE_WAFFE = 'Quetschen'
    elseif string.match(m[1], 'Magierschaedel$') then
      RE_PHYS = true
      RE_WAFFE = 'Explosion'
    elseif string.match(m[1], 'Peitschenhieb$') then
      RE_PHYS = true
      RE_WAFFE = 'Peitsche'
    elseif string.match(m[1], 'Felsbrocken$') then
      RE_PHYS = true
      RE_WAFFE = 'Schlag'
    elseif string.match(m[1], 'Pfeil$') then
      RE_PHYS = true
      RE_WAFFE = 'Stich'
    elseif string.match(m[1], 'Messer') then
      RE_PHYS = true
      RE_WAFFE = 'Schnitt'
    elseif string.match(m[1], 'Widerhaken$') then
      RE_PHYS = true
      RE_WAFFE = 'Reissen'
    else
      re_loeschen()
    end
    if (RE_PHYS) then
      local mag = nil;
      if string.match(m[1], 'brennend') then
        mag = 'Feuer'
      elseif string.match(m[1], 'eisig') then
        mag = 'Eis'
      elseif string.match(m[1], 'schreiend') then
        mag = 'Krach'
      elseif string.match(m[1], 'fluessig') then
        mag = 'Wasser'
      elseif string.match(m[1], 'satanisch') then
        mag = 'Boese'
      elseif string.match(m[1], 'giftig') then
        mag = 'Gift'
      elseif string.match(m[1], 'stuermisch') then
        mag = 'Sturm'
      elseif string.match(m[1], 'aetzend') then
        mag = 'Saeure'
      elseif string.match(m[1], 'grauenvollen') then
        mag = 'Terror'
      elseif string.match(m[1], 'magisch') then
        mag = 'Magie'
      elseif string.match(m[1], 'blitzend') then
        mag = 'Blitz'
      end
      if mag ~= nil then
        RE_WAFFE = mag .. '+' .. RE_WAFFE
      end
    end
  end
end
createMultiLineRegexTrigger(
  '^[^ ].+ feuers?t (.+) auf>< .+ ab\\.$',
  re_chaos_cb
)

-- Chaoswolke
createMultiLineRegexTrigger(
  '^Eine Chaoswolke loest sich aus (.+) (Haut|Chaoshaut) und schiesst>< (.+) zu\\.$',
  function(m)
    if m[1] == 'Deiner' then
      RE_ANGREIFER = 'Du'
    else
      RE_ANGREIFER = m[1]
    end
    RE_WAFFE = 'Chaoswolke'
    RE_ART = 'Chaos'
  end
)

-- Verbanne
createRegexTrigger(
  ' (hebt|hebst) die Arme empor und (wirft|wirfst) uebelste Worte gegen .*\\.',
  function()
    RE_WAFFE = 'Verbannen'
    RE_ART = 'Chaos'
  end
)

createRegexTrigger(
  '(Tutszt|Harkuhu|Graiop|Yrintri|Irkitis|Flaxtri|Nurchak) weicht dem Angriff aus\\.',
  function(m)
    RE_KARATE_ABWEHR = m[1]
    RE_KARATE = 2
  end
)

createRegexTrigger(
  '(Tutszt|Harkuhu|Graiop|Yrintri|Irkitis|Flaxtri|Nurchak) wirft sich in den Angriff\\.',
  function(m)
    RE_KARATE_ABWEHR = m[1]
    RE_KARATE = 2
  end
)

createRegexTrigger(
  'fuerchtet sich vor (Deiner Macht|der Macht von .*) und zittert vor Angst!',
  function() abwehr_helfer('RING', 'C') end
)

-- ZAUBERER

-- Giftpfeil
local re_zau_gpfeil_tmp_triggers = {}
addGroupedRegexTrigger(
  re_zau_gpfeil_tmp_triggers,
  '^  .* schiesst einen Giftpfeil auf den Boden\\.',
  schaden(1)
)
addGroupedRegexTrigger(
  re_zau_gpfeil_tmp_triggers,
  '^  .* Giftpfeil (bohrt sich in den Boden|laesst .* gruen anlaufen|laesst .* taumeln)\\.$',
  function(m)
    if string.match(m[1], '^bohrt ') then
      RE_SCHADEN = 1
    elseif string.match(m[1], ' gruen ') then
      RE_SCHADEN = 6
    elseif string.match(m[1], ' taumeln') then
      RE_SCHADEN = 7
    end
  end
)
addGroupedMultiLineRegexTrigger(
  re_zau_gpfeil_tmp_triggers,
  '^.* (kratzt|triffs?t) .* mit einem Giftpfeil><( worauf .*)?\\.$',
  function(m)
    if m[1] == 'kratzt' then
      RE_SCHADEN = 3
    elseif string.match(m[1], '^triff') and m[2] == '' then
      RE_SCHADEN = 4
    elseif string.match(m[1], '^triff') and m[2] ~= '' then
      RE_SCHADEN = 5
    else
      RE_SCHADEN = 15
    end
  end
)
disableTrigger(re_zau_gpfeil_tmp_triggers)
local re_zau_gpfeil_1
re_zau_gpfeil_1 = createRegexTrigger(
  '^  Aus Deiner Hand schiesst ein giftgruener Pfeil auf (.+)\\.',
  function(m)
    RE_OPFER = m[1]
    RE_ANGREIFER = 'Du'
    RE_WAFFE = 'Giftpfeil'
    RE_ART =  'Zauberei'
    disableTrigger(re_zau_gpfeil_1)
    enableTrigger(re_zau_gpfeil_tmp_triggers)
  end
)
disableTrigger(re_zau_gpfeil_1)
createSubstrTrigger(
  '  Du murmelst die vorgeschriebenen Worte fuer den Giftpfeil.',
  function()
    enableTrigger(re_zau_gpfeil_1)
  end
)
local re_zau_gpfeil_2
re_zau_gpfeil_2 = createRegexTrigger(
  '^  Aus (.+) Hand schiesst ein giftgruener Pfeil (in Deine Richtung|auf (.+) zu)\\.',
  function(m)
    RE_ANGREIFER = re_genitiv_loeschen(m[1])
    if m[2] == 'in Deine Richtung' then
      RE_OPFER = 'Dich'
    else
      RE_OPFER = m[3]
    end
    RE_WAFFE = 'Giftpfeil'
    RE_ART =  'Zauberei'
    disableTrigger(re_zau_gpfeil_2)
    enableTrigger(re_zau_gpfeil_tmp_triggers)
  end
)
disableTrigger(re_zau_gpfeil_2)
createSubstrTrigger(
  'murmelt: Khratrx venthrax whu!',
  function()
    enableTrigger(re_zau_gpfeil_2)
  end
)

-- Blitz
local re_zau_blitz
re_zau_blitz = createRegexTrigger(
  '^  Aus (.+) Hand loesen sich (ploetzlich|mehrere) grelle Blitze\\.$',
  function(m)
    RE_ANGREIFER = re_genitiv_loeschen(m[1])
    RE_WAFFE = 'Blitz'
    RE_ART =  'Zauberei'
    disableTrigger(re_zau_blitz)
    re_blitzschaden()
  end
)
disableTrigger(re_zau_blitz)
createSubstrTrigger(
  'murmelt: Illuhxio fulhraxtrj whu!',
  function()
    enableTrigger(re_zau_blitz)
  end
)
createSubstrTrigger(
  '  Du murmelst die vorgeschriebenen Worte fuer den Blitz.',
  function(m)
    enableTrigger(re_zau_blitz)
  end
)
createRegexTrigger(
  '^  Aus (.+) Hand loesen sich grelle Blitze und schiessen auf Dich zu\\.$',
  function(m)
    RE_ANGREIFER = re_genitiv_loeschen(m[1])
    RE_WAFFE = 'Blitz'
    RE_ART =  'Zauberei'
    re_blitzschaden()
  end
)

-- Feuerball
local RE_FBALL = ''
local zaub_feuerball_triggers = {}
zaub_feuerball_triggers[#zaub_feuerball_triggers+1] = createMultiLineRegexTrigger(
  '.* (schleuderst|schleudert) die Kugel in>< .* Richtung\\.',
  function() end
)
zaub_feuerball_triggers[#zaub_feuerball_triggers+1] = createMultiLineRegexTrigger(
  '^  ([^ ].+) (wird durch|Feuerball verfehlt|Feuerball bringt|Feuerball versengt|Feuerball entzuendet|Feuerball trifft|Feuerball kocht|Feuerball roestet|Feuerball verbrennt)>< (.+) (Feuerball reichlich warm|meilenweit|zum Schwitzen|Haare und Augenbrauen|Kleidung|an der Schulter|wie einen Hummer|auf kleiner Flamme|russig schwarz|fast zu Asche)?\\.$',
  function(m)
    RE_WAFFE = 'Feuerball'..RE_FBALL
    RE_ART = 'Zauberei'
    local dmg = nil
    if m[1] == 'Dir' then
      RE_OPFER = 'Dich'
      RE_ANGREIFER = re_genitiv_loeschen(m[3])
      dmg = 'zum Schwitzen'
    else
      RE_ANGREIFER = re_genitiv_loeschen(m[1])
      RE_OPFER = re_artikelkuerzen(m[3])
      if m[3] == 'Feuerball entzuendet' then
        RE_OPFER = re_genitiv_loeschen(m[3])
      end
      dmg = m[4]
    end
    if dmg == 'meilenweit' then
      RE_SCHADEN = 1
    elseif dmg == 'zum Schwitzen' then
      RE_SCHADEN = 5
    elseif dmg == 'Haare und Augenbrauen' then
      RE_SCHADEN = 6
    elseif dmg == 'Kleidung' or dmg == 'an der Schulter' then
      RE_SCHADEN = 7
    elseif dmg == 'wie einen Hummer' then
      RE_SCHADEN = 8
      RE_SCHADEN_SUB = -1
    elseif dmg == 'auf kleiner Flamme' then
      RE_SCHADEN = 8
      RE_SCHADEN_SUB = 1
    elseif dmg == 'russig schwarz' then
      RE_SCHADEN = 9
    elseif dmg == 'fast zu Asche' then
      RE_SCHADEN = 110
    else
      RE_SCHADEN = 15
    end
    re_ausgabe()
  end
)
disableTrigger(zaub_feuerball_triggers)
createRegexTrigger(
  '^([A-Z].*) laesst eine (kleine |gewaltige )?Kugel aus Feuer entstehen\\.$',
  function(m)
    RE_FBALL = ''
    if m[2] == 'kleine ' then
      RE_FBALL = '(-)'
    elseif m[1] == 'gewaltige ' then
      RE_FBALL = '(+)'
    end
    RE_FLAECHE_ANGREIFER = m[1]
    RE_FLAECHE_WAFFE = 'Feuerball'
    RE_FLAECHE_ART = '<magenta>Zauberei'
    RE_FLAECHE_ZEIT = os.time()
    enableTrigger(zaub_feuerball_triggers, FLAECHE_DELAY)
  end
)

-- Verletze Feuer
local re_zau_ver_fe_triggers = {}
re_zau_ver_fe_triggers[#re_zau_ver_fe_triggers+1] = createMultiLineRegexTrigger(
  '^  [^ ].+ (Flammen|Feuer)strahl ><(produziert nur heisse Luft|bringt .+ zum Schwitzen|trifft .+|macht .+ die Hoelle heiss|braet .+ gut durch\\. Steak medium|aeschert .+ einfach ein)[!.]$',
  function(m)
    if m[2] == 'produziert nur heisse Luft' then
      RE_SCHADEN = 1
    elseif string.match(m[2], '^bringt .* zum Schwitzen$') then
      RE_SCHADEN = 5
    elseif string.match(m[2], '^trifft .* und bringt .* Haut zum Kokeln$') then
      RE_SCHADEN = 8
    elseif string.match(m[2], '^trifft .* Es riecht') then
      RE_SCHADEN = 7
    elseif string.match(m[2], '^trifft ') then
      RE_SCHADEN = 6
    elseif string.match(m[2], '^macht .* die Hoelle heiss$') then
      RE_SCHADEN = 9
    elseif string.match(m[2], '^braet .* gut durch') then
      RE_SCHADEN = 10
    elseif string.match(m[2], '^aeschert .* einfach ein$') then
      RE_SCHADEN = 111
    else
      RE_SCHADEN = 15
    end
    disableTrigger(re_zau_ver_fe_triggers)
    re_ausgabe()
  end
)
disableTrigger(re_zau_ver_fe_triggers)
createMultiLineRegexTrigger(
  '^([A-Z].*) richtes?t einen gewaltigen Flammenstrahl auf>< (.+)\\.$',
  function(m)
    enableTriggers_sd(re_zau_ver_fe_triggers)
    RE_WAFFE = 'Feuer'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
  end,
  PRIO_AKT
)

-- Verletze Eis
local re_zau_ver_ei_triggers = {}
addGroupedRegexTrigger(
  re_zau_ver_ei_triggers,
  'zaubers?t eine Schneeflocke( herbei)?\\.$',
  schaden(1)
)
addGroupedMultiLineRegexTrigger(
  re_zau_ver_ei_triggers,
  '^  [^ ].+ Schneesturm schmettert Eiskristalle auf>< .*\\.$',
  schaden(9)
)
addGroupedMultiLineRegexTrigger(
  re_zau_ver_ei_triggers,
  '^  [^ ].+ (blaest|triffs?t|wirbels?t|kleiner Schneesturm friert|Schneesturm laesst fast|Schneesturm schockgefriert)>< .+ (Schneeflocke( herbei)?|kalten Wind ins Gesicht|mit einem kleinen Schneesturm|mit einem kleinen Schneesturm durcheinander|fast die Nase ab|Haende abfrieren|zu Staub)\\.$',
  function(m)
    if m[2] == 'kalten Wind ins Gesicht' then
      RE_SCHADEN = 5
    elseif m[2] == 'mit einem kleinen Schneesturm' then
      RE_SCHADEN = 6
    elseif m[2] == 'mit einem kleinen Schneesturm durcheinander' then
      RE_SCHADEN = 7
    elseif m[2] == 'fast die Nase ab' then
      RE_SCHADEN = 8
    elseif m[2] == 'Haende abfrieren' then
      RE_SCHADEN = 10
    elseif m[1] == 'Schneesturm schockgefriert' then
      RE_SCHADEN = 111
    else
      RE_SCHADEN = 15
    end
  end
)
disableTrigger(re_zau_ver_ei_triggers)
createRegexTrigger(
  '^([A-Z].*) huells?t (.+) in einen Schneesturm ein\\.$',
  function(m)
    RE_WAFFE = 'Eis'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    enableTriggers_sd(re_zau_ver_ei_triggers)
  end,
  PRIO_AKT
)

-- Verletze Magie
local re_zau_ver_ma_triggers = {}
addGroupedMultiLineRegexTrigger(
  re_zau_ver_ma_triggers,
  '^  [^ ].+ magischen? Funken treffen>< .+\\.$',
  schaden(6)
)
addGroupedMultiLineRegexTrigger(
  re_zau_ver_ma_triggers,
  '^  [^ ].+ (produziers?t (nur )?|magischen? Funken umschwirren|magischen? Funken lassen|magischen? Funken rauben|magischen? Funken lassen|magischen? Funken bringen|magischen? Funken bringen)>< .+ (Funken|erschaudern|den Atem|altern|die Kaelte des Todes|um den Verstand)\\.$',
  function(m)
    if string.match(m[1], '^produziers') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^magischen? Funken umschwirren$') then
      RE_SCHADEN = 5
    elseif string.match(m[1], '^magischen? Funken lassen$') then
      RE_SCHADEN = 7
    elseif string.match(m[1], '^magischen? Funken rauben$') then
      RE_SCHADEN = 8
    elseif string.match(m[1], '^magischen? Funken lassen$') then
      RE_SCHADEN = 9
    elseif m[2] == 'die Kaelte des Todes' then
      RE_SCHADEN = 10
    elseif m[2] == 'um den Verstand' then
      RE_SCHADEN = 111
    else
      RE_SCHADEN = 15
    end
  end
)
disableTrigger(re_zau_ver_ma_triggers)
createRegexTrigger(
  '^([A-Z].*) huells?t (.+) in einen Wirbel aus Funken\\.$',
  function(m)
    RE_WAFFE = 'Magie'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    enableTriggers_sd(re_zau_ver_ma_triggers)
  end,
  PRIO_AKT
)

-- Verletze Wasser
local re_zau_ver_wa_triggers = {}
re_zau_ver_wa_triggers[#re_zau_ver_wa_triggers+1] = createMultiLineRegexTrigger(
  '^  [^ ].+ (zaubers?t einen|spritzt|triffs?t|brings?t|spuels?t|laesst) ><.+ (Regen|klitschnass|mit einem Wasserstrahl(in.*)?|mit einem  Wasserstrahl aus dem Gleichgewicht|mit einem heftigen Wasserstrahl fast weg|in einer Sintflut untergehen)\\.$',
  function(m)
    if m[2] == 'Regen' then
      RE_SCHADEN = 1
    elseif m[2] == 'klitschnass' then
      RE_SCHADEN = 5
    elseif m[2] == 'mit einem Wasserstrahl' then
      RE_SCHADEN = 6
    elseif m[2] == 'mit einem Wasserstrahl aus dem Gleichgewicht' then
      RE_SCHADEN = 7
    elseif m[2] == 'mit einem Wasserstrahl in den Bauch' then
      RE_SCHADEN = 8
    elseif m[2] == 'mit einem Wasserstrahl ins Auge' then
      RE_SCHADEN = 9
    elseif m[2] == 'mit einem heftigen Wasserstrahl fast weg' then
      RE_SCHADEN = 10
    elseif m[2] == 'in einer Sintflut untergehen' then
      RE_SCHADEN = 111
    else
      RE_SCHADEN = 15
    end
    disableTrigger(re_zau_ver_wa_triggers)
    re_ausgabe()
  end
  )
disableTrigger(re_zau_ver_wa_triggers)
createMultiLineRegexTrigger(
  '^([A-Z].*) richtes?t einen gewaltigen Wasserstrahl auf ><(.+)\\.$',
  function(m)
    RE_WAFFE = 'Wasser'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    enableTriggers_sd(re_zau_ver_wa_triggers)
  end,
  PRIO_AKT
)

-- Verletze Wind
local re_zau_ver_lu_triggers = {}
addGroupedMultiLineRegexTrigger(
  re_zau_ver_lu_triggers,
  '^  [^ ].+ Windhose zerfetzt ><.+\\.$',
  schaden(10)
)
addGroupedMultiLineRegexTrigger(
  re_zau_ver_lu_triggers,
  '^  [^ ].+ (zaubers?t|Windhose zerzaust|triffs?t|wirbels?t|kleine Windhose schmettert|kleine Windhose hebt|Orkan zerfetzt) ><.+ (Windhoeschen|die Haare|mit einer kleinen Windhose|mit einer kleinen Windhose durcheinander|zu Boden|zwei Meter in die Luft|in kleine Stuecke)\\.$',
  function(m)
    if m[2] == 'Windhoeschen' then
      RE_SCHADEN = 1
    elseif m[2] == 'die Haare' then
      RE_SCHADEN = 5
    elseif m[2] == 'mit einer kleinen Windhose' then
      RE_SCHADEN = 6
    elseif m[2] == 'mit einer kleinen Windhose durcheinander' then
      RE_SCHADEN = 7
    elseif m[2] == 'zu Boden' then
      RE_SCHADEN = 8
    elseif m[2] == 'zwei Meter in die Luft' then
      RE_SCHADEN = 9
    elseif m[1] == 'Orkan zerfetzt' then
      RE_SCHADEN = 111
    else
      RE_SCHADEN = 15
    end
  end
)
disableTrigger(re_zau_ver_lu_triggers)
createMultiLineRegexTrigger(
  '^([A-Z].*) laesst eine Windhose um ><(.*) entstehen\\.$',
  function(m)
    RE_WAFFE = 'Wind'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    enableTriggers_sd(re_zau_ver_lu_triggers)
  end,
  PRIO_AKT
)

-- Verletze Saeure
local re_zau_ver_sa_triggers = {}
re_zau_ver_sa_triggers[#re_zau_ver_sa_triggers+1] = createMultiLineRegexTrigger(
  '^  (Der (dichte )?Saeurenebel|Ploetzlich|Auf)>< (zerfaellt sofort|reizt .+ Haut|greift .+ Haut an|bilden sich Blasen auf Deiner Haut|.+ Haut bilden sich Blasen|laesst .+ Fleisch aufquellen|frisst tiefe Wunden in .+ Fleisch|loest .+ das Fleisch von den Knochen|loest .+ Fleisch einfach auf)\\.$',
  function(m)
    if {m[3]} == 'zerfaellt sofort' then
      RE_SCHADEN = 1
    elseif string.match(m[3], '^reizt .* Haut$') then
      RE_SCHADEN = 5
    elseif string.match(m[3], '^greift .* Haut an$') then
      RE_SCHADEN = 6
    elseif string.match(m[3], '^.*bilden sich Blasen.*$') then
      RE_SCHADEN = 7
    elseif string.match(m[3], '^.* Fleisch aufquellen$') then
      RE_SCHADEN = 8
    elseif string.match(m[3], '^.* tiefe Wunden in .* Fleisch$') then
      RE_SCHADEN = 9
    elseif string.match(m[3], '^.* von den Knochen$') then
      RE_SCHADEN = 10
    elseif string.match(m[3], '^loest .* Fleisch einfach auf$') then
      RE_SCHADEN = 111
    else
      RE_SCHADEN = 15
    end
    disableTrigger(re_zau_ver_sa_triggers)
    re_ausgabe()
  end
)
disableTrigger(re_zau_ver_sa_triggers)
createRegexTrigger(
  '^([A-Z].*) huells?t (.*) in einen Saeurenebel ein\\.$',
  function(m)
    RE_WAFFE = 'Saeure'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    enableTriggers_sd(re_zau_ver_sa_triggers)
  end,
  PRIO_AKT
)

-- Verletze Laerm
local re_zau_ver_kr_triggers = {}
local function verletze_krach(m)
  local l = m[1]
  if m[2] ~= nil then
    l = m[1] .. ' ' .. m[2] .. ' ' .. m[3]
  end
  if string.match(l, ' nur leise$') then
    RE_SCHADEN = 1
  elseif string.match(l, ' den Ohren weh$') or string.match(l, ' kaum zu stoeren$') then
    RE_SCHADEN = 5
  elseif string.match(l, ' in Deinem Kopf$') or string.match(l, ' merklich zusammen') then
    RE_SCHADEN = 6
  elseif string.match(l, ' in Deinen Ohren$') or string.match(l, ' Gesicht vor Schmerzen$') then
    RE_SCHADEN = 7
  elseif string.match(l, ' fast ertauben$') or string.match(l, ' die Ohren zu$') then
    RE_SCHADEN = 8
  elseif string.match(l, ' Kopf explodieren$') or string.match (l, ' den Kopf fest$') then
    RE_SCHADEN = 9
  elseif string.match(l, ' einfach um$') then
    RE_SCHADEN = 10
  elseif string.match(l, '^Schrei zwingt .* in die Knie$') then
    RE_SCHADEN = 111
  else
    RE_SCHADEN = 15
  end
end
addGroupedMultiLineRegexTrigger(
  re_zau_ver_kr_triggers,
  '^  [^ ].+ (kraechzt nur leise|Schrei tut Dir in den Ohren weh|Schrei droehnt in Deinem Kopf|zuckt merklich zusammen|Schrei hinterlaesst ein ekliges Pfeifen in Deinen Ohren|verzieht das Gesicht vor Schmerzen|Schrei laesst Dich fast ertauben|haelt sich krampfhaft die Ohren zu|Schrei laesst fast Deinen Kopf explodieren|haelt sich krampfhaft den Kopf fest)\\.$',
  verletze_krach
)
addGroupedMultiLineRegexTrigger(
  re_zau_ver_kr_triggers,
  '^  [^ ].+ (Schrei scheint|Schrei fegt|Schrei zwingt) (.+) (kaum zu stoeren|einfach um|in die Knie)\\.$',
  verletze_krach
)
disableTrigger(re_zau_ver_kr_triggers)
createRegexTrigger(
  '^([A-Z].*) bruells?t (.+) mit ungeheurer Lautstaerke an\\.$',
  function(m)
    RE_WAFFE = 'Krach'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    enableTriggers_sd(re_zau_ver_kr_triggers)
  end,
  PRIO_AKT
)

-- Verletze Gift
local re_zau_ver_gi_triggers = {}
re_zau_ver_gi_triggers[#re_zau_ver_gi_triggers+1] = createMultiLineRegexTrigger(
  '^  [^ ].+ (laesst eine Kugel eklig gruenen Schleim|kannst den vergifteten Schleim|Schleimkugel streift|(triffs?t|bedecks?t|huells?t|ertraenks?t)) ><.+ (zu Boden fallen|nicht kontrollieren|(in|mit) einer Kugel( aus)? eklig gruene[mn] Schleim)(.*)\\.$',
  function(m)
    if m[1] == 'laesst eine Kugel eklig gruenen Schleim' or
        m[1] == 'kannst den vergifteten Schleim' then
      RE_SCHADEN = 1
    elseif string.match(m[1], ' streift ') then
      RE_SCHADEN = 5
    elseif string.match(m[6], ' am Arm$') then
      RE_SCHADEN = 7
    elseif string.match(m[6], ' ins Gesicht$') then
      RE_SCHADEN = 8
    elseif string.match(m[1], '^bedeck') then
      RE_SCHADEN = 9
    elseif string.match(m[1], '^triff') then
      RE_SCHADEN = 6
    elseif string.match(m[1], '^huell') then
      RE_SCHADEN = 10
    elseif string.match(m[1], '^ertraenk') then
      RE_SCHADEN = 111
    else
      RE_SCHADEN = 15
    end
    disableTrigger(re_zau_ver_gi_triggers)
    re_ausgabe()
  end
)
disableTrigger(re_zau_ver_gi_triggers)
createMultiLineRegexTrigger(
  '^([A-Z].*) bewirfs?t (.*) mit einer Kugel aus eklig>< gruenem Schleim.$',
  function(m)
    RE_WAFFE = 'Gift'
    RE_ART = 'Zauberei'
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    enableTriggers_sd(re_zau_ver_gi_triggers)
  end,
  PRIO_AKT
)

-- KAEMPFER

local function extra_waffe(waffe)
  RE_WAFFE = waffe
  RE_ART = 'extra'
end

-- Kniestoss
createRegexTrigger(
  ' (rammst|rammt) .* das Knie in den Koerper\\.',
  function() extra_waffe('Kniestoss') end
)

-- Kopfstoss
createRegexTrigger(
  '^[^ ].+ stoesst .+ ((seinen|ihren) Kopf in den Leib|heftig mit (dem|Deinem) Kopf)\\.$',
  function() extra_waffe('Kopfstoss') end
)

-- Kampftritt
createRegexTrigger(
  '^[^ ].+ (versetzt .+ einen heimtueckischen Kampftritt|tritt .+ heimtueckisch)\\.$',
  function() extra_waffe('Kampftritt') end
)

-- Ellbogenschlag
createRegexTrigger(
  ' (schlaegst|schlaegt) .* mit (Deinem|dem|seinen|ihren) Ellbogen\\.$',
  function() extra_waffe('Ellbogenschlag') end
)

-- Waffenschlag
createMultiLineRegexTrigger(
  '^[^ ].+ schlaegs?t .+ (fies mit|ploetzlich und)>< .*\\.',
  function(m)
    extra_waffe('Waffenschlag')
  end
)

-- Todesstoss
createMultiLineRegexTrigger(
  '^[^ ].+ setzt einen ([a-z]+ |)Todesstoss ><gegen (.*)',
  function(m)
    local qualitaet = m[1]
    if qualitaet == '' then
      RE_ART = 'lasch'
      RE_ART_COLOR = '<green>'
    elseif qualitaet == 'harmlosen ' then
      RE_ART = 'harmlos'
      RE_ART_COLOR = '<green>'
    elseif qualitaet == 'maechtigen ' then
      RE_ART = 'maechtig'
      RE_ART_COLOR = '<red>'
    elseif qualitaet == 'moerderischen ' then
      RE_ART = 'toedlich'
      RE_ART_COLOR = '<red>'
    else
      RE_ART = '???'
      RE_ART_COLOR = '<green>'
    end
    RE_WAFFE = 'Todesstoss'
  end
)

-- Rueckendeckung
createRegexTrigger(
  ' faengs?t den (Angriff|Schlag von .+)( gegen .+|, der eigentlich .+ treffen sollte,) etwas ab\\.$',
  function() abwehr_helfer('RDECKUNG', 'R') end
)

-- Parade
local function re_parade(m)
  local color
  if m[1] == 'Du' then
    color = '<magenta>'
  else
    color = '<yellow>'
  end
  if string.match(m[2], 'Kieferknochen$') or string.match(m[2], '[Ss]child') or
    string.match(m[2], '[Ss]chuppe') or string.match(m[2], 'Harpyienfedern$')
  then
    abwehr_helfer('PARADE', 'S', color)
  else
    abwehr_helfer('PARADE', 'P', color)
  end
end
createRegexTrigger(
  '^([^ ].+) pariers?t .+ Angriff mit (.+)\\.$',
  re_parade
)

-- Magieausweichen
local function re_magieausweichen()
  RE_KARATE_ABWEHR = 'Ausweichen'
  RE_KARATE = 3
end
createMultiLineRegexTrigger(
  '^[^ ].+ machs?t einen S(prung nach hinten und weichs?t|alto rueckwaerts und entgehs?t) so><.*\\.',
  re_magieausweichen
)
createMultiLineRegexTrigger(
  '^[^ ].+ ducks?t [Ds]ich ganz geschwind und tauchs?t so unter><.*\\.',
  re_magieausweichen
)
createRegexTrigger(
  '^[^ ].+ umtaenzels?t den Angriff (vollstaendig|teilweise)\\.$',
  re_magieausweichen
)

-- KLERIKER

-- Messerkreis
createSubstrTrigger(
  ' wird ein wenig tranchiert.',
  function() trenner_helfer('=', '<bgmagenta>') end
)

-- Blitz
local kleriker_blitz_trigger2
kleriker_blitz_trigger2 = createRegexTrigger(
  '^  ((Der Blitz verfehlt|Du fuehlst|Es knistert auf|Kleine Funken springen auf|Auf der Haut|Der Blitz brennt sich in|Der Blitz schlaegt hart in|Der Blitz wirkt sich verheerend auf|Der Blitz hat verheerende Auswirkungen auf die Gesundheit) (.+) ((wenn auch nur )?knapp|Haut( umher)?|springen kleine Funken umher|ein|Gesundheit aus)|([^ ].*) (wird etwas statisch aufgeladen|knistert etwas|zucks?t elektrisiert zusammen))\\.$',
  function(m)
    disableTrigger(kleriker_blitz_trigger2)
    local RE_KSCHADEN_1 = m[2]
    local RE_KSCHADEN_2 = m[4]
    RE_OPFER = m[3]
    if m[2] == '' then
      RE_KSCHADEN_1 = 'Nix'
      RE_KSCHADEN_2 = m[8]
      RE_OPFER = m[7]
    end
    if string.find(RE_KSCHADEN_2, 'knapp') then
      RE_SCHADEN = 1
    elseif string.find(RE_KSCHADEN_2, 'statisch aufgeladen') then
      RE_SCHADEN = 2
    elseif string.find(RE_KSCHADEN_1, 'knistert auf') or RE_KSCHADEN_2 == 'knistert etwas' then
      RE_SCHADEN = 3
    elseif string.find(RE_KSCHADEN_2, 'elektrisiert zusammen') then
      RE_SCHADEN = 4
    elseif RE_KSCHADEN_2 == 'Haut umher' then
      RE_SCHADEN = 5
    elseif string.find(RE_KSCHADEN_2, 'kleine Funken umher') then
      RE_OPFER = re_genitiv_loeschen(RE_OPFER)
      RE_SCHADEN = 5
    elseif string.find(RE_KSCHADEN_1, 'brennt sich in') then
      RE_SCHADEN = 6
    elseif string.find(RE_KSCHADEN_1, 'schlaegt hart in') then
      RE_SCHADEN = 7
    elseif string.find(RE_KSCHADEN_1, 'wirkt sich verheerend') then
      RE_SCHADEN = 109
    elseif string.find(RE_KSCHADEN_1, 'hat verheerende Auswirkungen') then
      RE_OPFER = re_genitiv_loeschen(RE_OPFER)
      RE_SCHADEN = 109
    else
      logger.warn('Fehler bei Kleriker-Blitz-Schaden, teil1: '..RE_KSCHADEN_1)
      RE_SCHADEN = 15
    end
    re_ausgabe()
  end
)
createMultiLineRegexTrigger(
  '^([^ ].+) (hebt|erhebst) (eine Hand|die Haende) gen Himmel und beschwoers?t>< .*herab\\.',
  function(m)
    RE_WAFFE = 'Blitz'
    RE_ART = 'Klerus'
    RE_ANGREIFER = m[1]
    enableTrigger(kleriker_blitz_trigger2)
  end
)

-- Donner
createRegexTrigger(
  '^(Der Koerper (.*) verkrampft sich vor Konzentration|(Du) konzentrierst Deine Gedanken auf einen Donner)\\.$',
  function(m)
    RE_FLAECHE_WAFFE = 'Donner'
    RE_WAFFE =  'Donner'
    RE_FLAECHE_ART = '<magenta>Klerus<reset>'
    RE_ART = RE_FLAECHE_ART
    if m[3] == '' then
      RE_FLAECHE_ANGREIFER = re_genitiv_loeschen(re_artikelkuerzen(m[2]))
    else
      RE_FLAECHE_ANGREIFER = 'Du'
    end
    RE_FLAECHE_ZEIT = os.time()
  end
)
createRegexTrigger(
  '^([^ ].*) (furzt tierisch|laesst tierisch einen Stinkefurz fahren)\\.$',
  function()
    if RE_FLAECHE_WAFFE == 'Donner' then
      RE_FLAECHE_ANGREIFER = nil
    end
  end
)
createSubstrTrigger(
  'Ein gewaltiger Donner erschuettert Dein Trommelfell.',
  function()
    if RE_FLAECHE_WAFFE == 'Donner' then
      RE_FLAECHE_ANGREIFER = nil
    end
  end
)

-- Erloese
local erloese_tmp_triggers = {}
addGroupedSubstrTrigger(
  erloese_tmp_triggers,
  '  Die Erloesung geht voll daneben.',
  schaden(1)
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '  Ein kurzes Gluehen erscheint zwischen .* Haenden, verlischt aber sofort wieder',
  schaden(1)
)


addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '  ([^ ].+) (fuehlst ein kurzes Kribbeln|schuettelt sich kurz|spuers?t den Hauch der Erloesung|bemerkst ein leichtes Ziehen|zuckt elektrisiert zusammen)\\.$',
  function(m)
    if m[2] == 'fuehlst ein kurzes Kribbeln' then
      RE_SCHADEN = 1
    elseif m[2] == 'schuettelt sich kurz' then
      RE_SCHADEN = 1
    elseif string.match(m[2], ' den Hauch der Erloesung$') then
      RE_SCHADEN = 2
    elseif m[2] == 'bemerkst ein leichtes Ziehen' then
      RE_SCHADEN = 4
    elseif m[2] == 'zuckt elektrisiert zusammen' then
      RE_SCHADEN = 4
    end
  end
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '^  Ein (helles )?Licht tanzt vor Deinen Augen umher\\.$',
  function(m)
    if m[1] == 'helles ' then
      RE_SCHADEN = 6
    else
      RE_SCHADEN = 5
    end
  end
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '^  Vor .+ Augen tanzt ein (helles )?Licht umher\\.$',
  function(m)
    if m[1] == 'helles ' then
      RE_SCHADEN = 6
    else
      RE_SCHADEN = 5
    end
  end
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '^  Ein gleissendes Licht umgibt .+ Kopf\\.$',
  function(m)
    RE_SCHADEN = 8
    RE_SCHADEN_SUB = -1
  end
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '  Grelle Lichtblitze zucken um .* Koerper\\.',
  schaden(9)
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '^  [^ ].+ komms?t der Erloesung immer naeher\\.$',
  schaden(10)
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '^  [^ ].+ Kopf beginnt zu gluehen\\.$',
  schaden(11)
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '^  [^ ].+ gesamter Koerper glueht grell auf\\.$',
  schaden(12)
)
addGroupedRegexTrigger(
  erloese_tmp_triggers,
  '^  [^ ].+ wird von dem Licht zerfetzt\\.$',
  schaden(13)
)
disableTrigger(erloese_tmp_triggers)
createRegexTrigger(
  '^([A-Z].*) sprichs?t ein kurzes Gebet der Erloesung (fuer|auf) (.+)\\.$',
  function(m)
    RE_ANGREIFER = m[1]
    RE_OPFER = m[3]
    RE_WAFFE = 'Erloese'
    RE_ART = 'Klerus'
    enableTrigger(erloese_tmp_triggers)
  end
)

-- TANJIAN
local RE_TAN_TMP

-- Kaminari
createSubstrTrigger(
  'Du konzentrierst Dich auf die Energien Deiner Umgebung.',
  function()
    RE_ANGREIFER = 'Du'
    RE_WAFFE = 'Kaminari'
    RE_ART = 'Tanjian'
    re_blitzschaden()
  end
)
createRegexTrigger(
  '^(.*) lenks?t die sich entladenden Energien auf (.+)\\.$',
  function(m)
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    RE_WAFFE = 'Kaminari'
    RE_ART = 'Tanjian'
    re_blitzschaden()
  end
)
local kaminari_tmp_triggers = {}
kaminari_tmp_triggers[#kaminari_tmp_triggers+1] = createRegexTrigger(
  '^Kleine Blitze zucken um .* herum durch die Luft\\.',
  function()
    disableTrigger(kaminari_tmp_triggers)
  end
)
kaminari_tmp_triggers[#kaminari_tmp_triggers+1] = createRegexTrigger(
  '^Die Blitze rasen auf (.+) zu\\.$',
  function(m)
    RE_OPFER = m[1]
    disableTrigger(kaminari_tmp_triggers)
    re_blitzschaden()
  end
)
disableTrigger(kaminari_tmp_triggers)
createRegexTrigger(
  '^([A-Z].*) konzentriert sich und (seine|ihre) Augen beginnen leicht zu gluehen\\.$',
  function(m)
    disableTrigger(kaminari_tmp_triggers)
    RE_ANGREIFER = m[1]
    RE_WAFFE = 'Kaminari'
    RE_ART = 'Tanjian'
    enableTrigger(kaminari_tmp_triggers)
  end
)

-- Arashi
local arashi_tmp_triggers = {}
addGroupedSubstrTrigger(
  arashi_tmp_triggers,
  '  Ein leichter Wind kommt auf.',
  schaden(1)
)

local RE_ARASHI_1 = regex('(trifft|kratzt|streift) (.+)(sehr )?(hart)?\\.')
addGroupedRegexTrigger(
  arashi_tmp_triggers,
  '^  Ein Windhauch (streift .+|kratzt .+|trifft .+)\\.$',
  function(m)
    if string.match(m[1], '^streift ') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^kratzt ') then
      RE_SCHADEN = 2
    elseif string.match(m[1], '^trifft .* sehr hart$') then
      RE_SCHADEN = 6
    elseif string.match(m[1], '^trifft .* hart$') then
      RE_SCHADEN = 5
    elseif string.match(m[1], '^trifft ') then
      RE_SCHADEN = 3
    end
    if RE_OPFER == '???' or RE_OPFER == '' then
      local m_opfer = RE_ARASHI_1:match(m[1])
      if m_opfer ~= nil then
        RE_OPFER = m_opfer[1]
      end
    end
  end
)
local RE_ARASHI_2 = regex('(.*) kraeftig$')
addGroupedMultiLineRegexTrigger(
  arashi_tmp_triggers,
  '^  Ein Windstoss schuettelt ><(.+) durch\\.$',
  function(m)
    if string.match(m[1], '.* kraeftig$') then
      RE_SCHADEN = 8
    else
      RE_SCHADEN = 7
    end
    if RE_OPFER == '???' or RE_OPFER == '' then
      local m_opfer = RE_ARASHI_2:match(m[1])
      if m_opfer ~= nil then
        RE_OPFER = m_opfer[1]
      end
    end
    if RE_OPFER == '???' or RE_OPFER == '' then
      RE_OPFER = m[1]
    end
  end
)
addGroupedMultiLineRegexTrigger(
  arashi_tmp_triggers,
  '^  Eine Windboee? haut ><(.+) um\\.$',
  function(m)
    RE_OPFER = m[1]
    RE_SCHADEN = 9
  end
)
addGroupedMultiLineRegexTrigger(
  arashi_tmp_triggers,
  '^  Ein Wirbelwind wirbelt ><(.+) herum\\.$',
  function(m)
    RE_OPFER = m[1]
    RE_SCHADEN = 10
  end
)
local RE_ARASHI_3 = regex('schleudert (.+) zu')
local RE_ARASHI_4 = regex('(.*)^(zerfetzt|vernichtet) ')
addGroupedRegexTrigger(
  arashi_tmp_triggers,
  '^  [^ ].+ Sturm (schleudert .+ zu Boden|zerfetzt .+|vernichtet .+)\\.$',
  function(m)
    if string.match(m[1], '^schleudert ') then
      RE_SCHADEN = 11
    elseif string.match(m[1], '^zerfetzt ') then
      RE_SCHADEN = 12
    elseif string.match(m[1], '^vernichtet ') then
      RE_SCHADEN = 13
    end
    if RE_OPFER == '???' or RE_OPFER == '' then
      local m_opfer = RE_ARASHI_3:match(m[1])
      if m_opfer ~= nil then
        RE_OPFER = m_opfer[1]
      else
        m_opfer = RE_ARASHI_4:match(m[1])
        if m_opfer ~= nil then
          RE_OPFER = m_opfer[1]
        end
      end
    end
  end
)
disableTrigger(arashi_tmp_triggers)
local arashi_tmp_wind_trigger
arashi_tmp_wind_trigger = createSubstrTrigger(
  'Ein starker Wind kommt auf.',
  function(m)
    RE_WAFFE = 'Arashi'
    RE_ART = 'Tanjian'
    disableTrigger(arashi_tmp_wind_trigger)
  end
)
disableTrigger(arashi_tmp_wind_trigger)
local arashi_ziel_tmp_triggers = {}
arashi_ziel_tmp_triggers[#arashi_ziel_tmp_triggers+1] = createMultiLineRegexTrigger(
  '^Bewegung kommt in die Luft und (.+) lenks?t sie auf>< (.+)\\.$',
  function(m)
    RE_OPFER = m[2]
    RE_ANGREIFER = m[1]
    RE_WAFFE = 'Arashi'
    RE_ART = 'Tanjian'
    disableTrigger(arashi_ziel_tmp_triggers)
    enableTrigger(arashi_tmp_triggers)
  end
)
arashi_ziel_tmp_triggers[#arashi_ziel_tmp_triggers+1] = createMultiLineRegexTrigger(
  'Ploetzlich scheint sich der Wind auf>< (.+) zu konzentrieren\\.$',
  function(m)
    RE_OPFER = m[1]
    RE_WAFFE = 'Arashi'
    RE_ART = 'Tanjian'
    disableTrigger(arashi_ziel_tmp_triggers)
    enableTrigger(arashi_tmp_triggers)
  end
)
disableTrigger(arashi_ziel_tmp_triggers)
createSubstrTrigger(
  'Du konzentrierst Dich auf die Dich umgebende Luft.',
  function()
    RE_ANGREIFER = 'Du'
    RE_WAFFE = 'Arashi'
    RE_ART = 'Tanjian'
    enableTrigger(arashi_tmp_wind_trigger)
    enableTrigger(arashi_ziel_tmp_triggers)
  end
)
createRegexTrigger(
  '^([A-Z].*) legt den Kopf in den Nacken und konzentriert sich\\.$',
  function(m)
    RE_ANGREIFER = m[1]
    RE_WAFFE = 'Arashi'
    RE_ART = 'Tanjian'
    enableTrigger(arashi_tmp_wind_trigger)
    enableTrigger(arashi_ziel_tmp_triggers)
  end
)

-- Samusa
local samusa_tmp_triggers = {}
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '^  [^ ].+ froestels?t\\.$',
  schaden(1)
)
addGroupedSubstrTrigger(
  samusa_tmp_triggers,
  '  Ein kalter Hauch streift ',
  schaden(1)
)
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '  Die Kaelte (brennt|kitzelt) auf .* Haut\\.',
  function(m)
    if m[3] == 'brennt' then
      RE_SCHADEN = 3
    elseif m[3] == 'kitzelt' then
      RE_SCHADEN = 2
    end
  end
)
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '^  [^ ].+ Haut bekommt einen (leichten |)Blaustich\\.$',
  function(m)
    if m[2] == '' then
      RE_SCHADEN = 3
    elseif m[2] == 'leichten ' then
      RE_SCHADEN = 2
    end
  end
)
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '^  Eine eisige Boee? wirbelt (.+) herum\\.$',
  function(m)
    if string.match(m[1], ' maechtig$') then
      RE_SCHADEN = 7
    elseif string.match(m[1], ' etwas $') then
      RE_SCHADEN = 5
    else
      RE_SCHADEN = 6
    end
  end
)
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '  (Kalter|Eiskalter) Regen prasselt auf .* herab\\.',
  function(m)
    if m[1] == 'Kalter' then
      RE_SCHADEN = 8
    elseif m[1] == 'Eiskalter' then
      RE_SCHADEN = 9
    end
  end
)
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '^  [^ ].+ schreis?t vor Kaelte\\.$',
  schaden(10)
)
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '  Ein Eishagel (zerschmettert|zermatscht) .*\\.',
  function(m)
    if m[1] == 'zerschmettert' then
      RE_SCHADEN = 11
    elseif m[1] == 'zermatscht' then
      RE_SCHADEN = 12
    end
  end
)
addGroupedRegexTrigger(
  samusa_tmp_triggers,
  '  Toedliche Kaelte umfaengt .*\\.',
  schaden(13)
)
disableTrigger(samusa_tmp_triggers)
createSubstrTrigger(
  'Du konzentrierst Dich auf die Kaelte des Universums.',
  function()
    disableTrigger(samusa_tmp_triggers)
    RE_ANGREIFER = 'Du'
    RE_WAFFE = 'Samusa'
    RE_ART = 'Tanjian'
    enableTrigger(samusa_tmp_triggers)
  end
)
createRegexTrigger(
  '^([A-Z].*) lenks?t die Kaelte auf (.+)\\.$',
  function(m)
    RE_ANGREIFER = m[1]
    RE_OPFER = m[2]
    RE_WAFFE = 'Samusa'
    RE_ART = 'Tanjian'
    enableTrigger(samusa_tmp_triggers)
  end
)
createRegexTrigger(
  '^([A-Z].*) konzentriert sich mit halb geschlossenen Augen\\.$',
  function(m)
    RE_TAN_ZEIT = os.time()
    RE_TAN_TMP = m[1]
  end
)
local samusa_kristalle_trigger
samusa_kristalle_trigger = createRegexTrigger(
  'Auf (.+) Haut bilden sich ploetzlich (kleine |)Eiskristalle[.!]$',
  function(m)
    disableTrigger(samusa_kristalle_trigger)
    RE_OPFER = re_genitiv_loeschen(m[1])
    RE_WAFFE = 'Samusa'
    RE_ART = 'Tanjian'
    if RE_TAN_TMP ~= '' then
      RE_ANGREIFER = RE_TAN_TMP
    else
      RE_ANGREIFER = '???'
    end
    RE_TAN_TMP = nil
    enableTrigger(samusa_tmp_triggers)
  end
)
createSubstrTrigger(
  'Es wird ploetzlich kaelter.',
  function()
    enableTrigger(samusa_kristalle_trigger)
  end
)

-- Kshira
local function re_tan_kout()
  RE_WAFFE = 'Kshira'
  RE_ART = 'Tanjian'
  if RE_TAN_TMP ~= '' then
    RE_ANGREIFER = RE_TAN_TMP
  else
    RE_ANGREIFER = '???'
  end
  RE_TAN_TMP = nil
  re_ausgabe()
end
local kshira_tmp_triggers = {}
kshira_tmp_triggers[#kshira_tmp_triggers+1] = createRegexTrigger(
  '^  Die Angst (kann|schmettert|nagt an) (.+) (nichts anhaben|zu Boden|Eingeweiden)\\.$',
  function(m)
    RE_OPFER = m[2]
    if m[3] == 'nichts anhaben' then
      RE_SCHADEN = 1
    elseif m[3] == 'zu Boden' then
      RE_SCHADEN = 7
    elseif m[3] == 'Eingeweiden' then
      RE_OPFER = re_genitiv_loeschen(RE_OPFER)
      RE_SCHADEN = 8
    else
      RE_SCHADEN = 15
    end
    re_tan_kout()
  end
)
kshira_tmp_triggers[#kshira_tmp_triggers+1] = createRegexTrigger(
  '^  ([^ ].+) (zitters?t( etwas)?|schlotters?t mit den Knien|quellen vor Angst die Augen aus dem Kopf|stirbs?t vor Angst)\\.$',
  function(m)
    RE_OPFER = m[1]
    if string.match(m[2], '^zitter') then
      RE_SCHADEN = 2
    elseif string.match(m[2], ' mit den Knien$') then
      RE_SCHADEN = 3
    elseif string.match(m[2], '^quellen vor Angst die Augen ') then
      RE_SCHADEN = 12
    elseif string.match(m[2], ' vor Angst$') then
      RE_SCHADEN = 13
    else
      RE_SCHADEN = 15
    end
    re_tan_kout()
  end
)
kshira_tmp_triggers[#kshira_tmp_triggers+1] = createRegexTrigger(
  '  Der Terror zermuerbt (.*)\\.',
  function(m)
    RE_OPFER = m[1]
    RE_SCHADEN = 6
    re_tan_kout()
  end
)
kshira_tmp_triggers[#kshira_tmp_triggers+1] = createRegexTrigger(
  '^  Der Terror (trifft|zerreisst) (.+) (hart|Gehirn)\\.$',
  function(m)
    RE_OPFER = m[2]
    if m[3] == 'hart' then
      RE_SCHADEN = 5
    elseif m[3] == 'Gehirn' then
      RE_OPFER = re_genitiv_loeschen(RE_OPFER)
      RE_SCHADEN = 10
    else
      RE_SCHADEN = 15
    end
    re_tan_kout()
  end
)
kshira_tmp_triggers[#kshira_tmp_triggers+1] = createRegexTrigger(
  '^  Angst und Terror (martern|zerfetzen) (.+) Koerper\\.$',
  function(m)
    RE_OPFER = re_genitiv_loeschen(m[2])
    if m[1] == 'martern' then
      RE_SCHADEN = 9
    elseif m[1] == 'zerfetzen' then
      RE_SCHADEN = 11
    end
    re_tan_kout()
  end
)
disableTrigger(kshira_tmp_triggers)
createRegexTrigger(
  '^([A-Z].*) lenks?t Angst und Terror auf .+ Gegner\\.$',
  function(m)
    RE_TAN_TMP = m[1]
    RE_TAN_ZEIT = os.time()
    enableTrigger(kshira_tmp_triggers)
  end
)
local tanjian_kshira_tmp_3_1
tanjian_kshira_tmp_3_1 = createSubstrTrigger(
  'Angst und Terror greifen um sich.',
  function()
    disableTrigger(tanjian_kshira_tmp_3_1)
    enableTrigger(kshira_tmp_triggers)
  end
)
disableTrigger(tanjian_kshira_tmp_3_1)
createSubstrTrigger(
  'Du spuerst ploetzlich eine furchteinfloessende Macht um Dich herum.',
  function()
    RE_TAN_ZEIT = os.time()
    enableTrigger(tanjian_kshira_tmp_3_1)
  end
)
local tanjian_kshira_tmp_4
tanjian_kshira_tmp_4 = createSubstrTrigger(
  'Du betrittst den Weg der Dunkelheit.',
  function()
    disableTrigger(tanjian_kshira_tmp_4)
  end
)
disableTrigger(tanjian_kshira_tmp_4)
createSubstrTrigger(
  'Du konzentrierst Dich auf die allgegenwaertige Macht der Furcht.',
  function(m)
    RE_TAN_TMP = 'Du'
    RE_TAN_ZEIT = os.time()
    enableTrigger(tanjian_kshira_tmp_4)
  end
)
createRegexTrigger(
  '^([A-Z].*) konzentriert sich\\.$',
  function(m)
    RE_TAN_TMP = m[1]
    RE_TAN_ZEIT = os.time()
  end
)

-- Kami (alle Schadensarten)
local RE_TAN_ANGREIFER
local RE_TAN_OPFER
createRegexTrigger(
  '^([A-Z].*) richtes?t (.+) auf (.+)[!\\.]$',
  function(m)
    RE_TAN_ANGREIFER = m[1]
    RE_TAN_OPFER = m[3]
  end,
  PRIO_AKT-1,   -- Prio < als verletze feuer
  {'F'}
)
local function setzeKamiOpferAngreifer()
  RE_ANGREIFER = '???'
  RE_OPFER = '???'
  if RE_TAN_ANGREIFER ~= nil then
    RE_ANGREIFER = RE_TAN_ANGREIFER
  end
  if RE_TAN_OPFER ~= nil then
    RE_OPFER = RE_TAN_OPFER
  end
  RE_TAN_OPFER = nil
  RE_TAN_ANGREIFER = nil
end

-- Kami Feuer
local kami_fe_triggers = {}
addGroupedRegexTrigger(
  kami_fe_triggers,
  '  Ein warmer Lufthauch streift .*\\.',
  schaden(1)
)
addGroupedRegexTrigger(
  kami_fe_triggers,
  '^  Ein Flammenstrahl (streift .+|trifft .+)\\.$',
  function(m)
    if string.match(m[1], '^streift .* leicht$') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^streift ') then
      RE_SCHADEN = 2
    elseif string.match(m[1], '^trifft .* sehr hart$') then
      RE_SCHADEN = 6
    elseif string.match(m[1], '^trifft .* hart$') then
      RE_SCHADEN = 5
    elseif string.match(m[1], '^trifft ') then
      RE_SCHADEN = 4
    end
end
)
addGroupedMultiLineRegexTrigger(
  kami_fe_triggers,
  '^  Ein (grosser|maechtiger|gigantischer) Flammenstrahl (roestet|kocht|aeschert|atomisiert) ><(.+)\\.$',
  function(m)
    if string.match(m[2]..m[3], '^roestet .* durch$') then
      RE_SCHADEN = 8
    elseif m[2] == 'roestet' then
      RE_SCHADEN = 7
    elseif string.match(m[2]..m[3], '^kocht .* gar$') then
      RE_SCHADEN = 10
    elseif m[2] == 'kocht' then
      RE_SCHADEN = 9
    elseif m[2] == 'aeschert' then
      RE_SCHADEN = 11
    elseif m[2] == 'atomisiert' then
      RE_SCHADEN = 12
    end
  end
)
addGroupedRegexTrigger(
  kami_fe_triggers,
  '^  [^ ].+ verpuffs?t in einem Flammenstrahl\\.$',
  schaden(13)
)
disableTrigger(kami_fe_triggers)
createSubstrTrigger(
  'ist ploetzlich von einer Flammenlohe umgeben.',
  function(m)
    setzeKamiOpferAngreifer()
    RE_WAFFE = 'Kami.Feuer'
    RE_ART = 'Tanjian'
    enableTrigger(kami_fe_triggers)
  end,
  PRIO_AKT
)

-- Kami Saeure
local kami_sa_triggers = {}
addGroupedRegexTrigger(
  kami_sa_triggers,
  '^  Ein Saeurestrahl (schiesst an .+ vorbei|streift .+|trifft .+|aetzt .+ an|veraetzt .+)\\.$',
  function(m)
    if string.match(m[1], '^schiesst ') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^streift .* leicht$') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^streift ') then
      RE_SCHADEN = 2
    elseif string.match(m[1], '^trifft .* sehr hart$') then
      RE_SCHADEN = 6
    elseif string.match(m[1], '^trifft .* hart$') then
      RE_SCHADEN = 5
    elseif string.match(m[1], '^trifft ') then
      RE_SCHADEN = 4
    elseif string.match(m[1], '^aetzt .* an$') then
      RE_SCHADEN = 7
    elseif string.match(m[1], '^veraetzt .* etwas$') then
      RE_SCHADEN = 8
    elseif string.match(m[1], '^veraetzt .* Gesicht$') then
      RE_SCHADEN = 9
    elseif string.match(m[1], '^veraetzt .* total$') then
      RE_SCHADEN = 10
    else
      RE_SCHADEN = 15
    end
  end
)
addGroupedRegexTrigger(
  kami_sa_triggers,
  '  Eine Saeureflut loesst (.*) auf\\.',
  function(m)
    if string.match(m[1], ' voellig') then
      RE_SCHADEN = 12
    else
      RE_SCHADEN = 11
    end
  end
)
addGroupedRegexTrigger(
  kami_sa_triggers,
  '^  [^ ].+ vergeht in einer Saeureflut\\.$',
  schaden(13)
)
disableTrigger(kami_sa_triggers)
createSubstrTrigger(
  'Gruenlicher Schleim benetzt ploetzlich ',
  function()
    setzeKamiOpferAngreifer()
    RE_WAFFE = 'Kami.Saeure'
    RE_ART = 'Tanjian'
    enableTrigger(kami_sa_triggers)
  end,
  PRIO_AKT
)

-- Kami Gift
local kami_gi_triggers = {}
addGroupedSubstrTrigger(
  kami_gi_triggers,
  '  Nichts passiert.',
  schaden(1)
)
addGroupedRegexTrigger(
  kami_gi_triggers,
  '^  Ein gruener Lichtstrahl (streift .+|trifft .+)\\.$',
  function(m)
    if string.match(m[1], '^streift .* leicht$') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^streift ') then
      RE_SCHADEN = 2
    elseif string.match(m[1], '^trifft .* sehr hart$') then
      RE_SCHADEN = 6
    elseif string.match(m[1], '^trifft .* hart$') then
      RE_SCHADEN = 5
    elseif string.match(m[1], '^trifft ') then
      RE_SCHADEN = 4
    else
      RE_SCHADEN = 15
    end
  end
)
addGroupedRegexTrigger(
  kami_gi_triggers,
  '^  Ein giftgruener Blitz trifft (.+)\\.$',
  function(m)
    if string.match(m[1], ' sehr hart$') then
      RE_SCHADEN = 9
    elseif string.match(m[1], ' hart$') then
      RE_SCHADEN = 8
    else
      RE_SCHADEN = 7
    end
  end
)
addGroupedRegexTrigger(
  kami_gi_triggers,
  '  Eine giftgruene Wolke huellt .* ein\\.',
  schaden(10)
)
addGroupedRegexTrigger(
  kami_gi_triggers,
  '  Ein Giftpfeilhagel geht auf .* nieder\\.',
  schaden(11)
)
addGroupedRegexTrigger(
  kami_gi_triggers,
  '^  Ein giftgruene(s Wallen schmettert .+ zu Boden|r Keil spaltet .+)\\.$',
  function(m)
    if string.match(m[1], ' Keil spaltet ') then
      RE_SCHADEN = 13
    elseif string.match(m[1], ' Wallen schmettert ') then
      RE_SCHADEN = 12
    else
      RE_SCHADEN = 15
    end
  end
)
disableTrigger(kami_gi_triggers)
createSubstrTrigger(
  'Ein gruenlicher Schimmer umgibt ploetzlich ',
  function(m)
    setzeKamiOpferAngreifer()
    RE_WAFFE = 'Kami.Gift'
    RE_ART = 'Tanjian'
    enableTrigger(kami_gi_triggers)
  end
)

-- Kami Wasser
local kami_wa_triggers = {}
addGroupedRegexTrigger(
  kami_wa_triggers,
  '^  Ein Wassertropfen (faellt zu Boden|streift .+|trifft .+)\\.$',
  function(m)
    if m[1] == 'faellt zu Boden' then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^streift ') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^trifft ') then
      RE_SCHADEN = 2
    else
      RE_SCHADEN = 15
    end
  end
)
addGroupedRegexTrigger(
  kami_wa_triggers,
  '^  Ein Wasserstrahl (trifft .+|bricht .+ die Knochen|spuelt .+ hinfort)\\.$',
  function(m)
    if string.match(m[1], '^trifft .* sehr hart$') then
      RE_SCHADEN = 6
    elseif string.match(m[1], '^trifft .* hart$') then
      RE_SCHADEN = 5
    elseif string.match(m[1], '^trifft ') then
      RE_SCHADEN = 4
    elseif string.match(m[1], '^bricht .* die Knochen$') then
      RE_SCHADEN = 10
    elseif string.match(m[1], '^spuelt .* hinfort$') then
      RE_SCHADEN = 11
    else
      RE_SCHADEN = 15
    end
  end
)
addGroupedRegexTrigger(
  kami_wa_triggers,
  '^  Eine Wasserfontaene trifft (.+)\\.$',
  function(m)
    if string.match(m[1], ' sehr hart$') then
      RE_SCHADEN = 9
    elseif string.match(m[1], ' hart$') then
      RE_SCHADEN = 8
    else
      RE_SCHADEN = 7
    end
  end
)
addGroupedRegexTrigger(
  kami_wa_triggers,
  '  Ein Wasserfall (zerschmettert|vernichtet) .*\\.',
  function(m)
    if m[1] == 'zerschmettert' then
      RE_SCHADEN = 12
    elseif m[1] == 'vernichtet' then
      RE_SCHADEN = 13
    else
      RE_SCHADEN = 15
    end
  end
)
disableTrigger(kami_wa_triggers)
createRegexTrigger(
  'Auf .* bilden sich ploetzlich einige Wassertropfen\\.',
  function(m)
    setzeKamiOpferAngreifer()
    RE_WAFFE = 'Kami.Wasser'
    RE_ART = 'Tanjian'
    enableTrigger(kami_wa_triggers)
  end
)

-- Kami Magie
kami_ma_triggers = {}
addGroupedRegexTrigger(
  kami_ma_triggers,
  '^  (Nichts passiert|Du spuerst ein merkwuerdiges Kribbeln|Irgendetwas scheint .+ zu kitzeln)\\.$',
  schaden(1)
)
addGroupedSubstrTrigger(
  kami_ma_triggers,
  '  Kleine Funken kitzeln ',
  schaden(2)
)
addGroupedRegexTrigger(
  kami_ma_triggers,
  '^  Ein (h|gr)elles Leuchten flackert um .+ herum auf\\.$',
  function(m)
    if m[1] == 'h' then
      RE_SCHADEN = 4
    elseif m[1] == 'gr' then
      RE_SCHADEN = 5
    end
  end
)
addGroupedRegexTrigger(
  kami_ma_triggers,
  '^  Ein Funken(strahl|regen) (trifft .+|huellt .+)\\.$',
  function(m)
    if string.match(m[2], '^trifft .* sehr hart$') then
      RE_SCHADEN = 8
    elseif string.match(m[2], '^trifft .* hart$') then
      RE_SCHADEN = 7
    elseif string.match(m[2], '^trifft ') then
      RE_SCHADEN = 6
    elseif string.match(m[2], '^huellt .* vollstaendig ein$') then
      RE_SCHADEN = 10
    elseif string.match(m[2], '^huellt .* ein$') then
      RE_SCHADEN = 9
    else
      RE_SCHADEN = 15
    end
  end
)
addGroupedRegexTrigger(
  kami_ma_triggers,
  '^  Etwas (zerreisst|scheint) .+ innerlich( zu zerreissen)?\\.$',
  schaden(11)
)
addGroupedRegexTrigger(
  kami_ma_triggers,
  '^  [^ ].+ wir(st|d) (atomisiert|vernichtet)\\.$',
  function(m)
    if m[2] == 'atomisiert' then
      RE_SCHADEN = 12
    elseif m[2] == 'vernichtet' then
      RE_SCHADEN = 13
    else
      RE_SCHADEN = 15
    end
  end
)
disableTrigger(kami_ma_triggers)
createRegexTrigger(
  '^[^ ].+ leuchtet ploetzlich in oktarinem Licht\\.$',
  function(m)
    setzeKamiOpferAngreifer()
    RE_WAFFE = 'Kami.Magie'
    RE_ART = 'Tanjian'
    enableTrigger(kami_ma_triggers)
  end
)

-- Kami Krach
local kami_kr_triggers = {}
addGroupedSubstrTrigger(
  kami_kr_triggers,
  '  Ein leises Pfeifen ertoent.',
  schaden(1)
)
addGroupedSubstrTrigger(
  kami_kr_triggers,
  '  Ein schriller Pfeifton bereitet ',
  schaden(1)
)
addGroupedSubstrTrigger(
  kami_kr_triggers,
  '  Ein schmerzhaftes Fiepen laesst ',
  schaden(2)
)
addGroupedRegexTrigger(
  kami_kr_triggers,
  '^  Ein (lautes|unglaubliches) Kreischen (trifft .+|zerfetzt .+|vernichtet .+)\\.$',
  function(m)
    if string.match(m[2], '^trifft .* sehr hart$') then
      RE_SCHADEN = 6
    elseif string.match(m[2], '^trifft .* hart$') then
      RE_SCHADEN = 5
    elseif string.match(m[2], '^trifft ') then
      RE_SCHADEN = 4
    elseif string.match(m[2], '^zerfetzt ') then
      RE_SCHADEN = 12
    elseif string.match(m[1], '^vernichtet ') then
      RE_SCHADEN = 13
    else
      RE_SCHADEN = 15
    end
  end
)
addGroupedSubstrTrigger(
  kami_kr_triggers,
  '  Eine unsichtbare Macht schuettelt ',
  schaden(7)
)
addGroupedRegexTrigger(
  kami_kr_triggers,
  '^  Dissonante Schallwellen werfen .+ (um|aus der Bahn)\\.$',
  function(m)
    if m[1] == 'um' then
      RE_SCHADEN = 8
    elseif m[1] == 'aus der Bahn' then
      RE_SCHADEN = 9
    end
  end
)
addGroupedRegexTrigger(
  kami_kr_triggers,
  '^  Ein ohrenbetaeubender Laerm laesst .+ (stoehnen|zerplatzen)\\.$',
  function(m)
    if m[1] == 'stoehnen' then
      RE_SCHADEN = 10
    elseif m[1] == 'zerplatzen' then
      RE_SCHADEN = 11
    end
  end
)
disableTrigger(kami_kr_triggers)
createSubstrTrigger(
  ' geht ploetzlich ein seltsames Summen aus.',
  function(m)
    setzeKamiOpferAngreifer()
    RE_WAFFE = 'Kami.Krach'
    RE_ART = 'Tanjian'
    enableTrigger(kami_kr_triggers)
  end
)

-- Kami Terror
local kami_te_triggers = {}
addGroupedRegexTrigger(
  kami_te_triggers,
  '^  Die schwarze Wolke (loest sich wieder auf|streift .+|trifft .+|laesst .+ vor Angst zittern|floesst .+ Angst ein)\\.$',
  function(m)
    if m[1] == 'loest sich wieder auf' then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^streift .* leicht$') then
      RE_SCHADEN = 1
    elseif string.match(m[1], '^streift ') then
      RE_SCHADEN = 2
    elseif string.match(m[1], '^trifft .* sehr hart$') then
      RE_SCHADEN = 6
    elseif string.match(m[1], '^trifft .* hart$') then
      RE_SCHADEN = 5
    elseif string.match(m[1], '^trifft ') then
      RE_SCHADEN = 4
    elseif string.match(m[1], '^laesst .* vor Angst zittern$') then
      RE_SCHADEN = 7
    elseif string.match(m[1], '^floesst .* Angst ein$') then
      RE_SCHADEN = 8
    else
      RE_SCHADEN = 15
    end
  end
)
addGroupedRegexTrigger(
  kami_te_triggers,
  '  Die Angst bereitet .* Schmerzen\\.',
  schaden(9)
)
addGroupedRegexTrigger(
  kami_te_triggers,
  '^  [^ ].+ (schreis?t vor Angst|wir(st|d) innerlich von Furcht zerfressen)\\.$',
  function(m)
    if string.match(m[1],'^schrei.* vor Angst$') then
      RE_SCHADEN = 10
    elseif string.match(m[1], '^wir.* innerlich von Furcht zerfressen$') then
      RE_SCHADEN = 11
    end
  end
)
addGroupedRegexTrigger(
  kami_te_triggers,
  '^  Eine unglaubliche Angst laesst .+ (Herz still stehen|sterben)\\.$',
  function(m)
    if m[1] == 'Herz still stehen' then
      RE_SCHADEN = 12
    elseif m[1] == 'sterben' then
      RE_SCHADEN = 13
    end
  end
)
disableTrigger(kami_te_triggers)
createRegexTrigger(
  '^[^ ].+ wird ploetzlich von einer schwarzen Wolke umgeben\\.$',
  function(m)
    setzeKamiOpferAngreifer()
    RE_WAFFE = 'Kami.Terror'
    RE_ART = 'Tanjian'
    enableTrigger(kami_te_triggers)
  end
)

-- DUNKELELFEN

-- Feuerlanze
local feuerlanze_tmp_triggers = {}
addGroupedRegexTrigger(
  feuerlanze_tmp_triggers,
  '^  Deine Feuerlanze schwaerzt die Haut (.*)\\.',
  function(m)
    RE_WAFFE = 'Feuerlanze'
    RE_ART = 'Delfen'
    RE_ANGREIFER = 'Du'
    RE_OPFER = m[1]
    RE_SCHADEN = 1
  end
)
local re_feuerlanze = '^  Deine Feuerlanze (fuegt|versengt|schlaegt mit voller Wucht in|roestet|verbrennt|laesst|verwandelt|verbannt)>< (.*) ((einige leichte|schwere) Verbrennungen zu|die Haut|ein|bei lebendigem Leibe|einen Raub der Flammen werden|in Russ und Asche|den Flammentod sterben|aus diesem Raum-Zeitkontinuum)\\.$'
local function delfen_feuerlanze(m)
  RE_WAFFE = 'Feuerlanze'
  RE_ART = 'Delfen'
  RE_ANGREIFER = 'Du'
  RE_OPFER = m[2]
  if m[3] == 'einige leichte Verbrennungen zu' then
    RE_SCHADEN = 5
  elseif m[3] == 'die Haut' then
    RE_SCHADEN = 6
  elseif m[3] == 'schwere Verbrennungen zu' then
    RE_SCHADEN = 7
  elseif m[1] == 'schlaegt mit voller Wucht in' then
    RE_SCHADEN = 8
  elseif m[1] == 'roestet' and m[3] == 'bei lebendigem Leibe' then
    RE_SCHADEN = 8
  elseif m[1] == 'verbrennt' and m[3] == 'bei lebendigem Leibe' then
    RE_SCHADEN = 9
  elseif m[3] == 'einen Raub der Flammen werden' then
    RE_SCHADEN = 10
  elseif m[3] == 'in Russ und Asche' then
    RE_SCHADEN = 11
  elseif m[3] == 'den Flammentod sterben' then
    RE_SCHADEN = 12
  elseif m[3] == 'aus diesem Raum-Zeitkontinuum' then
    RE_SCHADEN = 13
  else
    logger.warn('Feuerlanze nicht erkannt: m[1]=' .. m[1] .. ', m[2]='..m[2])
  end
end
addGroupedMultiLineRegexTrigger(
  feuerlanze_tmp_triggers,
  re_feuerlanze,
  delfen_feuerlanze
)
disableTrigger(feuerlanze_tmp_triggers)
createMultiLineRegexTrigger(
  '^Du konzentrierst Dich auf (.*) und ploetzlich>< schiesst.* .*lanze auf (ihn|sie|es)\\.',
  function()
    enableTrigger(feuerlanze_tmp_triggers)
  end
)

-- Aura
createRegexTrigger(
  '.* Aura leuchtet (hellrot|rot|orange|gelb) auf\\.',
  function(m) abwehr_helfer('RUESTUNG', 'A') end
)

-- Entziehe
createRegexTrigger(
  'Du entziehst (.*) einen Teil (seiner|ihrer) Lebensenergie\\.',
  function(m)
    RE_WAFFE = 'Entziehe'
    RE_ART = 'Delfen'
    RE_ANGREIFER = 'Du'
    RE_OPFER = m[1]
  end
)
createMultiLineRegexTrigger(
  '(.*) legt zwei Finger an>< (.*) Schlaefe, worauf (er|sie|es).*fuehlt\\.$',
  function(m)
    RE_WAFFE = 'Entziehe'
    RE_ART = 'Delfen'
    RE_ANGREIFER = m[1]
    RE_OPFER = re_genitiv_loeschen(m[2])
  end
)


-- ---------------------------------------------------------------------------
-- Abwehr-Helferchen
-- ---------------------------------------------------------------------------

-- Schwertmeisterschwert (SMS)
createSubstrTrigger(
  'Es gelingt Dir mit dem Schwert, den Schlag Deines Gegners etwas abzufangen.',
  function() abwehr_helfer('WAFFE', 'S') end
)

-- Speermeister-Speer (SpMS)
createMultiLineRegexTrigger(
  'Du faengst einen Teil des Angriffes durch eine schnelle>< Bewegung mit Deinem Speer ab\\.',
  function() abwehr_helfer('WAFFE', 'S') end
)
createMultiLineRegexTrigger(
  'gelingt es, durch eine schnelle Bewegung mit dem Speer,>< .* des Angriffes abzufangen\\.',
  function() abwehr_helfer('WAFFE', 'S') end
)

-- Skillschild
local skillschild_quals = { kaum = 1, etwas = 3, gut = 4, genial = 6 }
skillschild_quals['ein wenig'] = 2
skillschild_quals['sehr gut'] = 5
createRegexTrigger(
  'Dein Schild faengt .+ Angriff (.+) ab\\.',
  function(m)
    local qualitaet = m[1]
    abwehr_helfer('SCHILD', skillschild_quals[qualitaet], '<green>')
  end
)

-- Kieferknochen
createSubstrTrigger(
  'Der Kieferknochen faengt den Schlag des Gegners ab.',
  function() abwehr_helfer('SCHILD', 'K') end
)

-- Drachenschuppe
createSubstrTrigger(
  'Die Drachenschuppe faengt den Angriff ab.',
  function() abwehr_helfer('SCHILD', 'D') end
)
createRegexTrigger(
  ' Drachenschuppe wandelt .* Feuer in heilende Waerme.*\\.',
  function() abwehr_helfer('SCHILD', 'H', '<magenta>') end
)

-- Anti-Feuerring (AFR)
createSubstrTrigger(
  'Dein Ring zieht die Flammen auf sich und bewahrt Dich so vor Schaden.',
  function() abwehr_helfer('RING', 'A') end
)

-- Anti-Eisring (AER)
createSubstrTrigger(
  'Dein Ring saugt etwas Kaelte auf.',
  function() abwehr_helfer('RING', 'A') end
)

-- Drachenring
createSubstrTrigger(
  'Der Drachenring verwandelt den Angriff in eine Heilung.',
  function() abwehr_helfer('RING', 'D') end
)

-- irgend son Ring halt ;)
createSubstrTrigger(
  'Dein Ring glueht auf einmal rot auf.',
  function() abwehr_helfer('RING', 'R') end
)

-- Oktariner Ring aus Para-Moulokin
createSubstrTrigger(
  'Der Ring entzieht Dir einen Teil Deiner magischen Kraefte.',
  function() abwehr_helfer('RING', 'S') end
)
createSubstrTrigger(
  'Der Ring labt sich an der Magie ein',
  function() abwehr_helfer('RING', 'E') end
)

-- Kreuz
createSubstrTrigger(
  'Das Kreuz faengt an zu leuchten.',
  function() abwehr_helfer('AMULETT', 'K') end
)

-- Grummelbeisseramulett
createSubstrTrigger(
  'Dein Amulett huellt Dich in eine heilige Aura, die den Angriff schwaecht.',
  function() abwehr_helfer('AMULETT', 'A') end
)

-- Gluecksbringer
createSubstrTrigger(
  'Dein Gluecksbringer reflektiert den Angriff.',
  function() abwehr_helfer('AMULETT', 'G') end
)

-- Himmelskreuz
createSubstrTrigger(
  'Dein heiliges Kreuz faengt den Angriff ab.',
  function() abwehr_helfer('AMULETT', 'K') end
)

-- Haar der Nixe
createSubstrTrigger(
  'Das Haar einer Nixe absorbiert einen Teil des Angriffs.',
  function() abwehr_helfer('AMULETT', 'N') end
)

-- Amulett von Ananas
createSubstrTrigger(
  'Das Amulett aus Obsidian pulsiert, es scheint kurz schwarz zu strahlen.',
  function() abwehr_helfer('AMULETT', 'O') end
)

-- Totenschaedel
createSubstrTrigger(
  'Vom Schaedel geht kurzzeitig ein Leuchten aus.',
  function() abwehr_helfer('HELM', 'T') end
)

-- Eishelm
createSubstrTrigger(
  'Dein Helm kuehlt sich kurz ab.',
  function() abwehr_helfer('HELM', 'H') end
)

-- Pudelmuetze von Tilly
createMultiLineRegexTrigger(
  '^[A-Z].+ Pudelmuetze gibt ein wuetendes Bellen von sich,>< .* veraengstigt an\\.',
  function(m)
    abwehr_helfer('HELM', 'P')
  end
)
createMultiLineRegexTrigger(
  'Die Pudelmuetze von .* gibt ein wuetendes Bellen von sich\\.>< .* um\\.',
  function(m)
    abwehr_helfer('HELM', 'P')
  end
)

-- Feuerhelm
createSubstrTrigger(
  'Der Helm schuetzt Dich vor dem Feuer.',
  function() abwehr_helfer('HELM', 'F') end
)
createSubstrTrigger(
  ' Helm wehrt das Feuer ab.',
  function() abwehr_helfer('HELM', 'F') end
)

-- Myrthenkranz
createSubstrTrigger(
  'Der Myrthenkranz lindert Deine Schmerzen. Du fuehlst Dich gleich besser.',
  function() abwehr_helfer('HELM', 'M') end
)

-- Chaosball
createSubstrTrigger(
  'Der Chaosball leuchtet auf und pulsiert in hellem Licht.',
  function() abwehr_helfer('HELM', 'C') end
)

-- Maske von Patryns Riesen
createSubstrTrigger(
  ' Maske glueht kurz in einem giftigen Gruen auf.',
  function() abwehr_helfer('HELM', 'A') end
)

-- gruene Robe
createSubstrTrigger(
  'Deine Robe schuetzt Dich.',
  function() abwehr_helfer('RUESTUNG', 'R') end
)

-- Umhang aus Trollhaeuten
createSubstrTrigger(
  'Der Umhang knistert stark.',
  function() abwehr_helfer('RUESTUNG', 'U') end
)

-- Toga aus der Gladischule
createSubstrTrigger(
  'Die goldenen Faeden der Toga leuchten auf und heilen Dich etwas.',
  function() abwehr_helfer('RUESTUNG', 'T') end
)
createMultiLineRegexTrigger(
  'Die goldenen Faeden der Toga leuchten auf und schicken Deinem Gegner einen>< Blitz entgegen\\.',
  function(m)
    RE_WAFFE = 'Blitz'
    RE_WFUNC = '<red>Toga'
  end
)

-- Eisschamanenpanzer
createSubstrTrigger(
  'Der Eisschamanenpanzer unterstuetzt Deine Abwehrkraefte.',
  function() abwehr_helfer('RUESTUNG', 'E') end
)

-- Panzer der Gier
createSubstrTrigger(
  'Der Panzer naehrt sich an Deiner Energie.',
  function() abwehr_helfer('RUESTUNG', 'G') end
)

-- Robe der Magie
createSubstrTrigger(
  'Die Robe der Magie gibt Dir neue Kraft.',
  function() abwehr_helfer('RUESTUNG', 'M') end
)

-- Steintrollpanzer
createSubstrTrigger(
  ' verstaucht sich bei dem Schlag die Hand.',
  function() trenner_helfer('S', '<green>') end
)

-- Schutzschild der Dunkelelfen
createRegexTrigger(
  ' Schutzschild blitzt einmal kurz (heftig |kraeftig |leicht |)auf\\.$',
  function(m)
    RE_KARATE_ABWEHR = 'DeSch'
    if not m[1] or m[1] == 'leicht' then
      RE_KARATE = 2
    else
      RE_KARATE = 4
    end
  end
)

-- Padreics schwarz schimmernder Ring
createSubstrTrigger(
  'Die schwarz schimmernde Aura die Dich umgibt, leuchtet auf einmal hell.',
  function() abwehr_helfer('RING', 'R') end
)
createSubstrTrigger(
  'Die schwarz schimmernde Aura leuchtet ein letztes mal hell auf und erlischt.',
  function() abwehr_helfer('RING', 'E') end
)

-- Caldras Schlangenguertel
createSubstrTrigger(
  'Du weichst dem Angriff schlangengleich aus.',
  function() abwehr_helfer('RUESTUNG', 'G') end
)


-- ---------------------------------------------------------------------------
-- Artillerie
-- ---------------------------------------------------------------------------

local function artillerie(waffe)
  RE_WAFFE = waffe
  RE_ART = 'Artillerie'
end

-- Steine (Kampfstock)
createRegexTrigger(
  ' (schleuderst|schleudert) einen Stein nach .*\\.',
  function() artillerie('Stein') end
)

-- Wurfsterne
local wurfstern_dmg_trigger = {}
local function wurfstern(m)
  local schaden = m[1]
  local schaden2 = m[2]
  artillerie('Wurfstern')
  if schaden == 'verfehlt' or schaden == 'meilenweit an' then
    RE_SCHADEN = 1
  elseif string.match(schaden, '^zischt ') then
    RE_SCHADEN = 3
  elseif schaden == 'kratzt' then
    RE_SCHADEN = 5
  elseif string.match(schaden, '^triff.*t$') or schaden == 'verpasst' or schaden == 'schneidet' then
    RE_SCHADEN = 6
  elseif schaden2 == 'Bein' then
    RE_SCHADEN = 7
  elseif schaden == 'schlaegt' or schaden == 'enthauptet' then
    RE_SCHADEN = 7
  elseif schaden == 'bleibt in' then
    RE_SCHADEN = 8
  elseif schaden2 == 'die Eingeweide' then
    RE_SCHADEN = 108
  else
    logger.warn('Fehler bei Wurfsternschaden, schaden: '..schaden)
    RE_SCHADEN = 15
  end
  disableTrigger(wurfstern_dmg_trigger)
  re_ausgabe()
end

wurfstern_dmg_trigger[#wurfstern_dmg_trigger+1] = createMultiLineRegexTrigger(
  '^  [^ ].* (triffs?t) ><.* (am Arm)\\.',
  wurfstern
)
wurfstern_dmg_trigger[#wurfstern_dmg_trigger+1] = createMultiLineRegexTrigger(
  '^  [^ ].* Wurfstern ><(verfehlt|meilenweit an|zischt an|zischt knapp an|kratzt|triffs?t|verpasst|schneidet|zerfetzt|schlaegt|bleibt in|enthauptet) .* (meilenweit|vorbei|leicht|am Arm|einen radikalen Kurzhaarschnitt|fast die Hand ab|Bein|fast den Kopf ab|fast|Brust stecken|die Eingeweide)\\.$',
  wurfstern
)
disableTrigger(wurfstern_dmg_trigger)
createMultiLineRegexTrigger(
  '^(.*) nimms?t einen Wurfstern in die Hand und wirfs?t ><ihn nach (.*)\\.$',
  function(m)
    RE_ANGREIFER = re_artikelkuerzen(m[1])
    RE_OPFER = re_artikelkuerzen(m[2])
    enableTrigger(wurfstern_dmg_trigger)
  end
)

-- Robins Pfeile
local robins_pfeile_trigger_id
robins_pfeile_trigger_id = createSubstrTrigger(
  'die Sehne loslaesst, schnellt der Pfeil davon.',
  function()
    disableTrigger(robins_pfeile_trigger_id)
    artillerie('Robins Pfeil')
  end
)
disableTrigger(robins_pfeile_trigger_id)
createRegexTrigger(
  ' legs?t einen Pfeil auf die Sehne .* Bogens und spanns?t ihn\\.',
  function()
    enableTrigger(robins_pfeile_trigger_id)
  end
)

-- Paracelsus' Armbrust
createRegexTrigger(
  ' schiesst mit dem .*bolzen auf ',
  function() artillerie('Armbrust') end
)

-- Bumerang
-- table { nr -> { zeit = ..., raus = ..., rein = ..., werfer = ... } ]
-- repraesentiert alle aktiven bumerangs
-- zeit = wurfzeitpunkt, raus = zeitpunkt rausfliegen, rein = zeitpunkt reinfliegen
local RE_BUMIS = {}
local function re_bumizeiger_aktualisieren()
  local now = os.time()
  for n,bumi in ipairs(RE_BUMIS) do
    if bumi.raus == nil and now - bumi.zeit > 10 then
      RE_BUMIS[n] = nil
    end
  end
  for n,bumi in ipairs(RE_BUMIS) do
    if bumi.rein == nil and bumi.raus ~= nil and now - bumi.raus > 10 then
      RE_BUMIS[n] = nil
    end
  end
  for n,bumi in ipairs(RE_BUMIS) do
    if bumi.rein ~= nil and now - bumi.rein > 10 then
      RE_BUMIS[n] = nil
    end
  end
end
local function re_bumi_aus()
  re_bumizeiger_aktualisieren()
  local now = os.time()
  for n,bumi in ipairs(RE_BUMIS) do
    if now - bumi.zeit >= 2 then
      RE_BUMIS[n] = nil
      return
    end
  end
end
local function neuer_bumi(werfer)
  re_bumizeiger_aktualisieren()
  RE_BUMIS[#RE_BUMIS+1] = {
    werfer = werfer,
    zeit = os.time()
  }
end
createRegexTrigger(
  ' (faengt|faengst) den .*Bumerang (geschickt|ab)\\.',
  re_bumi_aus,
  2,
  {}
)
createRegexTrigger(
  ' faengt den .*Bumerang geschickt\\.',
  nil,
  1
)
createRegexTrigger(
  '^([^ ].*) wirfs?t den .*Bumerang( nach .*)?\\.$',
  function(m)
    neuer_bumi(m[1])
  end,
  2,
  {}
)
createRegexTrigger(
  ' wirft den .*Bumerang*\\.',
  nil,
  4
)
createSubstrTrigger(
  'Zwei Bumerangs stossen in der Luft zusammen und stuerzen ab.',
  function()
    re_bumi_aus()
    re_bumi_aus()
  end,
  1,
  {}
)
createRegexTrigger(
  'Der .*Bumerang bohrt sich in den Boden\\.',
  re_bumi_aus,
  1,
  {}
)
createRegexTrigger(
  'Der .*Bumerang fliegt nach .*\\.',
  function(m)
    re_bumizeiger_aktualisieren()
    for n,bumi in ipairs(RE_BUMIS) do
      if bumi.raus == nil then
        bumi.raus = os.time()
        return
      end
    end
  end,
  1,
  {}
)
createRegexTrigger(
  'Der .*Bumerang fliegt wieder herein\\.',
  function(m)
    re_bumizeiger_aktualisieren()
    for n,bumi in ipairs(RE_BUMIS) do
      if bumi.raus ~= nil and bumi.rein == nil then
        bumi.rein = os.time()
        return
      end
    end
  end,
  1,
  {}
)
local function getErsterBumi()
  for n,bumi in ipairs(RE_BUMIS) do
    return bumi
  end
end
createRegexTrigger(
  '(Der .*Bumerang (fliegt ueber|zischt an|schwirrt knapp an|rasiert|trifft|schlaegt|zerschmettert|zermatscht|pulverisiert|zerstaeubt|atomisiert) (.*) (hinweg|ein Haarbueschel ab|am Kopf|hart am Kopf|sehr hart am Kopf|den Kopf ein|den Kopf in kleine Stueckchen|den Kopf zu Brei|den Kopf|vorbei)|([^ ].*) weichs?t dem .*Bumerang (gerade noch rechtzeitig|geschickt) aus)\\.$',
  function(m)
    artillerie('Bumerang')
    re_waffe_geraten()
    local RE_Schaden_Vor
    local RE_Schaden_Nach
    if m[5] ~= '' then
      RE_OPFER = m[5]
      RE_Schaden_Vor = 'verfehlt'
    else
      RE_OPFER = m[3]
      RE_Schaden_Vor = m[2]
      RE_Schaden_Nach = m[4]
    end
    re_bumizeiger_aktualisieren()
    local bumi = getErsterBumi()
    if bumi ~= nil then
      RE_ANGREIFER = bumi.werfer
    else
      RE_ANGREIFER = '???'
    end
    if string.match(RE_OPFER,' sehr hart') then
      RE_Schaden_Nach = 'sehr hart '..RE_Schaden_Nach
      RE_OPFER = string.gsub(RE_OPFER, ' sehr hart', '')
    end
    if string.match(RE_OPFER,' hart') then
      RE_Schaden_Nach = 'hart '..RE_Schaden_Nach
      RE_OPFER = string.gsub(RE_OPFER, ' hart', '')
    end
    if string.match(RE_OPFER, ' Kopf') then
      RE_Schaden_Nach = 'Kopf'..RE_Schaden_Nach
      RE_OPFER = string.gsub(RE_OPFER, ' Kopf', '')
    end
    if RE_OPFER == 'Du' or RE_OPFER == 'Dir' or RE_OPFER == 'Deinem' or RE_OPFER == 'Dich' then
      RE_OPFER = 'Dich'
    end
    if RE_Schaden_Vor == 'verfehlt' or RE_Schaden_Vor == 'zischt an' then
      RE_SCHADEN = 1
    elseif RE_Schaden_Vor == 'schwirrt knapp an' or RE_Schaden_Vor == 'fliegt ueber' then
      RE_OPFER = re_genitiv_loeschen(RE_OPFER)
      RE_SCHADEN = 1
    elseif RE_Schaden_Vor == 'rasiert' then
      RE_SCHADEN = 3
    elseif RE_Schaden_Nach == 'am Kopf' then
      RE_SCHADEN = 4
    elseif RE_Schaden_Nach == 'hart am Kopf' then
      RE_SCHADEN = 5
    elseif RE_Schaden_Nach == 'sehr hart am Kopf' then
      RE_SCHADEN = 6
    elseif RE_Schaden_Vor == 'schlaegt' then
      RE_SCHADEN = 7
    elseif RE_Schaden_Vor == 'zerschmettert' then
      RE_SCHADEN = 8
    elseif RE_Schaden_Vor == 'zermatscht' then
      RE_SCHADEN = 9
    elseif RE_Schaden_Vor == 'pulverisiert' then
      RE_SCHADEN = 10
    elseif RE_Schaden_Vor == 'zerstaeubt' then
      RE_SCHADEN = 11
    elseif RE_Schaden_Vor == 'atomisiert' then
      RE_SCHADEN = 12
    else
      RE_SCHADEN = 15
    end
    re_ausgabe()
  end
)


-- ---------------------------------------------------------------------------
-- Angriffsmeldungen
-- haben niedrigere Prio als alle anderen Trigger, damit besondere Angriffe- nicht
-- versehentlich als Normalangriff erkannt werden
-- ---------------------------------------------------------------------------
local RE_REGEXP_WAFFE = '^  ([^ ].+) greifs?t [a-z,` ]*([A-Z].*) mit ([-A-Za-z` ]*) an\\.$'
local RE_REGEXP_KARATEKOMBI = regex('([^ ]+) kombinierten ([^ ]+)')

local function match_normalen_angriff(m)
  local RE_ANAME = m[1]
  local opfer = m[2]
  local waffe = m[3]
  re_loeschen()
  RE_WAFFE = waffe
  logger.debug('RE_WAFFE = "' .. RE_WAFFE .. '"')
  if RE_WAFFE == 'brennenden Haenden' or RE_WAFFE == 'flammenden Haenden' then
    RE_WAFFE = 'Feuerhand'
  elseif RE_WAFFE == 'feuchten Haenden' then
    RE_WAFFE = 'Wasserhand'
  elseif RE_WAFFE == 'aetzenden Haenden' or RE_WAFFE == 'saeuretriefenden Haenden' then
    RE_WAFFE = 'Saeurehand'
  elseif RE_WAFFE == 'giftigen Haenden' then
    RE_WAFFE = 'Gifthand'
  elseif RE_WAFFE == 'magischen Haenden' then
    RE_WAFFE = 'Magiehand'
  elseif RE_WAFFE == 'eisigen Haenden' or RE_WAFFE == 'eiskalten Haenden' then
    RE_WAFFE = 'Eishand'
  elseif RE_WAFFE == 'leuchtenden Haenden' then
    RE_WAFFE = 'Akshara'
  elseif string.match(opfer, 'blutruenstig') then
    RE_ART = 'Raserei'
    RE_ART_COLOR = '<yellow>'
  elseif string.match(opfer, ' vorsichtig') then
    RE_ART = 'SchKroete'
    RE_ART_COLOR = '<yellow>'
  elseif string.match(opfer, ' schlangengleich') then
    RE_ART = 'Schlange'
    RE_ART_COLOR = '<yellow>'
  elseif string.match(RE_WAFFE, '^Blitzen aus (Deinen|seinen|ihren) Fingerkuppen$') then
    RE_WAFFE = 'Blitzhand'
  elseif string.match(RE_WAFFE, 'misslungenen ') then
    local RE_WAFFE_P
    if string.match(RE_WAFFE, 'total ') then
      RE_WAFFE_P = '(--)'
    else
      RE_WAFFE_P = '(-)'
    end
    RE_WAFFE = RE_WAFFE:sub(string.find(RE_WAFFE, 'misslungenen ')+13)
    RE_ART = 'Karate'
    RE_ART_COLOR = '<yellow>'
    RE_WAFFE = re_karatekuerzen(RE_WAFFE)
    RE_WAFFE = RE_WAFFE .. string.rep('_', 5-RE_WAFFE:len()) .. RE_WAFFE_P
  elseif string.match(RE_WAFFE, 'gelungenen ') then
    local RE_WAFFE_P
    if string.match(RE_WAFFE, 'sehr ') then
      RE_WAFFE_P = '(++)'
    else
      RE_WAFFE_P = '(+)'
    end
    RE_WAFFE = RE_WAFFE:sub(string.find(RE_WAFFE, 'gelungenen ')+11)
    RE_ART = 'Karate'
    RE_ART_COLOR = '<yellow>'
    RE_WAFFE = re_karatekuerzen(RE_WAFFE)
    RE_WAFFE = RE_WAFFE .. string.rep('_', 5-RE_WAFFE:len()) .. RE_WAFFE_P
  else
    local m_kombi = RE_REGEXP_KARATEKOMBI:match(RE_WAFFE) or {}
    local k1 = m_kombi[1]
    local k2 = m_kombi[2]
    if k1 ~= nil and k2 ~= nil then
      local RE_WAFFE_P = k2
      RE_WAFFE = re_karatekuerzen(k1)
      RE_WAFFE_P = re_karatekuerzen(RE_WAFFE_P)
      RE_WAFFE = RE_WAFFE .. '+' .. RE_WAFFE_P
      RE_ART = 'Karatekomb'
      RE_ART_COLOR = '<yellow>'
    end
  end
  RE_WAFFE = re_artikelkuerzen(RE_WAFFE)
  RE_ANAME = re_artikelkuerzen(RE_ANAME)
  logger.debug('speichere Waffe "' .. RE_WAFFE .. '" fuer Angreifer "' .. RE_ANAME .. '"')
  RE_ANGRIFFSWAFFEN_MERKER[RE_ANAME] = {
    waffe = RE_WAFFE,
    art = RE_ART,
    color = RE_ART_COLOR
  }
end

createRegexTrigger(
  RE_REGEXP_WAFFE,
  match_normalen_angriff,
  PRIO_NORMALANGRIFF
)


-- ---------------------------------------------------------------------------
-- normale Schadenmeldungen
-- ---------------------------------------------------------------------------

-- wichtig: andere trigger auf 'schlaeg' oder 'trifft' muessen hoehere prio haben
local RE_REGEXP_DEFAULT = '^  ([^ ].+) (verfehls?t|kitzels?t|kratzt|triffs?t|schlaegs?t|zerschmetters?t|pulverisiers?t|zerstaeubs?t|atomisiers?t|vernichtes?t) (.+)\\.'

local function suche_name_und_schaden_extra(rest)
  local i = string.find(rest, ' am Bauch')
    or string.find(rest, ' sehr hart')
    or string.find(rest, ' hart')
    or string.find(rest, ' mit dem Krachen brechender Knochen')
    or string.find(rest, ' in kleine Stueckchen')
    or string.find(rest, ' zu Brei')
  if i ~= nil then
    return rest:sub(1, i-1), rest:sub(i+1)
  end
  return rest, ''
end

local function match_normalen_schaden(m)
  RE_ANGREIFER = m[1]
  local name, meldung_nach = suche_name_und_schaden_extra(m[3])
  RE_OPFER = name
  re_macro(m[2], meldung_nach, m.line)
end

createRegexTrigger(
  RE_REGEXP_DEFAULT,
  match_normalen_schaden,
  PRIO_NORMALANGRIFF
)


-- ---------------------------------------------------------------------------
-- Initialisierung
-- ---------------------------------------------------------------------------

re_loeschen()

client.cecho('<magenta>>>> Lade Paket: <yellow>reduce.lua<reset>')

client.createStandardAlias(
  'reduce',
  1,
  function(level) damage_threshold = tonumber(level) end
)

client.createStandardAlias('reduce_rm', 0, remove_reduce)


-- in erster Linie fuer Tests
return {
  karatekuerzen = re_karatekuerzen,
  namekuerzen = re_namekuerzen,
  leerzeichenkuerzen = re_leerzeichenkuerzen,
  genitiv_loeschen = re_genitiv_loeschen,
  substring_ab = substring_ab,
  setOutputListener = function(f) outputListener = f end
}
