-- Trves

local base   = require 'base'
local itemdb = require 'itemdb'
local inv    = require 'inventory'
local timer  = require 'timer'
local kampf  = require 'battle'

local logger = client.createLogger('trves')
local keymap = base.keymap


local function state()
  return base.getPersistentTable('trves')
end


-- ---------------------------------------------------------------------------
-- Spezialwaffen fuer besondere Kaempfer-Techniken

-- liefert nil falls keine solche gesetzt ist
local function getSpezialwaffe(technik)
  local waffe = state()[technik]
  if waffe == nil then
    return '*'
  else
    return waffe
  end
end

-- Konvention ist: '*' bedeutet Default-Waffe
local function setSpezialwaffe(technik, newVal)
  if newVal == '*' then
    state()[technik] = nil
  else
    local name = itemdb.waffenName(newVal) or newVal
    state()[technik] = name
  end
end

-- (auch waffentrick)
local function fintenwaffe()
  return getSpezialwaffe('fintenwaffe')
end
local function waffenschlagwaffe()
  return getSpezialwaffe('waffenschlag')
end
local function waffenwurfwaffe()
  return getSpezialwaffe('waffenwurfwaffe')
end
local function waffenbruchwaffe()
  return getSpezialwaffe('waffenbruchwaffe')
end

local function set_fintenwaffe(waffe)
  return setSpezialwaffe('fintenwaffe', waffe)
end
local function set_waffenschlagwaffe(waffe)
  return setSpezialwaffe('waffenschlag', waffe)
end
local function set_waffenwurfwaffe(waffe)
  return setSpezialwaffe('waffenwurfwaffe', waffe)
end
local function set_waffenbruchwaffe(waffe)
  return setSpezialwaffe('waffenbruchwaffe', waffe)
end


-- ---------------------------------------------------------------------------
-- Kaempfer-Techniken

-- waffe wechseln und cmd ausfuehren, danach auf default-waffe wechseln
-- args: world_cmd, waffe
local function skill_mit_waffe(cmd, waffe)
  inv.wechselWaffe(waffe)
  client.send(cmd..' '..kampf.getGegner())
  inv.zueckeDefaultWaffe()
end

-- waffe wechseln und finte ausfuehren, danach waffe wechseln und fertigkeit,
-- danach auf default-waffe wechseln
-- args: fertigkeit=%{1}, waffe=rest
local function skill_mit_finte(cmd, waffe)
  inv.wechselWaffe(fintenwaffe())
  client.send('finte '..kampf.getGegner())
  skill_mit_waffe(cmd, waffe)
end

-- kaempfer-skills mit spezialwaffen
local function finte()
  skill_mit_waffe('finte', fintenwaffe())
end
local function waffentrick()
  skill_mit_waffe('waffentrick', fintenwaffe())
end
local function waffenschlag()
  skill_mit_waffe('waffenschlag', waffenschlagwaffe())
end
local function waffenbruch()
  skill_mit_waffe('waffenbruch', waffenbruchwaffe())
end
local function waffenwurf()
  skill_mit_waffe('waffenwurf', waffenwurfwaffe())
end

local function waffenschlagMitFinte()
  skill_mit_finte('waffenschlag', waffenschlagwaffe())
end
local function todesstossMitFinte()
  client.send('finte '..kampf.getGegner())
  client.send('todesstoss '..kampf.getGegner())
end

local function beschimpfe(gegner)
  client.send('beschimpfe '..(gegner or base.gegner))
end

local letzte_rueckendeckung

local function rueckendeckung(optName)
  if (optName ~= nil) then
    letzte_rueckendeckung = optName
  elseif (optName == '-') then
    letzte_rueckendeckung = nil
  else
    client.send('rueckendeckung '..(letzte_rueckendeckung or ''))
  end
end

local function waffenschaerfen()
  local waffe = inv.waffe()
  if waffe ~= nil then
    client.send('waffenschaerfen '..waffe)
  end
end

local function createFunctionMitGegner(cmd)
  return
    function()
      client.send(cmd..' '..kampf.getGegner())
    end
end


-- ---------------------------------------------------------------------------
-- Statuszeile / Trigger

