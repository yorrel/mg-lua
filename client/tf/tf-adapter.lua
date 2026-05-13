local mg_lua_dir = os.getenv('MG_LUA_DIR')
package.path = package.path..';'..mg_lua_dir..'/lua/?.lua'


local tools   = require 'utils.tools'
local class   = require 'utils.class'
local json    = require 'dkjson'
local regex   = require 'rex_pcre2'
local loggers = require 'client.common.loggers'
local mre     = require 'client.common.multi-line-trigger'


-- ---------------------------------------------------------------------------
-- communication lua -> tf

local function send(...)
  for _,msg in ipairs{...} do
    msg = string.gsub(msg, '%%', '&perc&')
    tf_eval('/set _msg='..msg)
    tf_eval('/set _msg=$[replace("&perc&","%",_msg)]')
    tf_eval('/send %{_msg}')
  end
end


-- ---------------------------------------------------------------------------
-- keys

local keyListener = nil

-- wird von tf aus aufgerufen, muss daher global sein
function tf_dokey(key)
  if keyListener ~= nil then
    keyListener(key)
  end
end


-- ---------------------------------------------------------------------------
-- Output

local darkmode = os.getenv('MG_THEME') == 'dark'

local lightmode_colors = {}
lightmode_colors['<red>'] = '@{Cred}'
lightmode_colors['<green>'] = '@{Cgreen}'
lightmode_colors['<yellow>'] = '@{Cyellow}'
lightmode_colors['<blue>'] = '@{Cblue}'
lightmode_colors['<magenta>'] = '@{Cmagenta}'
lightmode_colors['<cyan>'] = '@{Ccyan}'
lightmode_colors['<bgred>'] = '@{Cbgred}'
lightmode_colors['<bggreen>'] = '@{Cbggreen}'
lightmode_colors['<bgmagenta>'] = '@{Cbgmagenta}'
lightmode_colors['<bgyellow>'] = '@{Cbgyellow}'
lightmode_colors['<bgcyan>'] = '@{Cbgcyan}'
lightmode_colors['<bold>'] = '@{B}'
lightmode_colors['<reset>'] = '@{n}'

local darkmode_colors = {}
darkmode_colors['<red>'] = '@{Cbrightred}'
darkmode_colors['<green>'] = '@{Cbrightgreen}'
darkmode_colors['<yellow>'] = '@{Cbrightyellow}'
darkmode_colors['<blue>'] = '@{Cbrightblue}'
darkmode_colors['<magenta>'] = '@{Cbrightmagenta}'
darkmode_colors['<cyan>'] = '@{Cbrightcyan}'

local function getColor(c)
  return darkmode and darkmode_colors[c] or lightmode_colors[c]
end

local function cecho(msg)
  msg = string.gsub(msg, '(<%l+>)', getColor)
  msg = string.gsub(msg, '%%', '\\%%')
  local lines = tools.splitString(msg, '\n')
  for _,line in ipairs(lines) do
    tf_eval('/echo -p -- '..line)
  end
end

local function echo(msg)
  tf_eval('/_echo '..msg)
end

local function createLogger(komponente)
  return loggers.createLogger(komponente, cecho)
end

local logger = createLogger('tf')


-- ---------------------------------------------------------------------------
-- Aliases

local aliases = {}


-- Standard-Alias mit n Pflicht-Parametern erzeugen.
-- Bei Eingabe von #name p1 ... pn wird f(p1,...,pn) aufgerufen.
-- Wird ein String uebergeben, so wird dieser einfach gesendet.
-- return aliasID
local function createStandardAlias(name, n, f)
  local id = name..'~'..n
  if type(f) == 'string' then
    aliases[id] = function() client.send(f) end
  else
    aliases[id] = f
  end
  tf_eval('/createLuaAlias '..name)
end

