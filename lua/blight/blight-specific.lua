
local base   = require 'base'
local tools  = require 'tools'
local ME     = require 'gmcp-data'
local room   = require 'room'

local logger = client.createLogger('blight')


-- ---------------------------------------------------------------------------
-- base

base.keymap['M_,'] =
  function()
    local param = prompt.get()
    prompt.set('')
    client.executeStandardAlias('go', param)
  end

client.createStandardAlias('quit', 0, function() blight.quit() end)


-- ---------------------------------------------------------------------------
-- gmcp

local function receive(event)
  gmcp.receive(event, ME.accept[event])
end

gmcp.on_ready(
  function()
    logger.info('GMCP starten!')
    gmcp.register('MG.char 1')
    gmcp.register('MG.room 1')
    local clientName, version = blight.version()
    gmcp.send('Core.Hello { "client": "'..clientName..'", "version": "'..version..'" }')
    gmcp.send('Core.Debug 1')
    gmcp.send('Core.Supports.Set [ "MG.char 1", "MG.room 1" ]')
    receive('MG.char.base')
    receive('MG.char.info')
    receive('MG.char.maxvitals')
    receive('MG.char.vitals')
    receive('MG.char.wimpy')
    receive('MG.room.info')
  end
)


-- ---------------------------------------------------------------------------
-- status_area

blight.status_height(2)

local function state()
  return base.getPersistentTable('utils')
end

local function padLeft(s, n)
  s = '          '..s
  s = string.sub(s, string.len(s)-n+1)
  return s
end

local function padRight(s, n)
  s = s..'                              '
  s = string.sub(s, 1, n)
  return s
end

local gift_views = {}
gift_views[0] = '_'
gift_views[1] = 'g'
gift_views[10] = 'G'

local function vitalsStatus()
  local lp_style = C_BOLD
  if ME.lp < math.min(0.381 * ME.lp_max, 80) then
    lp_style = lp_style..C_RED
  elseif ME.lp < 0.631 * ME.lp_max then
    lp_style = lp_style..C_YELLOW
  end
  local lp = lp_style..padLeft(ME.lp, 3)..C_RESET
  local gift = gift_views[math.min(ME.gift,10)] or ME.gift or '_'
  local gift_style = gift == '_' and '' or C_BOLD..C_GREEN
  gift = gift_style..gift..C_RESET
  local kp = padLeft(ME.kp, 3)
  local s = state()
  local eblock = (s.eblock_voll and '*' or '_') .. (s.eblock_locked and 'L' or '_')
  return C_BOLD..'LP:'..lp..gift..'_'..C_BOLD..C_CYAN..'KP:'..kp..eblock..C_RESET
end

local function vsfrStatus()
  local vs = padLeft(state().vorsicht or 0, 3)
  local flucht = tools.listJoin(room.getEscape(), ';') or state().fluchtrichtung or ''
  flucht = padRight(flucht, 20)
  return C_BOLD..C_GREEN..'VS:'..vs..'_FR:'..flucht..C_RESET
end

local function roomStatus()
  local para = base.para()
  local paraString = '__'
  if para and para > 0 then
    paraString = C_BOLD..C_RED..'P'..para..C_RESET
  end
  local wp = padRight(room.getRaumWegpunkt() or '', 10)
  return paraString..'__WP:'..wp..'__'..(ME.raum_id_short or '')
end

local function status_update1()
  local lpkp = vitalsStatus()
  local vsfr = vsfrStatus()
  local room = roomStatus()
  blight.status_line(0, lpkp..'__'..vsfr..'__'..room)
end

local function status_update2()
  local gilde = base.getGildenStatusLine()
  blight.status_line(1, gilde)
end

base.registerEventHandler('gmcp.MG.char.vitals', status_update1)
base.registerEventHandler('gmcp.MG.char.wimpy', status_update1)
base.registerEventHandler('gmcp.MG.room.info', status_update1)
base.registerEventHandler('gmcp.MG.room.info', status_update1)
base.registerEventHandler('gilde.statusline.update', status_update2)
