
local tools = require 'utils.tools'


-- ---------------------------------------------------------------------------
-- communication -> mud

local function send(...)
  for _,msg in ipairs{...} do
    mud.send(msg, { gag = true })
  end
end


-- ---------------------------------------------------------------------------
-- keys

local keyListener = nil

local function key(code, codeBlight)
  if codeBlight == nil then
    codeBlight = string.gsub(code, 'C[-]', 'Ctrl-')
    codeBlight = string.gsub(codeBlight, 'M[-]', 'Alt-')
  end
  code = string.gsub(code, '[-]', '_')
  blight.bind(codeBlight, function() keyListener(code) end)
end

local all_keys = 'abcdefghijklmnopqrstuvwxyz'
local i = 1
while i <= all_keys:len() do
  local k = all_keys:sub(i, i)
  key('C-'..k)
  key('M-'..k)
  i = i + 1
end

key('F1', 'f1')
key('F2', 'f2')
key('F3', 'f3')
key('F4', 'f4')
key('F5', 'f5')
key('F6', 'f6')
key('F7', 'f7')
key('F8', 'f8')
key('F9', 'f9')
key('F10', 'f10')
key('F11', 'f11')
key('F12', 'f12')

key('S-F1', '\u{1b}[1;2p')
key('S-F2', '\u{1b}[1;2q')
key('S-F3', '\u{1b}[1;2r')
key('S-F4', '\u{1b}[1;2s')
key('S-F5', '\u{1b}[15;2~')
key('S-F6', '\u{1b}[17;2~')
key('S-F7', '\u{1b}[18;2~')
key('S-F8', '\u{1b}[19;2~')
key('S-F9', '\u{1b}[20;2~')
key('S-F10', '\u{1b}[21;2~')
key('S-F11', '\u{1b}[23;2~')
key('S-F12', '\u{1b}[24;2~')

key('M-0')
key('M-1')
key('M-2')
key('M-3')
key('M-4')
key('M-5')
key('M-6')
key('M-7')
key('M-8')
key('M-9')

key('M-,')

-- M-left, M-right, Ctrl-entf
blight.bind('\u{1b}[1;3d', function() blight.ui('step_word_left') end)
blight.bind('\u{1b}[1;3c', function() blight.ui('step_word_right') end)
blight.bind('\u{1b}[3;5~', function() blight.ui('delete_to_end') end)
-- home/end
blight.bind('home',        function() blight.ui('step_to_start') end)
blight.bind('end',         function() blight.ui('step_to_end') end)


-- ---------------------------------------------------------------------------
-- Output

local darkmode = os.getenv('MG_THEME') == 'dark'


local color_codes = {}
color_codes['<red>'] = C_RED
color_codes['<green>'] = C_GREEN
color_codes['<yellow>'] = C_YELLOW
color_codes['<blue>'] = C_BLUE
color_codes['<magenta>'] = C_MAGENTA
color_codes['<cyan>'] = C_CYAN
color_codes['<bgred>'] = BG_RED
color_codes['<bggreen>'] = BG_GREEN
color_codes['<bgmagenta>'] = BG_MAGENTA
color_codes['<bgyellow>'] = BG_YELLOW
color_codes['<bold>'] = C_BOLD
color_codes['<reset>'] = C_RESET

local darkmode_colors = {}
darkmode_colors['<red>'] = C_BRED
darkmode_colors['<green>'] = C_BGREEN
darkmode_colors['<yellow>'] = C_BYELLOW
darkmode_colors['<blue>'] = C_BBLUE
darkmode_colors['<magenta>'] = C_BMAGENTA
darkmode_colors['<cyan>'] = C_BCYAN

local function getColor(c)
  if darkmode then
    return darkmode_colors[c] or color_codes[c]
  end
  return color_codes[c]
end

local function replaceColorCodes(s)
  if not darkmode then
    return s
  end
  s = string.gsub(s, '(<%l*>)', getColor)
  return s
end

local function cecho(msg)
  blight.output(replaceColorCodes(msg))
end

local function line()
  blight.output('------------------------------------------------------------')
end

local debug_on = false

