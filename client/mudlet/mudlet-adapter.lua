
-- ---------------------------------------------------------------------------
-- Logging

local debug_level = 1
-- 3=err, 2=warn, 1=info, 0=debug
function debugLevel(level)
  debug_level = level
end

local function cecho_tfcolors(msg)
  msg = string.gsub(tf_text, '@{n}', '<reset>')
  msg = string.gsub(tf_text, '@{Cbg([^}]*)}', '<:%1>')
  msg = string.gsub(tf_text, '@{C([^}]*)}', '<%1>')
  cecho(msg)
end

local function createLogger(komponente)
  local kmp = '['..string.sub(komponente,1,5)..']'
  kmp = kmp..string.sub('     ',1,7-#kmp)
  return {
    debug =
      function(msg)
        if debug_level <= 0 then
          cecho('<grey>DEBUG '..kmp..' '..msg..'\n')
        end
      end,
    info =
      function(msg)
        if debug_level <= 1 then
          cecho('<cyan>>>>  '..kmp..' '..msg..'\n')
        end
      end,
    warn =
      function(msg)
        if debug_level <= 2 then
          cecho('<yellow>>>>  '..kmp..' '..msg..'\n')
        end
      end,
    error =
      function(msg)
        cecho('<red>>>> '..kmp..' '..msg..'\n')
      end
  }
end


local logger = createLogger('mudlt')


-- ---------------------------------------------------------------------------
-- Events

local handler = {}

local function handleEventMitMudlet(event)
  local allHandler = handler[event] or {}
  for _,f in ipairs(allHandler) do
    pcall(f)
  end
end

local function registerEventHandler(event, f)
  local handlerZumEvent = handler[event]
  if handlerZumEvent == nil then
    handlerZumEvent = {}
    handler[event] = handlerZumEvent
    -- event an normale mudlet-events haengen (mit neuen globalen functions)
    local nameHandlerZuEvent = '_handleEventMitMudlet_'..string.gsub(event, '%.', '_')
    _G[nameHandlerZuEvent] = function() handleEventMitMudlet(event) end
    registerAnonymousEventHandler(event, nameHandlerZuEvent)
  end
  handlerZumEvent[#handlerZumEvent+1] = f
end


-- ---------------------------------------------------------------------------
-- Aliases

local alias_ids = {}
local alias_cmds = {}

function _executeAliasCmd(name, n, matches)
  logger.debug('aufruf alias '..name..' mit '..n..' Parametern')
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
  local pattern = '^#'..name
  local aliasId = name..'~'..n
  for _=1,n-1 do
     pattern = pattern..'\\s+(\\S+)'
  end
  if n > 0 then
     pattern = pattern..'\\s+(.*\\S)'
  end
  pattern = pattern..'\\s*$'
  local code = [[_executeAliasCmd(']]..name..[[', ]]..n..[[, matches)]]
  alias_cmds[aliasId] = f

  local oldId = alias_ids[aliasId]
  if (oldId ~= nil) then
    killAlias(oldId)
  end

  local id = tempAlias(pattern, code)
  alias_ids[aliasId] = id
  return id
end


-- ---------------------------------------------------------------------------
-- Trigger

local trigger_id = 1  -- globaler counter
local trigger_cmds = {}

local styles = {
  g = deleteLine,
  green = function() fg('green') end,
  yellow = function() fg('yellow') end,
  red = function() fg('red') end,
  blue = function() fg('blue') end,
}

local function callStyleFunctions(style)
  for _,s in ipairs(style) do
    local f = styles[s]
    if f == nil then
      logger.error('Style \''..s..'\' kann nicht uebersetzt werden!')
    else
      f()
    end
  end
  resetFormat()
end

local function createStyleWrapper(style, f)
  if style == nil then
    return f
  else
    return
      function()
	pcall(f)
	callStyleFunctions(style)
      end
  end
end


function _executeTriggerCmd(name)
  local cmd = trigger_cmds[name]
  cmd()
end

-- Erzeugung eines Triggers.
-- f: aufzurufende Funktion (kann lokal sein)
-- return triggerID
local function createSubstrTrigger(pattern, f, style, prio)
  local name = 'lua_stdtrigger_'..trigger_id
  trigger_id = trigger_id + 1
  local code = [[_executeTriggerCmd(']]..name..[[')]]
  local triggerID = tempTrigger(pattern, code)
  trigger_cmds[name] = createStyleWrapper(style, f)
  return triggerID
end

function _executeRegexTriggerCmd(name, matches)
  local cmd = trigger_cmds[name]
  -- matches[2] ist der erste match
  cmd(matches[2],matches[3],matches[4],matches[5],matches[6],matches[7],matches[8],matches[9])
end

-- Erzeugung eines Triggers.
-- f: aufzurufende Funktion, aufgerufen wird f(p1,p2,p3,...) - pi ist match i
-- return triggerID
local function createRegexTrigger(pattern, f, style, prio)
  local name = 'lua_retrigger_'..trigger_id
  trigger_id = trigger_id + 1
  local code = [[_executeRegexTriggerCmd(']]..name..[[', matches)]]
  local triggerID = tempRegexTrigger(pattern, code)
  trigger_cmds[name] = createStyleWrapper(style, f)
  return triggerID
end


-- ---------------------------------------------------------------------------
-- Timer

local timer_id = 1
local timer_cmds = {}

function _execute_timer(id)
  local f = timer_cmds[id]
  timer_cmds[id] = nil
  f()
end

local function createTimer(sec, f)
  local id = 'timer'..timer_id
  timer_id = timer_id + 1
  timer_cmds[id] = f
  tempTimer(sec, [[_execute_timer(']]..id..[[')]])
end


-- ---------------------------------------------------------------------------
-- send / eval

local function multi_send(...)
  for _,msg in ipairs{...} do
    send(msg)
  end
end

local function eval(cmd)
  if type(cmd) == 'function' then
    cmd()
  elseif type(cmd) == 'string' then
    send(cmd)
  end
end

local function xtitle(title)
end


-- ---------------------------------------------------------------------------
-- module definition

return {
  createLogger = createLogger,
  cecho = cecho_tfcolors,
  registerEventHandler = registerEventHandler,
  raiseEvent = raiseEvent,
  createStandardAlias = createStandardAlias,
  createSubstrTrigger = createSubstrTrigger,
  createRegexTrigger = createRegexTrigger,
  createMultiLineRegexTrigger = createRegexTrigger, -- TODO
  enableTrigger = enableTrigger,
  disableTrigger = disableTrigger,
  killTrigger = killTrigger,
  createTimer = createTimer,
  send = multi_send,
  eval = eval,
  xtitle = xtitle,
}
