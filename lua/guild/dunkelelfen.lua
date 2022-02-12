-- Dunkelelfen

local base   = require 'base'
local itemdb = require 'itemdb'
local inv    = require 'inventory'
local ME     = require 'gmcp-data'
local timer  = require 'timer'
local kampf  = require 'battle'

local logger = client.createLogger('delfen')
local keymap = base.keymap


local function state()
  return base.getPersistentTable('dunkelelf')
end

-- Konvention ist: '*' bedeutet Default-Waffe
local function setVerkleidenWaffe(newVal)
  local name = itemdb.waffenName(newVal) or newVal
  state().verkleidenwaffe = name
end

local function verkleidenWaffe()
  return state().verkleidenwaffe
end


-- ---------------------------------------------------------------------------
-- Gilden-Utils

local function createFunctionMitGegner(cmd)
  return
    function()
      client.send(cmd..' '..kampf.getGegner())
    end
end

local function createFunctionMitHands(n, cmd, delay)
  return
    function()
      inv.doWithHands(n, cmd, delay)
    end
end

local function createFunctionMitHandsUndGegner(n, cmd, delay)
  return 
    function()
      inv.doWithHands(n, cmd..' '..kampf.getGegner(), delay)
    end
end

-- verschmelze wieder aufheben: 3x schnell hintereinander beten
local function verschmelze_aufheben()
  timer.enqueue(1, createFunctionMitHands(2, 'bete', 10))
  timer.enqueue(5, 'bete')
  timer.enqueue(9, 'bete')
end


-- Sonnenschutz
local function autoSonnenschutz()
  if ME.lp <= 20 then
    logger.severe('Sonnenschaden bei niedrigen LP -> Auto-Logout!')
    client.send('schlaf ein')
  else
    inv.doWithHands(1, 'schutz')
  end
end

client.createSubstrTrigger('Die Sonne scheint gnadenlos auf Dein Haupt und schwaecht Dich.', autoSonnenschutz, {'red'})


-- Verkleiden

local function verkleidung_schneiden()
  local w = verkleidenWaffe()
  if w ~= nil then
    inv.wechselWaffe(w)
    client.send('schneide verkleidung aus leiche')
    inv.zueckeDefaultWaffe()
  end
end



-- ---------------------------------------------------------------------------
-- Trigger + Statuszeile

local function statusAn(id, optVal)
  return
    function()
      base.statusAdd(id, optVal)
    end
end

local function statusAus(id)
  return
    function()
      base.statusRemove(id)
    end
end

-- weihe
client.createRegexTrigger('Die Weihe .* klingt wieder ab.', statusAus('We'), {'red'})

-- aura
client.createSubstrTrigger('Um Dich herum entsteht eine *magische Aura.', statusAn('A'), {'green'})
client.createSubstrTrigger('Die Dich umgebene magische Aura stabilisiert sich wieder.', statusAn('A'), {'green'})
client.createSubstrTrigger('Die Magieaura die Dich umgibt loest sich allmaehlich auf.', statusAus('A'), {'red'})

-- schutzschild
client.createSubstrTrigger('Du konzentrierst Dich auf den Aufbau eines Schutzschilds.', nil, {'blue'})
client.createSubstrTrigger('Du machst eine Pirouette, schnippst danach mit dem Finger, und auf einmal', nil, {'green'})
client.createSubstrTrigger('entsteht ein magisches Schutzschild um Dich herum.', statusAn('S'), {'green'})
client.createSubstrTrigger('Das Schutzschild um Dich herum loest sich langsam auf.', nil, {'yellow'})
client.createSubstrTrigger('Dein Schutzschild ist nun aufgebraucht.', statusAus('S'), {'red'})

-- blitzhand
client.createSubstrTrigger('Du konzentrierst Dich einen Moment und laesst Deine magische Energie in', statusAn('hnd'), {'green'})
client.createSubstrTrigger('Das Kribbeln in Deinen Fingern laesst allmaehlich nach.', statusAus('hnd'), {'red'})
client.createSubstrTrigger('Deine magischen Kraefte verlassen Dich, Deine Haende entspannen sich wieder.', statusAus('hnd'), {'red'})