local function createLogger(komponente)
  local kmp = '['..komponente:sub(1,5)..']'
  kmp = kmp..string.sub('     ',1,7-#kmp)
  return {
    debug =
      function(msg)
        if debug_on then
          cecho('<cyan>[DEBUG] '..kmp..' '..msg..'<reset>')
        end
      end,
    info =
      function(msg)
        cecho('<cyan>>>> '..kmp..' '..msg..'<reset>')
      end,
    warn =
      function(msg)
        cecho('<bgyellow>>>> '..kmp..' '..msg..'<reset>')
      end,
    error =
      function(msg)
        cecho('<bgred>>>> '..kmp..' '..msg..'<reset>')
      end
  }
end


local logger = createLogger('blight')


-- ---------------------------------------------------------------------------
-- regex

local function rex_replace(s, pattern, replacement)
  local re = regex.new(pattern)
  return re:replace(s, replacement)
end

-- if s matches, return table of captures, otherwise return nil
local function rex_match(s, pattern)
  local re = regex.new(pattern)
  local t = re:match(s)
  if t ~= nil then
    local m = {}
    -- blight.regex.match returns t[1]=full_text, t[2]=match1, etc.
    for i,s in ipairs(t) do
      if i > 1 then
        m[i-1] = t[i]
      end
    end
    return m
  end
  return nil
end

local rex = {
  replace = rex_replace,
  match = rex_match,
}


-- ---------------------------------------------------------------------------
-- Aliases

local lastMatchedStandardAliasLine

local aliases = {}

-- Standard-Alias mit n Pflicht-Parametern erzeugen.
-- Bei Eingabe von #name p1 ... pn wird f(p1,...,pn) aufgerufen.
local function createStandardAlias(name, n, f, tabCompletion)
  if n > 6 then
    logger.error('Alias mit '..n..' Parametern werden nicht unterstuetzt!')
  end
  local re = '^#'..name
  for i=1,n-1 do re = re..'\\s+(\\S+)' end
  if n>0 then
    re = re..'\\s+(.*\\S)'
  end
  re = re..'\\s*$'
  if type(f) == 'string' then
    f = function() send(f) end
  end
  local callback =
    function(m, line)
      if line ~= lastMatchedStandardAliasLine or line == nil then
        lastMatchedStandardAliasLine = line
        f(m[2], m[3], m[4], m[5], m[6], m[7])
      end
    end
  aliases[name..'~'..n] = callback
  alias.add(re, callback)
  if tabCompletion then
    blight.on_complete(
      function(input)
        if input:sub(1, #name+1) == '#'..name then
          local arg = input:sub(name:len()+3)
          local t = {}
          for _,v in ipairs(tabCompletion(arg)) do
            table.insert(t, '#'..name..' '..v)
          end
          return t, true
        end
        return {}
      end
    )
  end
end

local function executeStandardAlias(alias, param)
  if alias:sub(1,1) == '#' then
    alias = alias:sub(2)
  end
  param = param or ''
  local t = tools.splitString(param, ' ')
  local n = #t
  local callback = aliases[alias..'~'..#t]
  lastMatchedStandardAliasLine = nil
  if callback ~= nil then
    callback({nil, t[1], t[2], t[3], t[4], t[5], t[6]}, nil)
  else
    logger.error('Alias '..alias..' mit '..n..' Parametern nicht gefunden!')
  end
end


-- ---------------------------------------------------------------------------
-- Trigger

local styles_trigger = {}
styles_trigger['B'] = C_BOLD

local function getTriggerOptions(style)
  if style ~= nil and tools.listContains(style, 'g') then
    return { gag = true, enabled = true }
  end
  return { enabled = true }
end

local function getTriggerColor(style)
  local color = ''
  if style == nil then
    return color
  end
  for _,s in ipairs(style) do
    local code = getColor(s) or styles_trigger[s]
    if code ~= nil then
      color = color..code
    end
  end
  return color
end

local function killTrigger(id)
  trigger.remove(id)
end

local function disableTrigger(id)
  trigger.get(id):set_enabled(false)
end

local function enableTrigger(id)
  trigger.get(id):set_enabled(true)
end

local dummyCallback = function() end

-- letztes line Object, um Verarbeitung weiterer Trigger zu verhindern
-- (wenn Trigger kein fallthrough-Trigger ist)
local lastMatchedLine

-- f: function to call with table of matches as parameter
-- return triggerID
local function createRegexTrigger(pattern, f, style, prio)
  f = f or dummyCallback
  local options = getTriggerOptions(style)
  local color = getTriggerColor(style)
  local callback =
    function(matches, line)
      local l = line:line()
      -- fallthrough handling
      if lastMatchedLine == line then
        return
      end
      local fallthrough = style ~= nil and tools.listContains(style, 'F')
      if not fallthrough then
        lastMatchedLine = line
      end
      -- process match
      local m = {}
      m.line = l
      for i,s in ipairs(matches) do
        if i > 1 then
          m[i-1] = matches[i]
        end
      end
      line:replace(color..l..C_RESET)
      f(m)
    end
  return trigger.add(pattern, options, callback).id
end

-- f: function to call
-- return triggerID
local function createSubstrTrigger(pattern, f, style, prio)
  local re = string.gsub(pattern, '([%.%?%*%+%(%)])', '\\%1')
  return createRegexTrigger(re, f, style, prio)
end

local function pattern2log(pattern)
  pattern = string.gsub(pattern, '%$', '')
  return pattern
end

local function matcheText(t, pattern, f)
  local matches = rex.match(t, pattern)
  logger.debug('matching multi-line buffer \''..t..'\' with pattern \''..pattern2log(pattern)..'\'')
  if matches ~= nil then
    matches.line = t
    f(matches)
  else
    logger.debug('multi line trigger: \'' .. t .. '\' passt nicht zu Pattern \'' .. pattern2log(pattern) .. '\'')
    blight.output(t)
  end
end

local function strip(s)
  local s = string.gsub(s, '^ *', '')
  return s
end

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
  local start = string.gsub(pattern, '><.*$', '')
  local pattern_multi = string.gsub(pattern, '><', '')
  local id = multi_re_ids
  multi_re_ids = multi_re_ids + 1

  local id2
  id2 = createRegexTrigger(
    '^(.*)$',
    function(m)
      local line = m.line
      multiline_trigger_buffer[id] = multiline_trigger_buffer[id] .. ' ' .. strip(line)
      if string.match(line, '.*[.!] ?$') then
        disableTrigger(id2)
        local buffer = multiline_trigger_buffer[id]
        multiline_trigger_buffer[id] = nil
        matcheText(buffer, pattern_multi, f)
      end
    end,
    style
  )
  disableTrigger(id2)

  local id1
  id1 = createRegexTrigger(
    start,
    function(m)
      local line = m.line
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

-- f: function to call, or a string to send
-- count: optional (default 1)
local function createTimer(sec, f, count)
  count = count or 1
  local callback = f
  if type(f) == 'string' then
    callback = function() send(cmd) end
  end
  timer.add(sec, count, callback)
end

local function xtitle(title)
  mud.add_tag(title)
end


-- ---------------------------------------------------------------------------
-- login

local loginName
local loginPwd

local loginTrigger1
local loginTrigger2

loginTrigger1 = createRegexTrigger(
  '^Der Steinbeisser verschwindet wieder, und Du wachst in einer anderen Welt auf\\.$',
  function()
    disableTrigger(loginTrigger1)
    enableTrigger(loginTrigger2)
    mud.send(loginName)
  end
)
disableTrigger(loginTrigger1)

loginTrigger2 = createRegexTrigger(
  '^Schoen, dass Du wieder da bist.*!$',
  function()
    disableTrigger(loginTrigger2)
    mud.send(loginPwd, { gag = true })
  end
)
disableTrigger(loginTrigger2)

local function login(host, port, name, pwd)
  enableTrigger(loginTrigger1)
  loginName = name
  loginPwd = pwd
  mud.connect(host, port, false, false)
end


-- ---------------------------------------------------------------------------
-- interaktion

createStandardAlias(
  'debug',
  0,
  function()
    debug_on = not debug_on
    logger.info('Debug: '..(debug_on and 'on' or 'off'))
  end
)


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