base.statusAdd('Tk','   ')  -- Taktik
base.statusAdd('parade','   ',true)
base.statusAdd('T','   ')  -- Technik
base.statusAdd('schnell','  ',true)
base.statusAdd('rueckendeckung','  ',true)


local function statusUpdate(id, optVal)
  return
    function()
      base.statusUpdate(id, optVal)
    end
end

local function setTaktik(val)
  state().taktik = tonumber(val)
  base.statusUpdate('Tk', state().taktik)
end

-- paraden
client.createSubstrTrigger('Du konzentrierst Dich auf die Bewegungen des Parierens, um im kommenden Kampf', statusUpdate('parade','Par'), {'<green>'})
client.createSubstrTrigger('Du parierst die naechsten Angriffe mit ', statusUpdate('parade','Par'), {'<green>'})
client.createSubstrTrigger('Du merkst, dass du die feindlichen Schlaege nicht mehr lange mit Deiner Waffe', nil, {'<yellow>'})
client.createSubstrTrigger('Du beendest Deine Schildparade.', statusUpdate('parade','   '), {'<red>'})
client.createSubstrTrigger('Du beendest Deine Parade.', statusUpdate('parade','   '), {'<red>'})
client.createSubstrTrigger('Du konzentrierst Dich nun nicht mehr auf die Bewegungen der Parade.', statusUpdate('parade','   '), {'<red>'})

-- rueckendeckung
client.createRegexTrigger('Du gibst .* Rueckendeckung.', statusUpdate('rueckendeckung','Rd'), {'<green>'})
client.createSubstrTrigger('Du beendest die Rueckendeckung fuer ', statusUpdate('rueckendeckung','  '), {'<red>'})

-- schnell
client.createSubstrTrigger('Du kaempfst jetzt schneller!', statusUpdate('schnell','Sc'), {'<green>'})

-- schmerzen
client.createSubstrTrigger('Du beisst ob der Schmerzen die Zaehne zusammen.', nil, {'<green>'})
client.createSubstrTrigger('Du schaffst es nicht mehr, die Schmerzen weiterhin zu ignorieren.', nil, {'<red>'})

-- techniken: schildkroete - drache - schlange - raserei
client.createSubstrTrigger('Du kaempfst nun mit der Kampftechnik der Schildkroete.', statusUpdate('T','Skr'), {'<green>'})
client.createSubstrTrigger('Du kaempfst nun mit der Kampftechnik des Drachen.', statusUpdate('T','Dra'), {'<green>'})
client.createSubstrTrigger('Du kaempfst nun die Technik der Schlange und machst dabei schnelle,', statusUpdate('T','Sna'), {'<green>'})
client.createSubstrTrigger('Du beendest die Kampftechnik ', statusUpdate('T','   '), {'<red>'})
client.createSubstrTrigger('Du konzentrierst Dich nun nicht mehr auf die Technik ', statusUpdate('T','   '), {'<red>'})
client.createSubstrTrigger(
  'Du steigerst Dich in wilde Raserei!',
  function()
    setTaktik(0)
    base.statusUpdate('T','Ras')
  end,
  {'<green>'})
client.createSubstrTrigger('Du beendest Deine Raserei', statusUpdate('T','   '), {'<red>'})

-- taktik
local function setTaktikMatch1(m)
  setTaktik(m[1])
end
client.createRegexTrigger('Du kaempfst mit ([0-9]+)% Defensive.', setTaktikMatch1, {'<blue>'})
client.createRegexTrigger('Du aenderst Deine Taktik und kaempfst nun mit ([0-9]+)% Defensive.', setTaktikMatch1, {'<blue>'})
-- initialisierung
client.send('taktik')


-- ---------------------------------------------------------------------------
-- Utils

local function gruesse(c)
  client.send('stehe still', 'gruesse '..c)
end

-- kampfwille
client.createSubstrTrigger(
  'Du bist irgendwie paralysiert und kannst Dich nicht richtig bewegen!',
  function()
    client.send('kampfwille')
  end,
  {'<magenta>'}
)

