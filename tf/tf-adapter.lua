local mg_lua_dir = os.getenv('MG_LUA_DIR')
package.path = package.path..';'..mg_lua_dir..'/lua/?.lua'


local tools = require 'tools'
local json   = require 'json'
local regex   = require 'rex_pcre2'


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
lightmode_colors['<reset>'] = '@{n}'

local darkmode_colors = {}
darkmode_colors['<red>'] = '@{Cbrightred}'
darkmode_colors['<green>'] = '@{Cbrightgreen}'
darkmode_colors['<yellow>'] = '@{Cbrightyellow}'
darkmode_colors['<blue>'] = '@{Cbrightblue}'
darkmode_colors['<magenta>'] = '@{Cbrightmagenta}'
darkmode_colors['<cyan>'] = '@{Cbrightcyan}'

local function getColor(c)
  if darkmode then
    return darkmode_colors[c] or lightmode_colors[c] or c
  else
    return lightmode_colors[c] or c
  end
end

local function replaceDarkmodeColors(s)
  if not darkmode then
    return s
  end
  for code,replacement in pairs(darkmode_colors) do
    s = string.gsub(s, '@{'..code..'}', '@{'..replacement..'}')
  end
  return s
end

local function cecho(msg)
  msg = string.gsub(msg, '(<%a+>)', getColor)
  msg = string.gsub(msg, '%%', '\\%%')
  tf_eval('/echo -p '..msg)
end

local function echo(msg)
  tf_eval('/_echo '..msg)
end

local function line()
  echo('------------------------------------------------------------')
end

local debug_on = false

local function createLogger(komponente)
  local kmp = '['..string.sub(komponente,1,5)..']'
  kmp = kmp..string.sub('     ',1,7-#kmp)
  return {
    debug =
      function(msg)
        if debug_on then
          tf_eval('/echo -aCmagenta [DEBUG] '..kmp..' '..msg)
        end
      end,
    info =
      function(msg)
        local color = getColor('<cyan>')
        cecho(color..' >>> '..kmp..' '..msg)
      end,
    warn =
      function(msg)
        tf_eval('/echo -aCbgyellow >>> '..kmp..' '..msg)
      end,
    severe =
      function(msg)
        tf_eval('/echo -aCbgred >>> '..kmp..' '..msg)
      end
  }
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
  local endOfName = string.len(args)
  local firstKomma = string.find(args,',')
  if firstKomma ~= nil then
    endOfName = firstKomma-1
  end
  local aliasName = string.sub(args,1,endOfName)
  local paramString = nil
  local params = {}
  if firstKomma ~= nil then
    paramString = string.sub(args, firstKomma+1)
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
        logger.severe('Alias mit '..i..' Parametern kann nicht aufgerufen werden!')
      end
      return
    end
  end
  logger.severe('Alias \''..aliasName..'\' nicht gefunden!')
end

local function executeStandardAlias(alias, param)
  if string.sub(alias,1,1) == '#' then
    callLuaAlias(string.sub(alias,2))
  else
    callLuaAlias(alias)
  end
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
      logger.severe('Style \''..s..'\' kann nicht uebersetzt werden!')
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
  args = string.sub(args,2,#args-2)
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
  return pattern
end

-- trigger creation
-- f: function to call with table of matches as parameter
-- return triggerID
local function createRegexTrigger(pattern, f, style, prio)
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

local function pattern2log(pattern)
  pattern = string.gsub(pattern, '%$', '')
  return pattern
end

local function rex_gsub(t, pattern, replacement)
  replacement = string.gsub(replacement, '$(%d)', '%%1')
  return regex.gsub(t, pattern, replacement)
end

local function rex_match(t, pattern)
  -- regex.match return full text if no captures are specified
  local m1,m2,m3,m4,m5,m6,m7,m8 = regex.match(t, pattern)
  if m1 == nil then
    return nil
  end
  return { m1,m2,m3,m4,m5,m6,m7,m8 }
end

local rex = {
  gsub = rex_gsub,
  match = rex_match,
}

local function matcheText(t, pattern, f)
  local matches = rex.match(t, pattern)
  logger.debug('matching multi-line buffer \''..t..'\' with pattern \''..pattern2log(pattern)..'\'')
  if matches ~= nil then
    matches.line = t
    f(matches)
  else
    logger.debug('multi line trigger: \'' .. t .. '\' passt nicht zu Pattern \'' .. pattern2log(pattern) .. '\'')
    echo(t)
  end
end

local function improveAnchors(pattern)
  if string.sub(pattern,1,2) == '(^' then
    pattern = '^('..string.sub(pattern,3)
  end
  if string.sub(pattern,-2) == '$)' then
    pattern = string.sub(pattern,1,-3)..')$'
  end
  return pattern
end

local function strip(s)
  local s = string.gsub(s, '^ *', '')
  return s
end

local PRIO_MULTILINES = 99999

-- ids fuer multiline trigger / multiline_trigger_buffer
local multi_re_ids = 0

-- Buffer fuer Zeilen der multiline trigger
-- id -> string (concatenated lines)
local multiline_trigger_buffer = {}

-- Erzeugung eines Multi-Line-Triggers.  Der Anfang des Patterns bis zum
-- speziellen Kennzeichen '><' wird als Erkennung des Multi-Line-Triggers
-- verwendet. Danach werden alle Zeilen genommen bis eine Zeile mit '.' oder '!'
-- endet. Das gesamte Pattern (ohne '><') wird für alle Zeilen genutzt bis zum
-- Textende.
-- f: aufzurufende Funktion, bekommt table matches als parameter
-- return triggerID
local function createMultiLineRegexTrigger(pattern, f, style, prio)
  local start = improveAnchors('(' .. string.gsub(pattern, '><.*$', '') .. '.*)$')
  local pattern_multi = string.gsub(pattern, '><', '')

  local id = multi_re_ids
  multi_re_ids = multi_re_ids + 1

  local id2
  id2 = createRegexTrigger(
    '^(.*)$',
    function(m)
      local line = m[1]
      multiline_trigger_buffer[id] = multiline_trigger_buffer[id] .. ' ' .. strip(line)
      if string.match(line, '.*[.!] ?$') then
        disableTrigger(id2)
        local buffer = multiline_trigger_buffer[id]
        multiline_trigger_buffer[id] = nil
        matcheText(buffer, pattern_multi, f)
      end
    end,
    style,
    PRIO_MULTILINES
  )
  disableTrigger(id2)

  local id1
  id1 = createRegexTrigger(
    start,
    function(m)
      local line = m[1]
      if string.match(line, '.*[.!] ?$') then
        matcheText(line, pattern_multi, f)
      else
        multiline_trigger_buffer[id] = line
        enableTrigger(id2)
      end
    end,
    style,
    prio
  )

  return id1
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

local function login(host, port, name, pwd)
  tf_eval('/addworld -Tlp MG '..name..' '..pwd..' '..host..' '..port)
  tf_eval('/connect MG')
end


-- ---------------------------------------------------------------------------
-- interaktion

createStandardAlias('debug', 0,  function(item) debug_on = not debug_on end)


-- ---------------------------------------------------------------------------
-- module definition

return {
  useKeyListener = function(f) keyListener = f end,
  createLogger = createLogger,
  line = line,
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
  regex = rex,
  login = login,
}
