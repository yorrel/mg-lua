-- Basisfunktionalitaeten

-- die event listener von gmcp-data muessen zuerst geladen werden
local tools  = require 'utils.tools'
local json   = client.json

local logger = client.createLogger('base')


-- ---------------------------------------------------------------------------
-- universal eval method (text / functions / standard aliases)

local function eval(cmd)
  if type(cmd) == 'table' then
    for _,c in pairs(cmd) do
      eval(c)
    end
  elseif type(cmd) == 'function' then
    cmd()
  elseif type(cmd) == 'string' then
    if cmd:sub(1,1) == '#' then
      local index = cmd:find(' ')
      local aliasName = index and cmd:sub(1, index-1) or cmd
      local paramString = index and cmd:sub(index+1)
      client.executeStandardAlias(aliasName, paramString)
    else
      client.send(cmd)
    end
  end
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
  logger.debug('raise event '..event)
  local allHandler = handler[event] or {}
  for _,f in pairs(allHandler) do
    logger.debug('event handler aufrufen fuer event '..event)
    local ok, err = pcall(f)
    if not ok then
      logger.error('Fehler bei Aufruf eines Handlers von event '..event..': '..err)
    end
  end
end


-- ---------------------------------------------------------------------------
-- charakterspezifische Tastenbelegung
--
-- Konfiguration:
-- keymap.<key> = [string|function]
-- keycodes : F1, S_F1, C_a, M_a

local keymap = {}

local function dokey(id)
  id = string.gsub(id, '[-]', '_')
  local binding = keymap[id]
  if binding == nil then
    logger.info('key '..id)
  else
    eval(binding)
  end
end

client.useKeyListener(dokey)

-- ---------------------------------------------------------------------------
-- Persistence

local global_save_dir = MG_LUA_SAVE_DIR or os.getenv('MG_LUA_SAVE_DIR')

local saveFiles = {}

-- contentProvider - returns String, nil means "do not save"
local function registerSaveFile(filename, contentProvider)
  saveFiles[filename] = contentProvider
end

local function readSaveFile(filename)
  local fullname = global_save_dir..'/'..filename
  local f = io.open(fullname, 'r')
  if f then
    local content = f:read('*all')
    f:close()
    return content
  end
  return nil
end

local function save(filename, contentProvider)
  local content = contentProvider()
  if content ~= nil then
    local fullname = global_save_dir..'/'..filename
    local f = io.open(fullname, 'w')
    f:write(content)
    f:close()
    logger.info('file written: ' .. fullname)
  end
end

local function persistSaveFile(filename)
  for name,contentProvider in pairs(saveFiles) do
    if name == filename then
      save(name, contentProvider)
      return
    end
  end
end

local function saveChar()
  for filename,contentProvider in pairs(saveFiles) do
    save(filename, contentProvider)
  end
end

local char_state
local common_state
local common_dirty_flag = false

local function readFile(filename)
  local f = assert(io.open(filename, 'r'))
  local content = f:read('*a')
  f:close()
  return content
end

local function readJsonFile(filename)
  local content = readFile(filename)
  return json.decode(content)
end

local function readCharState(name)
  local filename = global_save_dir..'/'..name..'.json'
  char_state = readJsonFile(filename)
  logger.info('Charakterzustand \''..filename..'\' eingelesen')
end

local function readCommonState()
  local filename = global_save_dir..'/common.json'
  common_state = readJsonFile(filename)
  logger.info('Gemeinsame Daten \''..filename..'\' eingelesen')
end

local function registerStandardSaveFiles(name)
  registerSaveFile(
    name..'.json',
    function()
      return json.encode(char_state)
    end
  )
  registerSaveFile(
    'common.json',
    function()
      if common_dirty_flag then
        common_dirty_flag = false
        return json.encode(common_state)
      else
        return nil
      end
    end
  )
end


local function getPersistentTable(id)
  char_state = char_state or {}
  char_state[id] = char_state[id] or {}
  return char_state[id]
end

local function getCommonPersistentTable(id)
  common_state = common_state or {}
  common_state[id] = common_state[id] or {}
  return common_state[id]
end

local function setCommonPersistentTableDirty()
  common_dirty_flag = true
end


local character_name
local character_guild
local character_wizlevel
local character_race

local charakterInitialisiert = false