-- Aufruf aus tf
-- args: aliasName[,params]
function callLuaAlias(args)
  local endOfName = args:len()
  local firstKomma = string.find(args,',')
  if firstKomma ~= nil then
    endOfName = firstKomma-1
  end
  local aliasName = args:sub(1,endOfName)
  local paramString = nil
  local params = {}
  if firstKomma ~= nil then
    paramString = args:sub(firstKomma+1)
    params = tools.splitString(paramString, ' ')
    logger.debug('Parameter vorhanden, Roh-String \''..paramString..'\' zerlegt in List der Laenge '..#params)
  end
  for i=#params,0,-1 do
    local id = aliasName..'~'..i
    logger.debug('Pruefe Existenz von Alias '..id)
    local f = aliases[id]
    if f ~= nil then
      -- mit maximaler Anzahl Parameter ist zu verwenden
      local mergedParams = params
      if i < #params then
        -- die letzen #params-i parameter mergen
        mergedParams = tools.subTable(params, 1, i-1)
        local restParams = tools.subTable(params, i, #params+1)
        local lastParam = table.concat(restParams, ' ')
        mergedParams[i] = lastParam
        logger.debug('Alias \''..aliasName..'\' mit '..i..' Parametern (letzter gemerged zu '..lastParam..')')
      end
      if i <= 4 then
        f(mergedParams[1], mergedParams[2], mergedParams[3], mergedParams[4])
      else
        logger.error('Alias mit '..i..' Parametern kann nicht aufgerufen werden!')
      end
      return
    end
  end
  logger.error('Alias \''..aliasName..'\' nicht gefunden!')
end

local function executeStandardAlias(alias, param)
  local paramSuffix = param and ','..param or ''
  if alias:sub(1,1) == '#' then
    callLuaAlias(alias:sub(2)..paramSuffix)
  else
    callLuaAlias(alias..paramSuffix)
  end
end


-- ---------------------------------------------------------------------------
-- regex

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


-- ---------------------------------------------------------------------------
-- Trigger

-- Durch die create-Methoden werden tf-Trigger angelegt. Verwendete Namen:
-- id: std_42, re_42
-- tf-trigger:         lua_trigger_<id>
-- tf-trigger-pattern: lua_trigger_<id>_pattern

local trigger_cmds = {}
local trigger_type = {}
local trigger_switches = {}

local styles_common = {}
styles_common['g'] = '-ag'
styles_common['F'] = '-F'
styles_common['B'] = '-aB'
styles_common['<bgred>'] = '-aCbgred'
styles_common['<bggreen>'] = '-aCbggreen'
styles_common['<bgmagenta>'] = '-aCbgmagenta'
styles_common['<bgyellow>'] = '-aCbgyellow'
styles_common['<bgcyan>'] = '-aCbgcyan'

local styles_lightmode = {}
styles_lightmode['<red>'] = '-aCred'
styles_lightmode['<green>'] = '-aCgreen'
styles_lightmode['<yellow>'] = '-aCyellow'
styles_lightmode['<blue>'] = '-aCblue'
styles_lightmode['<magenta>'] = '-aCmagenta'
styles_lightmode['<cyan>'] = '-aCcyan'

local styles_darkmode = {}
styles_darkmode['<red>'] = '-aCbrightred'
styles_darkmode['<green>'] = '-aCbrightgreen'
styles_darkmode['<yellow>'] = '-aCbrightyellow'
styles_darkmode['<blue>'] = '-aCbrightblue'
styles_darkmode['<magenta>'] = '-aCbrightmagenta'
styles_darkmode['<cyan>'] = '-aCbrightcyan'


local function getStyleSwitch(s)
  if darkmode then
    return styles_darkmode[s]
  else
    return styles_lightmode[s]
  end
end

local function getStyleSwitches(style)
  local switches = ''
  if style == nil then
    return switches
  end
  for _,s in ipairs(style) do
    local switch = getStyleSwitch(s)
    if switch == nil then
      switch = styles_common[s]
    end
    if switch ~= nil then
      switches = switches..' '..switch
    else
      logger.error('Style \''..s..'\' kann nicht uebersetzt werden!')
    end
  end
  return switches
end

local function getPrioSwitch(prio)
  if prio == nil then
    return ''
  else
    return ' -p'..prio
  end
end

local function killTrigger(id)
  logger.debug('purge lua trigger: \''..(id or '')..'\'')
  if id == nil then
    logger.warn('purge lua trigger: id missing')
  else
    tf_eval('/purge lua_trigger_'..id)
  end
end

local function disableTrigger(id)
  killTrigger(id)
end

-- als id wird immer der tf-name des triggers verwendet
local function enableTrigger(id)
  killTrigger(id)
  logger.debug('create lua trigger: \''..(id or '')..'\'')
  local typ = trigger_type[id]
  local switches = trigger_switches[id]
  local tfTrigger = 'lua_trigger_'..id
  local patternId = 'lua_trigger_'..id..'_pattern'
  tf_eval('/set LUA_TF_BRIDGE_TRIGGER_TYP='..typ)
  tf_eval('/set LUA_TF_BRIDGE_TRIGGER_SWITCHES='..switches)
  tf_eval('/set LUA_TF_BRIDGE_TRIGGER_PATTERN=%{'..patternId..'}')
  tf_eval('/set LUA_TF_BRIDGE_TRIGGER_NAME='..tfTrigger)
  tf_eval('/set LUA_TF_BRIDGE_TRIGGER_ID='..id)
  tf_eval('/createLuaTrigger')
end


-- Aufruf von standard/regex-triggern aus tf heraus
-- args hat die Form: #match1#match2#...#match8#id#line#
function _executeTriggerCmd(args)
  logger.debug('aufruf trigger mit args: \''..args..'\'')
  args = args:sub(2,-3)
  local matches = tools.splitString(args, '#')
  local id = matches[9]
  local line = matches[10]
  matches.line = line
  matches[9] = nil
  matches[10] = nil
  local cmd = trigger_cmds[id]
    if type(cmd) == 'string' then
    send(cmd)
  end
  if type(cmd) == 'function' then
    cmd(matches)
  end
end

local trigger_id = 1  -- global counter

local function createTriggerId(typ)
  local id = typ..'_'..trigger_id
  trigger_id = trigger_id + 1
  return id
end

-- trigger creation
-- f: function to call
-- return triggerID
local function createSubstrTrigger(pattern, f, style, prio)
  local id = createTriggerId('std')
  local switches = getPrioSwitch(prio)..getStyleSwitches(style)
  local patternId = 'lua_trigger_'..id..'_pattern'
  tf_eval('/set '..patternId..'='..pattern)
  trigger_type[id] = 'substr'
  trigger_switches[id] = switches
  trigger_cmds[id] = f
  enableTrigger(id)
  return id
end

local function maskPattern(pattern)
  -- workaround: mask \\ and $ (does not work directly)
  pattern = string.gsub(pattern, '\\', '&backslash&')
  pattern = string.gsub(pattern, '%$', '&dollar&')
  -- workaround for '
  pattern = string.gsub(pattern, '\'', '.')
  return pattern
end

local dummyCallback = function() end

-- trigger creation
-- f: function to call with table of matches as parameter
-- return triggerID
local function createRegexTrigger(pattern, f, style, prio)
  f = f or dummyCallback
  local id = createTriggerId('re')
  local switches = getPrioSwitch(prio)..getStyleSwitches(style)
  local patternId = 'lua_trigger_'..id..'_pattern'
  pattern = maskPattern(pattern)
  -- set regex pattern as tf variable
  tf_eval('/set '..patternId..'='..pattern)
  -- unmask the tf variable in tf
  tf_eval('/unmask_pattern '..patternId)
  trigger_type[id] = 'regexp'
  trigger_switches[id] = switches
  trigger_cmds[id] = f
  enableTrigger(id)
  return id
end

local function createMultiLineRegexTrigger(pattern, f, style, prio)
  return
    mre.createMultiLineRegexTrigger(
      createRegexTrigger, enableTrigger, disableTrigger,
      Regex, logger, echo,
      pattern, f, style, prio
    )
end


-- ---------------------------------------------------------------------------
-- Timer

local timer_id = 1
local timer_cmds = {}
local timer_count = {}

function _execute_timer(id)
  local callback = timer_cmds[id]
  if timer_count[id] ~= 'i' then
    timer_count[id] = timer_count[id] - 1
  end
  if timer_count[id] == 0 then
    timer_cmds[id] = nil
    timer_count[id] = nil
  end
  callback()
end

-- f: function to call or string to send
-- count: optional (default 1), 0 means indefinitely
local function createTimer(sec, f, count)
  count = (count == 0 and 'i') or count or 1
  local id = 'timer'..timer_id
  timer_id = timer_id + 1
  local callback = f
  if type(f) == 'string' then
    callback = function() send(f) end
  end
  timer_cmds[id] = callback
  timer_count[id] = count
  tf_eval('/repeat -'..sec..' '..count..' /calllua _execute_timer '..id)
end

local function xtitle(title)
  tf_eval('/xtitle '..title)
end


-- ---------------------------------------------------------------------------
-- login

local loginName

local function login(host, port, name, pwd)
  loginName = name
  tf_eval('/addworld -Tlp MG '..name..' '..pwd..' '..host..' '..port)
  tf_eval('/connect MG')
end


-- ---------------------------------------------------------------------------
-- logfile

local function startLog()
  local logfile = loginName..'_'..os.date('%Y-%m-%d_%H%M%S')..'.log'
  tf_eval('/log -i '..logfile)
  tf_eval('/log '..logfile)
end

local function stopLog()
  tf_eval('/log off')
end


-- ---------------------------------------------------------------------------
-- module definition

return {
  configKeymap = function(f) keyListener = f end,
  createLogger = createLogger,
  cecho = cecho,
  createStandardAlias = createStandardAlias,
  executeStandardAlias = executeStandardAlias,
  createSubstrTrigger = createSubstrTrigger,
  createRegexTrigger = createRegexTrigger,
  createMultiLineRegexTrigger = createMultiLineRegexTrigger,
  enableTrigger = tools.varargCallClosure(enableTrigger),
  disableTrigger = tools.varargCallClosure(disableTrigger),
  killTrigger = tools.varargCallClosure(killTrigger),
  createTimer = createTimer,
  send = send,
  xtitle = xtitle,
  json = json,
  regex = function(pattern) return Regex(pattern) end,
  login = login,
  startLog = startLog,
  stopLog = stopLog,
}
