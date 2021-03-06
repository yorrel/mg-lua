
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
}