local function initCharakter(name, guild, race, wizlevel)
  if charakterInitialisiert then
    return
  end
  charakterInitialisiert = true
  -- window title
  client.xtitle(name..' ('..tools.capitalize(guild)..', '..race..')')
  -- base vars
  character_name = name
  character_guild = guild
  character_race = race
  character_wizlevel = wizlevel
  -- Zustand vom Charakter einlesen
  pcall(readCharState, name)
  -- Charakter-uebergreifende Daten einlesen
  pcall(readCommonState)
  registerStandardSaveFiles(name)
  raiseEvent('base.char.init.done')
  if getPersistentTable('base').logfile then
    client.startLog(name)
  end
end


local function save_and_sleep()
  saveChar()
  if character_wizlevel == 1 then
    client.send('guthaben')
  end
  client.send('schlaf ein')
end


-- ---------------------------------------------------------------------------
-- standard funktionen
-- schaetz, identifiziere, leichen entsorgen

-- Guild Object
local gilde

local function gilden_schaetz(objekt)
  gilde:schaetz(objekt)
end

local function gilden_identifiziere(objekt)
  gilde:identifiziere(objekt)
end


local para = 0

local function set_para_welt(welt)
  logger.info('Setze Para-Welt: '..welt)
  para = tonumber(welt)
end


local status_config = ''
local attribute_length = {}
local attribute_values = {}

-- arg: config string with attribute definitions '...{name:4}...'
local function statusConfig(conf)
  status_config = string.gsub(
    conf,
    '({%a+:%d+})',
    function(attr)
      local index = string.find(attr, ':')
      local key = attr:sub(2, index-1)
      local length = attr:sub(index+1, -2)
      attribute_length[key] = tonumber(length)
      return '{'..key..'}'
    end
  )
end

-- args: list of lists { id, val }
local function statusUpdate(...)
  for _,entry in ipairs{...} do
    local attr = entry[1]
    local val = entry[2]
    attribute_values[attr] = val
  end
  raiseEvent('statusline.gilde.update')
end

local function getStatusValue(key)
  return attribute_values[key]
end

local function getGildenStatusLine()
  return string.gsub(
    status_config,
    '{(%a+)}',
    function(key)
      local val = attribute_values[key] or ''
      local len = attribute_length[key] or 1
      return string.format('%-'..len..'s', val)
    end
  )
end

local roomFlagFunction = function() return nil end

local function roomFlag()
  return roomFlagFunction()
end

local function setRoomFlagFunction(f)
  roomFlagFunction = f
end

-- ---------------------------------------------------------------------------
-- auto logfile on/off

local function toggleAutoLogFile()
  local s = getPersistentTable('base')
  s.logfile = not s.logfile
  if s.logfile then
    logger.info('Starte kuenftig automatisch das Loggen ins Logfile')
    client.startLog(character_name)
  else
    logger.info('Erzeuge kuenftig kein Logfile mehr')
    client.stopLog()
  end
end


-- ---------------------------------------------------------------------------
-- Reboot / Reset

local resetHooks = {}

local function reboot()
  for _,f in ipairs(resetHooks) do
    eval(f)
  end
end

local function addResetHook(f)
  resetHooks[#resetHooks+1] = f
end


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('reboot',  0, reboot)
client.createStandardAlias('s',  1, gilden_schaetz)
client.createStandardAlias('i',  1, gilden_identifiziere)
client.createStandardAlias('se', 0, save_and_sleep)
client.createStandardAlias('save', 0, saveChar)
client.createStandardAlias('para', 1, set_para_welt)
client.createStandardAlias('log', 0, toggleAutoLogFile)


-- ---------------------------------------------------------------------------
-- module definition

return {
  initCharakter = initCharakter,
  keymap = keymap,
  eval = eval,
  dokey = dokey,
  registerEventHandler = registerEventHandler,
  raiseEvent = raiseEvent,
  getPersistentTable = getPersistentTable,
  getCommonPersistentTable = getCommonPersistentTable,
  setCommonPersistentTableDirty = setCommonPersistentTableDirty,
  registerSaveFile = registerSaveFile,
  readSaveFile = readSaveFile,
  persistSaveFile = persistSaveFile,
  setGuild = function(g) gilde = g end,
  gilde = function() return gilde end,
  statusConfig = statusConfig,
  statusUpdate = statusUpdate,
  getStatusValue = getStatusValue,
  getGildenStatusLine = getGildenStatusLine,
  roomFlag = roomFlag,
  setRoomFlagFunction = setRoomFlagFunction,
  addResetHook = addResetHook,
  charName = function() return character_name end,
  charGuild = function() return character_guild end,
  charRace = function() return character_race end,
  charWizlevel = function() return character_wizlevel end,
  para = function() return para end,
  setPara = set_para_welt,
}