-- Typische Fehler von Kaempfern (Waffe fallen lassen)
local waffe_aufnehmen = inv.waffenAufnehmen
client.createSubstrTrigger('Wie auch immer Du es geschafft hast, es ist passiert! Du hast Dir eine Hand', waffe_aufnehmen, {'<magenta>','B'})
client.createSubstrTrigger('Oh weia! Du wolltest mal wieder besonders cool sein und eine gewagte Finte', waffe_aufnehmen, {'<magenta>'})
client.createSubstrTrigger('Im Eifer des Gefechts faellt Dir einfach so Deine Waffe aus der Hand. Dumm', waffe_aufnehmen, {'<magenta>'})
client.createSubstrTrigger('Du versuchst schneller zu kaempfen und verlierst im Eifer des', waffe_aufnehmen, {'<magenta>'})
client.createRegexTrigger('Du schwingst .* in hohem Bogen, laesst .* aber leider genau am', waffe_aufnehmen, {'<magenta>'})
client.createSubstrTrigger('Der Waffenwurf ist misslungen. Du laesst ', waffe_aufnehmen, {'<magenta>'})
client.createSubstrTrigger('Argl! Du machst eine weitausholende Bewegung, um die Waffe', waffe_aufnehmen, {'<magenta>'})

client.createSubstrTrigger(
  'Du siehst im Kampf zur Zeit keine Moeglichkeit die Waffe an Dich zu nehmen.',
  function()
    timer.enqueue(2, waffe_aufnehmen)
  end,
  {'<magenta>'})

client.createSubstrTrigger(
  'Du stolperst! Dabei verlierst Du sehr unschicklich Deine ganze Ruestung!',
  function()
    client.send('nimm alles', 'trage alles')
    waffe_aufnehmen()
  end,
  {'<magenta>'})


-- ---------------------------------------------------------------------------
-- reboot / reset

local function reset()
  set_fintenwaffe('*')
  set_waffenschlagwaffe('*')
  set_waffenwurfwaffe('*')
  set_waffenbruchwaffe('*')
end

base.addResetHook(reset)


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

local function info()
  logger.info('Finte/Waf.tr. [#kf] : '..(fintenwaffe() or '*'))
  logger.info('Waffenschlag  [#kws]: '..(waffenschlagwaffe() or '*'))
  logger.info('Waffenbruch   [#kwb]: '..(waffenbruchwaffe() or '*'))
  logger.info('Waffenwurf    [#kww]: '..(waffenwurfwaffe() or '*'))
  client.send('taktik')
end

base.gilde.info = info


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.F5   = createFunctionMitGegner('kampftritt')
keymap.S_F5 = createFunctionMitGegner('unterlaufe')
keymap.F6   = createFunctionMitGegner('kniestoss')
keymap.S_F6 = createFunctionMitGegner('ellbogenschlag')
keymap.F7   = createFunctionMitGegner('kopfstoss')
keymap.S_F7 = todesstossMitFinte
keymap.F8   = waffenschlag
keymap.S_F8 = waffenschlagMitFinte

-- besondere Waffen-/Schildtechniken
keymap.M_f = finte
keymap.M_g = waffentrick
keymap.M_b = 'block'
keymap.M_p = 'ko'
keymap.M_y = waffenbruch

-- besondere Kampftaktiken und Techniken
keymap.M_k =  createFunctionMitGegner('fokus')
keymap.M_x = 'schnell'
keymap.M_d = 'schildkroete'
keymap.M_e = 'schlange'
keymap.M_t = 'drache'
keymap.M_a = 'raserei'

-- Abwehr
keymap.M_m = 'schildparade'
keymap.M_v = 'parade'
keymap.M_r = rueckendeckung

-- Sonstiges
keymap.M_i = 'schmerz'
keymap.M_j = 'kampfwille'
keymap.M_z = waffenschaerfen


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('be',  1, beschimpfe)
client.createStandardAlias('be',  0, beschimpfe)
client.createStandardAlias('gr',  1, gruesse)
client.createStandardAlias('rd',  1, rueckendeckung)
client.createStandardAlias('wb',  0, waffenbruch)

client.createStandardAlias('kf',  1, set_fintenwaffe)
client.createStandardAlias('kws', 1, set_waffenschlagwaffe)
client.createStandardAlias('kww', 1, set_waffenwurfwaffe)
client.createStandardAlias('kwb', 1, set_waffenbruchwaffe)

client.createStandardAlias('s',  0, function() client.send('schaetz') end)
