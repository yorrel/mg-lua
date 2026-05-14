
local tools   = require 'utils.tools'
local class   = require 'utils.class'
local regex   = require 'rex_pcre2'
local loggers = require 'client.common.loggers'
local mre     = require 'client.common.multi-line-trigger'


-- ---------------------------------------------------------------------------
-- Output & Logging

local function cecho(msg)
  local lines = tools.splitString(msg, '\n')
  for _,line in ipairs(lines) do
    local output_raw = string.gsub(line, '<%w*>', '')
    print(output_raw)
  end
end

local function createLogger(komponente)
  return loggers.createLogger(komponente, cecho)
end

local logger = createLogger('test')


-- ---------------------------------------------------------------------------
-- Aliases

local alias_ids = alias_ids or {}
local alias_cmds = alias_cmds or {}


function _executeAliasCmd(name, n, matches)
  local aliasId = name..'~'..n
  local cmd = alias_cmds[aliasId]
  -- matches[2] ist der erste match
  cmd(matches[2],matches[3],matches[4],matches[5],matches[6],matches[7],matches[8],matches[9])
end

-- Standard-Alias mit n Pflicht-Parametern erzeugen.
-- bei Eingabe von #name p1 ... pn wird f(p1,...,pn) aufgerufen
-- name~n muss eindeutig sein
-- return aliasID
local function createStandardAlias(name, n, f)
  local aliasId = name..'~'..n
  alias_cmds[aliasId] = f
  return 'dummy'
end


-- ---------------------------------------------------------------------------
-- stub standard functions

local nop = function() end

local function send(...)
  for _,msg in ipairs{...} do
    print('[2MUD]   '..msg)
  end
end

local Regex = class(
  function(a, pattern)
    a.re = regex.new(pattern)
  end
)
function Regex:replace(s, replacement)
  replacement = string.gsub(replacement, '$(%d)', '%%1')
  return regex.gsub(s, self.re, replacement)
end
-- if s matches, return table of captures, otherwise return nil
function Regex:match(s)
  -- regex.match return full text if no captures are specified
  local m1,m2,m3,m4,m5,m6,m7,m8 = regex.match(s, self.re)
  if m1 == nil then
    return nil
  end
  return { m1,m2,m3,m4,m5,m6,m7,m8 }
end

local trigger_id = 0
local all_trigger = {}

local function enableTrigger(id)
  for _,trigger in ipairs(all_trigger) do
    if trigger.id == id then
      trigger.active = true
    end
  end
end

local function disableTrigger(id)
  for _,trigger in ipairs(all_trigger) do
    if trigger.id == id then
      trigger.active = false
    end
  end
end

local function createRegexTrigger(pattern, f, style, prio)
  f = f or nop
  local id = trigger_id
  trigger_id = trigger_id + 1
  local trigger = {
    id = id,
    pattern = pattern,
    f = f,
    active = true
  }
  all_trigger[#all_trigger+1] = trigger
  return trigger.id
end

local function createMultiLineRegexTrigger(pattern, f, style, prio)
  return
    mre.createMultiLineRegexTrigger(
      createRegexTrigger, enableTrigger, disableTrigger,
      Regex, logger, print,
      pattern, f, style, prio
    )
end

local function createSubstrTrigger(pattern, f, style, prio)
  local re = string.gsub(pattern, '([%.%?%*%+%(%)])', '\\%1')
  return createRegexTrigger(re, f, style, prio)
end


-- ---------------------------------------------------------------------------
-- test functions

local function trigger(text)
  for _,trigger in ipairs(all_trigger) do
    if trigger.active then
      local m1,m2,m3,m4,m5,m6,m7,m8 = regex.match(text, trigger.pattern)
      if m1 then
        local m = { m1,m2,m3,m4,m5,m6,m7,m8 }
        trigger.f(m)
        return
      end
    end
  end
end


-- ---------------------------------------------------------------------------
-- test client definition

return {
  configKeymap = nop,
  createLogger = createLogger,
  cecho = cecho,
  createStandardAlias = createStandardAlias,
  executeStandardAlias = _executeAliasCmd,
  createSubstrTrigger = createSubstrTrigger,
  createRegexTrigger = createRegexTrigger,
  createMultiLineRegexTrigger = createMultiLineRegexTrigger,
  enableTrigger = tools.varargCallClosure(enableTrigger),
  disableTrigger = tools.varargCallClosure(disableTrigger),
  killTrigger = nop,
  createTimer = nop,
  send = send,
  xtitle = nop,
  json = json,
  regex = function(pattern) return Regex(pattern) end,
  login = nop,
  startLog = nop,
  stopLog = nop,
  trigger = trigger,
}
