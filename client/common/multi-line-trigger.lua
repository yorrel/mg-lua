-- multi line regex trigger

local function pattern2log(pattern)
  pattern = string.gsub(pattern, '%$', '')
  return pattern
end

local function matcheText(t, re, pattern, f, logger, output)
  local matches = re:match(t)
  logger.debug('matching multi-line buffer \''..t..'\' with pattern \''..pattern2log(pattern)..'\'')
  if matches ~= nil then
    matches.line = t
    f(matches)
  else
    logger.debug('multi line trigger: \'' .. t .. '\' passt nicht zu Pattern \'' .. pattern2log(pattern) .. '\'')
    output(t)
  end
end

local function strip(s)
  local s = string.gsub(s, '^ *', '')
  return s
end

local dummyCallback = function() end

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
local function createMultiLineRegexTrigger(
    createRegexTrigger, enableTrigger, disableTrigger,
    Regex, logger, output,
    pattern, f, style, prio)
  f = f or dummyCallback
  local start = string.gsub(pattern, '><.*$', '')
  local pattern_multi = string.gsub(pattern, '><', '')
  local re_multi = Regex(pattern_multi)
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
        matcheText(buffer, re_multi, pattern_multi, f, logger, output)
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
        matcheText(line, re_multi, pattern_multi, f, logger, output)
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
-- module definition

return {
  createMultiLineRegexTrigger = createMultiLineRegexTrigger,
}
