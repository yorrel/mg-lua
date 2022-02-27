
local base   = require 'base'
local inv    = require 'inventory'
local room   = require 'room'
local ME     = require 'gmcp-data'
local kampf  = require 'battle'
local tools  = require 'utils.tools'

local logger = client.createLogger('utils')

local keymap = base.keymap


local function state()
  return base.getPersistentTable('utils')
end


-- ---------------------------------------------------------------------------
-- Standardfunktionen

-- ohne Parameter wird eigenes Haus geoeffnet
local function betrete_haus(name)
  name = name or base.charName()
  client.send(
    'schliesse haus von ' .. name .. ' auf',
    'oeffne haus von ' .. name,
    'betrete haus von ' .. name,
    'schliesse haus',
    'schliesse haus ab'
  )
end

local function untersucheMich()
  client.line()
  client.send('unt '..base.charName())
end

local function kerbholz(npc)
  inv.doWithHands(1, 'richte kerbholz auf '..(npc or kampf.getGegner()))
end

local function toggleScoreamu()
  local s = state()
  s.scoreamu = not (s.scoreamu or false)
  if s.scoreamu then
    logger.info('Ausruestungsanzeige mit Scoreamulett')
  else
    logger.info('Standardanzeige fuer Ausruestung')
  end
end

local function zeigeAusruestung()
  local cmd = 'ausruestung -k'
  if state().scoreamu then
    cmd = 'sinfo'
  end
  client.send(cmd)
end

-- ---------------------------------------------------------------------------
-- Elfenbeinblock

local function eblockVollErkannt()
  logger.info('Elfenbeinblock ist voll.')
  base.gagNextLine('in den Block.')
  state().eblock_voll = true
end

local function eblockLeerErkannt()
  logger.warn('Elfenbeinblock ist leer!')
  state().eblock_voll = false
end

local function eblock()
  if not state().eblock_voll then
    inv.doWithHands(1, 'dare')
  else
    state().eblock_locked = not state().eblock_locked
    local msg = ''
    if not state().eblock_locked then
      msg = ' NICHT'
    end
    logger.info('Elfenbeinblock'..msg..' locked.')
  end
  base.raiseEvent('gmcp.MG.char.vitals')
end

-- automatisch nachladen wenn EBlock nicht gelocked ist
local function utilsMGLpKpListener()
  local s = state()
  if ME.kp < 21 and s.eblock_voll and not s.eblock_locked then
    inv.doWithHands(1, 'sumere')
  end
end

base.registerEventHandler('gmcp.MG.char.vitals', utilsMGLpKpListener)

-- trigger zur Erkennung
client.createSubstrTrigger([[Du konzentrierst Dich kurz und uebertraegst einen Teil Deiner magischen Energie]], eblockVollErkannt, {'g'})
client.createSubstrTrigger([[Der Elfenbeinblock ist doch geladen!]], eblockVollErkannt, {'g'})
client.createSubstrTrigger([[Frische Kraft stroemt aus dem Elfenbeinblock in Deinen Koerper.]], eblockLeerErkannt, {'g'})
client.createSubstrTrigger([[Der Elfenbeinblock ist gar nicht geladen!]], eblockLeerErkannt, {'g'})


-- ---------------------------------------------------------------------------
-- Ohrenschuetzer

local ohrenschuetzer_aktiv = false
local function toggle_ohrenschuetzer()
  if ohrenschuetzer_aktiv then
    client.send('ziehe ohrenschuetzer aus')
  else
    client.send('trage ohrenschuetzer')
  end
  ohrenschuetzer_aktiv = not ohrenschuetzer_aktiv
end


-- ---------------------------------------------------------------------------
-- Dschinn

local dschinn_aktiv = false
local function dschinn()
  if dschinn_aktiv then
    client.send('verschwinde dschinn')
  else
    client.send('reibe lampe')
  end
  dschinn_aktiv = not dschinn_aktiv
end


-- ---------------------------------------------------------------------------
-- Highlighting

client.createSubstrTrigger([[teilt Dir mit:]], nil, {'B','<cyan>','F'}, 0)
client.createSubstrTrigger([[Die Hydra sinkt langsam in das Tal der Lupinen nieder.]], nil, {'B','<magenta>'})
client.createSubstrTrigger([[Die Elster klaut]], nil, {'B','<red>'})
client.createSubstrTrigger([[wird von der Saeure angeaetzt.]], nil, {'B','<red>'})
client.createSubstrTrigger([[Du merkst, wie sich der Wurzelsaft aufloest.]], nil, {'B','<red>'})


-- ---------------------------------------------------------------------------
-- gagging

client.createSubstrTrigger([[Du bist nun im 'Lang'modus.]], nil, {'g'})
client.createSubstrTrigger([[Du bist nun im 'Ultrakurz'modus.]], nil, {'g'})

local function withLine(cmd)
  return
    function()
      client.line()
      client.send(cmd)
    end
end

local directions = {
  n = 'norden',
  s = 'sueden',
  o = 'osten',
  w = 'westen'
}

local directions_variants = {
  'oben',
  'unten'
}

local function getDirectionFor(dir)
  local dirLong = directions[dir]
  if dirLong == nil then
    return nil
  end
  local dirShort = dirLong:sub(1, -3)
  local exits = tools.listMap(
    ME.raum_exits,
    function(s) return s:lower() end
  )
  -- exit exists
  if tools.listContains(exits, dirLong) then
    return dir
  end
  -- exactly one variant exists
  local dirVariants = tools.listMap(
    directions_variants,
    function(s) return dirShort..s end
  )
  local exitsDirVariants = tools.listFilter(
    dirVariants,
    function(s) return tools.listContains(exits, s) end
  )
  if #exitsDirVariants == 1 then
    return exitsDirVariants[1]
  end
  -- exactly one exit containing dir exists
  local exitsWithDir = tools.listFilter(
    exits,
    function(s) return s:find(dirShort) end
  )
  if #exitsWithDir == 1 then
    logger.info(dir..' -> '..exitsWithDir[1])
    return exitsWithDir[1]
  end
  return nil
end

local function move(dir)
  return
    function()
      client.line()
      client.send(
        room.getCmdForExit(dir)
        or getDirectionFor(dir)
        or dir
      )
    end
end


-- ---------------------------------------------------------------------------
-- reset

base.addResetHook(
  function()
    local s = state()
    s.scoreamu = false
    s.eblock_voll = false
    s.eblock_locked = true
  end
)


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.F1   = withLine('schau')
keymap.S_F1 = untersucheMich
keymap.F2   = withLine('inv -a')
keymap.S_F2 = 'info'
keymap.F12  = dschinn

keymap.M_n = move('n')
keymap.M_o = move('o')
keymap.M_s = move('s')
keymap.M_w = move('w')
keymap.M_h = move('ob')
keymap.M_u = move('u')

keymap.M_1 = 'iss drops'
keymap.M_2 = eblock
keymap.M_3 = 'vesdael'           -- Heilung mit Ring von Vesray
keymap.M_4 = zeigeAusruestung

keymap.C_y = toggle_ohrenschuetzer


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('haus', 1, betrete_haus)
client.createStandardAlias('scoreamu', 0, toggleScoreamu)

client.createStandardAlias('rk', 0, kerbholz)
client.createStandardAlias('rk', 1, kerbholz)
