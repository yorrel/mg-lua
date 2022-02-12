
local base   = require 'base'
local tools  = require 'tools'
local ME     = require 'gmcp-data'
local room   = require 'room'

local logger = client.createLogger('tf')


-- ---------------------------------------------------------------------------
-- gmcp Daten auswerten

-- wird direkt von tf aufgerufen
function parseGmcpData(data)
  local endOfName = string.find(data, ' ')
  local name = string.sub(data, 1, endOfName-1)
  local jsonString = string.sub(data, endOfName)
  local acceptFunc = ME.accept[name]
  if acceptFunc ~= nil then
    acceptFunc(jsonString)
  end
end


-- ---------------------------------------------------------------------------
-- Daten -> tf fuer Statuszeile

local function state()
  return base.getPersistentTable('utils')
end

local gift_views = {}
gift_views[0] = '_'
gift_views[1] = 'g'
gift_views[10] = 'G'

local function vital2TF()
  tf_eval('/set LP='..ME.lp)
  local lp_style = 'B'
  if ME.lp < 0.631 * ME.lp_max then
    lp_style = 'BCbgyellow'
  elseif ME.lp < math.min(0.381 * ME.lp_max, 80) then
    lp_style = 'BCbgred'
  end
  tf_eval('/set LP_STYLE='..lp_style)
  tf_eval('/set KP='..ME.kp)
  local gift = gift_views[math.min(ME.gift,10)] or ME.gift or '_'
  tf_eval('/set GIFT='..gift)
  tf_eval('/set GIFT_STYLE='..(gift == '_' and 'B' or 'BCgreen'))
  local s = state()
  local eblock_voll = '_'
  if s.eblock_voll then
    eblock_voll = '*'
  end
  local eblock_locked = '_'
  if s.eblock_locked then
    eblock_locked = 'L'
  end
  tf_eval('/set EBLOCK_VOLL='..eblock_voll)
  tf_eval('/set EBLOCK_LOCKED='..eblock_locked)
  tf_eval('/status_update')
end

base.registerEventHandler('gmcp.MG.char.vitals', vital2TF)


local function room2TF()
  tf_eval('/set ROOMID='..ME.raum_id_short)
  tf_eval('/set PARA='..(base.para() or 0))
  tf_eval('/set PARA_STYLE='..(base.para() and 'BCred' or 'B'))
  tf_eval('/status_update')
end

base.registerEventHandler('gmcp.MG.room.info', room2TF)


local function vsfr2TF()
  tf_eval('/set VORSICHT='..(state().vorsicht or 0))
  local flucht = tools.listJoin(room.getEscape(), ';') or state().fluchtrichtung or ''
  tf_eval('/set FLUCHTRICHTUNG=' .. flucht)
  tf_eval('/status_update')
end

base.registerEventHandler('gmcp.MG.char.wimpy', vsfr2TF)
base.registerEventHandler('gmcp.MG.room.info', vsfr2TF)


local function gildenStatus2TF()
  local status = base.getGildenStatusLine()
  tf_eval('/set STATUS_GILDE='..status)
  tf_eval('/status_update')
end

base.registerEventHandler('gilde.statusline.update', gildenStatus2TF)
