-- timer: timed queued execution

local base  = require 'base'


local function isEmpty(t)
  for key,val in pairs(t) do
    return false
  end
  return true
end

local delayed_timer_created = false
local delayed_timer_active = false
local delayed_table = {}
local delayed_timer = 0

local function execute_delayed()
  if delayed_timer_active then
    delayed_timer = delayed_timer + 1
    for t,cmds in pairs(delayed_table) do
      if t <= delayed_timer then
        base.eval(cmds)
        delayed_table[t] = nil
      end
    end
    if isEmpty(delayed_table) then
      delayed_timer_active = false
    end
  end
end

local function enqueueCmd(sec, f)
  if not delayed_timer_created then
    delayed_timer_created = true
    client.createTimer(1, execute_delayed, 0)
  end
  if not delayed_timer_active then
    delayed_timer_active = true
    delayed_timer = 0
  end
  local cmds = delayed_table[delayed_timer + sec] or {}
  cmds[#cmds+1] = f
  delayed_table[delayed_timer + sec] = cmds
end

return {
  enqueue = enqueueCmd,
}
