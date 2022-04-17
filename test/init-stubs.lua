
local home = os.getenv("HOME")
package.path = package.path..";"..home.."/work/mg-lua/lua/?.lua"


-- ---------------------------------------------------------------------------
-- Logging

local function debug(komponente, msg)
  print("DEBUG "..komponente.." "..msg)
end

local function info(komponente, msg)
  print("INFO  "..komponente.." "..msg)
end

local function warn(komponente, msg)
  print("WARN  "..komponente.." "..msg)
end

local function error(komponente, msg)
  print("ERROR "..komponente.." "..msg)
end

local function line()
  print("------------------------------------------------------------")
end

local function createLogger(komponente)
  local kmp = "["..string.sub(komponente,1,5).."]"
  kmp = kmp..string.sub("     ",1,7-#kmp)
  return {
    debug = function(msg) debug(kmp,msg) end,
    info = function(msg) info(kmp,msg) end,
    warn = function(msg) warn(kmp,msg) end,
    error = function(msg) error(kmp,msg) end,
  }
end


-- ---------------------------------------------------------------------------
-- Events

local handler = {}

local function registerEventHandler(event, f)
  local eventHandler = handler[event]
  if eventHandler == nil then
    eventHandler = {}
    handler[event] = eventHandler
  end
  eventHandler[#eventHandler+1] = f
end

local function raiseEvent(event)
  local allHandler = handler[event] or {}
  for _,f in pairs(allHandler) do
    pcall(f)
  end
end


-- ---------------------------------------------------------------------------
-- Aliases

local alias_ids = alias_ids or {}
local alias_cmds = alias_cmds or {}


function _executeAliasCmd(name, n, matches)
  local aliasId = name.."~"..n
  local cmd = alias_cmds[aliasId]
  -- matches[2] ist der erste match
  cmd(matches[2],matches[3],matches[4],matches[5],matches[6],matches[7],matches[8],matches[9])
end

-- Standard-Alias mit n Pflicht-Parametern erzeugen.
-- bei Eingabe von #name p1 ... pn wird f(p1,...,pn) aufgerufen
-- name~n muss eindeutig sein
-- return aliasID
local function createStandardAlias(name, n, f)
  local aliasId = name.."~"..n
  alias_cmds[aliasId] = f
  return "dummy"
end


-- ---------------------------------------------------------------------------
-- stub standard functions

local nop = function() end

local function send(...)
  for _,msg in ipairs{...} do
    print("[2MUD]   "..msg)
  end
end

local function eval(cmd)
  if type(cmd) == "function" then
    cmd()
  elseif type(cmd) == "string" then
    send(cmd)
  end
end


client = {
  createLogger = createLogger,
  line = line,
  echo = print,
  cecho = print,
  registerEventHandler = registerEventHandler,
  raiseEvent = raiseEvent,
  createStandardAlias = createStandardAlias,
  createSubstrTrigger = nop,
  createRegexTrigger = nop,
  createMultiLineRegexTrigger = nop,
  enableTrigger = nop,
  disableTrigger = nop,
  killTrigger = nop,
  createTimer = nop,
  send = send,
  eval = eval,
  xtitle = nop,
}


-- ---------------------------------------------------------------------------
-- common stuff + Testcharakter

require "init"
local char  = require "base"

char.ME.name  = "Snert"
char.ME.gilde = "karate"
char.ME.raum_id = "bff5364155f609ff15992cb3572ed6d5"
char.ME.raum_id_short = "bff53"
char.ME.raum_region = "Seher"
raiseEvent("gmcp.MG.char.base")


-- ---------------------------------------------------------------------------
-- utility Funktionen zum Simulieren von Aliases usw.

function execAlias(name, arg1, arg2, arg3, arg4, arg5)
  local matches = { "#"..name, arg1, arg2, arg3, arg4, arg5 }
  print("size of matches is: "..#matches)
  _executeAliasCmd(name, #matches-1, matches)
end


-- ---------------------------------------------------------------------------
-- debug-Einstellungen

-- bekannte raumIds von wegpunkten loeschen
local wegpunkte = char.getCommonPersistentTable("wegpunkte")
for k,v in pairs(wegpunkte) do
  wegpunkte[k] = nil
end
