
local base   = require 'base'
local tools  = require 'utils.tools'
local ME     = require 'gmcp-data'
local room   = require 'room'

local logger = client.createLogger('blight')


-- ---------------------------------------------------------------------------
-- base

-- gag all prompt lines
trigger.add(
  '',
  { prompt = true, gag = true },
  function(m) end
)


-- ---------------------------------------------------------------------------
-- ways

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

blight.status_height(4)

local function state()
  return base.getPersistentTable('utils')
end


local vitalsStatus = ''
local roomStatus = ''

local function status_update1()
  blight.status_line(1, vitalsStatus..'  '..roomStatus)
end

local vitalsFormat =
  C_BOLD..C_BRED..'LP:'..C_RESET..C_BOLD..'%s%3d'..C_BGREEN..'%1s '
  ..C_BBLUE..'KP:'..C_RESET..C_BOLD..'%3d%1s%1s'..C_RESET

local gift_views = {}
gift_views[0] = ' '
gift_views[1] = 'g'
gift_views[10] = 'G'

local function updateVitalsStatus()
  local lp_style = ''
  if ME.lp < math.min(0.381 * ME.lp_max, 80) then
    lp_style = C_RED
  elseif ME.lp < 0.631 * ME.lp_max then
    lp_style = C_YELLOW
  end
  local gift = gift_views[math.min(ME.gift,10)] or ME.gift or ' '
  local eblock_voll = state().eblock_voll and '*' or ' '
  local eblock_locked = state().eblock_locked and 'L' or ' '
  vitalsStatus = string.format(
    vitalsFormat,
    lp_style, ME.lp, gift, ME.kp, eblock_voll, eblock_locked
  )
  status_update1()
end

local roomStatusFormat =
  C_BGREEN..'%-13s  '..C_BCYAN..'%-9s  %-24s  %-5s  '..C_BRED..'%2s'..C_RESET

local function updateRoomStatus()
  local para = base.para()
  local paraString = '  '
  if para and para > 0 then
    paraString = 'P'..para
  end
  local wp = room.getRaumWegpunkt()
  wp = wp and '('..string.sub(wp, 1, 11)..')' or ' '
  local raum_kurz = string.sub(ME.raum_kurz or '', 1, 24)
  local region = string.sub(ME.raum_region or '', 1, 9)
  roomStatus = string.format(
    roomStatusFormat,
    wp, region, raum_kurz, ME.raum_id_short or '', paraString
  )
  status_update1()
end

base.registerEventHandler('gmcp.MG.char.vitals', updateVitalsStatus)
base.registerEventHandler('gmcp.MG.room.info', updateRoomStatus)


local gildenStatusFormat = '%-42s'

local gildenStatus = string.format(gildenStatusFormat, '')
local vsfrStatus = ''

local function status_update2()
  blight.status_line(2, gildenStatus..'  '..vsfrStatus)
end

local function updateGildenStatus()
  local status = base.getGildenStatusLine()
  gildenStatus = string.format(C_BMAGENTA..gildenStatusFormat..C_RESET, status)
  status_update2()
end

local vsfrFormat = C_BOLD..C_BBLUE..'VS:%3d  FR:%-20s'..C_RESET

local function updateVSFR()
  local vs = state().vorsicht or 0
  local flucht = tools.listJoin(room.getEscape(), ';') or state().fluchtrichtung or ''
  flucht = string.sub(flucht, 1, 24)
  vsfrStatus = string.format(vsfrFormat, vs, flucht)
  status_update2()
end

base.registerEventHandler('gmcp.MG.char.wimpy', updateVSFR)
base.registerEventHandler('gilde.statusline.update', updateGildenStatus)