-- schmerzen
client.createRegexTrigger('  Du starrst .* in die Augen, bis .*', nil, {'green'})
client.createSubstrTrigger('Schmerzen lassen nach.', nil, {'red'})

-- beschwoere
local function beschwoere_pause()
  timer.enqueue(
    60,
    function()
      logger.info('beschwoere wieder moeglich (60 sec)')
    end
  )
end
client.createSubstrTrigger('Du machst zahlreiche Gesten ueber der Leiche, aber alle Versuche sie zum', beschwoere_pause, {'red'})
client.createSubstrTrigger('Du machst zahlreiche Gesten ueber der Leiche und erweckst sie zu neuem Leben.', beschwoere_pause, {'green'})

-- verschmelze
local function verschmelze_pause()
  timer.enqueue(
    60,
    function()
      logger.info('verschmelze wieder moeglich (60 sec)')
    end
  )
end
client.createSubstrTrigger('Du legst der Leiche drei Finger an die Schlaefe und vereinigst Deinen Geist', verschmelze_pause, {'green'})
client.createSubstrTrigger('Du merkst, wie Dein Geist allmaehlich wieder frei wird, und Du die Gedanken-', nil, {'yellow'})
client.createSubstrTrigger('verschmelzung wieder rueckgaengig machst.', nil, {'yellow'})
client.createSubstrTrigger('Du reinigst Deinen Geist von der Gedankenverschmelzung vollkommen und fuehlst', nil, {'green'})
client.createSubstrTrigger('Dich nun auch gleich wieder wesentlich wohler in Deiner Haut.', nil, {'green'})

-- sonnenschutz
client.createSubstrTrigger('Du murmelst einige Worte vor Dich hin, und auf einmal haeltst Du einen', statusAn('s'), {'green'})
client.createSubstrTrigger('Dein Schutzfilm gegen die Sonne verblasst langsam wieder.', statusAus('s'), {'red'})


-- ---------------------------------------------------------------------------
-- reboot / reset

local function reset()
  setVerkleidenWaffe(nil)
end

base.addResetHook(reset)


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

local function info()
  logger.info('Verkleiden    [#kvw]: '..(verkleidenWaffe() or ''))
end

base.gilde.info = info


-- ---------------------------------------------------------------------------
-- Tasten

-- licht
keymap.M_l = 'nachtsicht'
-- sonnenschutz
keymap.M_d = createFunctionMitHands(1, 'schutz')
-- bete (heilt), mit verzoegerung
keymap.M_z = createFunctionMitHands(2, 'bete', 5)
-- schutzzauber
keymap.M_m = createFunctionMitHands(2, 'aura')
keymap.M_v = 'schutzschild'
-- weihe
keymap.M_e = createFunctionMitHands(2, 'weihe mich')
keymap.M_r = createFunctionMitHands(2, 'weihe raum')
-- ehrfurcht (befriede)
keymap.M_p = createFunctionMitGegner('ehrfurcht')
keymap.M_i = createFunctionMitGegner('bannkreis')
keymap.M_g = createFunctionMitGegner('schmerz')
keymap.M_a = 'balsamiere leiche'
keymap.M_b = verkleidung_schneiden

-- kampf
keymap.F5   = 'blitzhand'
keymap.F6   = createFunctionMitHandsUndGegner(2, 'finsternis', 3)
keymap.F7   = createFunctionMitGegner('vergifte')
keymap.F8   = createFunctionMitHandsUndGegner(1, 'feuerlanze')
keymap.S_F8 = createFunctionMitHandsUndGegner(1, 'entziehe')

-- zombie
keymap.M_j = 'unt zombie'
keymap.M_k = createFunctionMitHands(2, 'beschwoere leiche leise')


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias(
  'skills',
  0,
  function()
    client.send('tm nenaisu sprueche', 'tm teo faehigkeiten')
  end
)

client.createStandardAlias('bete', 0, verschmelze_aufheben)
client.createStandardAlias('kvw', 1, setVerkleidenWaffe)
