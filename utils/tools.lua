
-- Utilities
-- darf keine Abhaengigkeiten haben


-- ---------------------------------------------------------------------------
-- table utilities

-- append t2 at the end of t1
local function tableConcat(t1,t2)
  for i=1,#t2 do
    t1[#t1+1] = t2[i]
  end
end

local function tableJoin(t1,t2)
  for k,v in pairs(t2) do
    t1[k] = v
  end
end

local function tableKeySet(t)
  local keys = {}
  for key,_ in pairs(t) do
    table.insert(keys, key)
  end
  return keys
end

-- erzeugt neue table vom index first bis last
local function subTable(t, first, last)
  local result = {}
  for k,v in ipairs(t) do
    if k>=first and k<=last then
      result[#result+1] = v
    end
  end
  return result
end

local function listJoin(t, separator)
  if t == nil then
    return nil
  end
  local s = ''
  for _,e in ipairs(t) do
    s = s .. e .. separator
  end
  if s:len() > 0 then
    s = s:sub(1, -separator:len()-1)
  end
  return s
end

local function listContains(list, element)
  if list == nil then return false end
  for _,v in ipairs(list) do
    if (v == element) then
      return true
    end
  end
  return false
end

local function listRemove(list, element)
  if list == nil then return end
  for k,v in ipairs(list) do
    if (v == element) then
      table.remove(list,k)
      return
    end
  end
end

local function listMap(list, f)
  local result = {}
  for _,v in ipairs(list) do
    table.insert(result, f(v))
  end
  return result
end

local function listFilter(list, f)
  local result = {}
  for _,v in ipairs(list) do
    if f(v) then
      table.insert(result, v)
    end
  end
  return result
end

-- ---------------------------------------------------------------------------
-- div utilities

local function splitString(s, pattern)
  local t = {}
  local i = 1
  while true do
    local next = string.find(s, pattern, i, true)
    if next == nil then
      if i <= s:len() then
        t[#t+1] = s:sub(i)
      end
      return t
    else
      t[#t+1] = s:sub(i,next-1)
      i = next + pattern:len()
    end
  end
end

local function splitWords(s)
  local t = {}
  local i = 1
  local start = nil
  while i <= s:len() do
    local c = s:sub(i,i)
    if start == nil then
      if c ~= ' ' then
        start = i
      end
    else
      if c == ' ' then
        t[#t+1] = s:sub(start,i-1)
        start = nil
      end
    end
    i = i + 1
  end
  if start ~= nil then
    t[#t+1] = s:sub(start)
  end
  return t
end

local function capitalize(word)
  return word:sub(1,1):upper()..word:sub(2)
end

local function parseArgs(s)
  local words = splitWords(s)
  local flags = {}
  local args = {}
  for _,w in ipairs(words) do
    if w:sub(1,1) == '-' then
      table.insert(flags, w)
    else
      table.insert(args, w)
    end
  end
  return args, flags
end

local function varargCallClosure(f)
  return
    function(args)
      if type(args) == 'table' and #args > 0 then
        for _,v in ipairs(args) do
          f(v)
        end
      else
        f(args)
      end
    end
end

-- cmds_n: table [subcmd_name -> f], with n = function arity
local function createSubCmdDispatcher(cmds0, cmds1, cmds2, cmds3)
  return
    function(cmd, arg1, arg2, arg3)
      if cmds3 and arg3 then
        local f = cmds3[cmd]
        if f ~= nil then
          return f(arg1, arg2, arg3)
        end
      end
      if arg3 then
        arg2 = arg2..' '..arg3
      end
      if cmds2 and arg2 then
        local f = cmds2[cmd]
        if f ~= nil then
          return f(arg1, arg2)
        end
      end
      if arg2 then
        arg1 = arg1..' '..arg2
      end
      if arg1 then
        local f = cmds1[cmd]
        if f ~= nil then
          return f(arg1)
        end
      end
      if not arg1 then
        local f = cmds0[cmd]
        if f ~= nil then
          return f()
        end
      end
      print('>>> sub cmd '..cmd..' mit diesen Parametern nicht auswertbar')
    end
end

-- cmds_n: table [subcmd_name -> f]
local function createSubCmdTabCompletion(cmds0, cmds1, cmds2, cmds3)
  local all_cmds = {}
  tableConcat(all_cmds, tableKeySet(cmds0))
  if cmds1 then tableConcat(all_cmds, tableKeySet(cmds1)) end
  if cmds2 then tableConcat(all_cmds, tableKeySet(cmds2)) end
  if cmds3 then tableConcat(all_cmds, tableKeySet(cmds3)) end
  table.sort(all_cmds)
  return function(arg)
    local cmds = {}
    for _,cmd in ipairs(all_cmds) do
      if cmd:sub(1,#arg) == arg then
        table.insert(cmds, cmd)
      end
    end
    return cmds
  end
end


return {
  tableConcat = tableConcat,
  tableJoin = tableJoin,
  subTable = subTable,
  listJoin = listJoin,
  listContains = listContains,
  listRemove = listRemove,
  listMap = listMap,
  listFilter = listFilter,
  splitString = splitString,
  splitWords = splitWords,
  capitalize = capitalize,
  parseArgs = parseArgs,
  varargCallClosure = varargCallClosure,
  createSubCmdDispatcher = createSubCmdDispatcher,
  createSubCmdTabCompletion = createSubCmdTabCompletion,
}
