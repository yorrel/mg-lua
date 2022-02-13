-- Basisfunktionalitaeten

-- die event listener von gmcp-data muessen zuerst geladen werden
local tools  = require 'tools'
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
    if string.sub(cmd,1,1) == '#' then
      cmd = string.gsub(cmd, ' ', ',')
      client.executeStandardAlias(cmd)
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
      logger.severe('Fehler bei Aufruf eines Handlers von event '..event..': '..err)
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

local char_state
local common_state

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
  logger.info('Charakterzustand von \''..filename..'\' eingelesen')
end

local function readCommonState()
  local filename = global_save_dir..'/common.json'
  common_state = readJsonFile(filename)
  logger.info('Gemeinsame Daten von \''..filename..'\' eingelesen')
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
  -- Code zur Gilde
  if pcall(require, 'guild/'..guild) then
    logger.info('Code zur Gilde \''..(guild or '')..'\' eingelesen')
  end
  raiseEvent('base.char.init.done')
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

local dirtyflag = false

local function setCommonPersistentTableDirty()
  dirtyflag = true
end

local function saveTable(filename, tableObject)
  local encoded = json.encode(tableObject)
  local f = io.open(filename, 'w')
  f:write(encoded)
  f:close()
  logger.info('file written: ' .. filename)
end

local function saveChar()
  saveTable(global_save_dir..'/'..character_name..'.json', char_state)
  if dirtyflag then
    dirtyflag = false
    saveTable(global_save_dir..'/common.json', common_state)
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
-- Helper: one-shot gag-trigger

local ignore_trigger = {}
local function gagNextLine(pattern, actual_line)
  if actual_line == nil or not string.find(actual_line, pattern, 1, true) then
    local id = ignore_trigger[pattern]
    if id == nil then
      id = client.createSubstrTrigger(
        pattern,
        function()
          local id_pattern = ignore_trigger[pattern]
          client.disableTrigger(id_pattern)
        end,
        {'g'}
      )
      ignore_trigger[pattern] = id
    else
      client.enableTrigger(id)
    end
  end
end


-- ---------------------------------------------------------------------------
-- standard funktionen
-- schaetz, identifiziere, leichen entsorgen

-- Objekt fuer gilden-Standardfunktionen:
-- Gilden koennen entsprechende Funktionen definieren
local gilde = {
  schaetz = nil,
  identifiziere = nil,
  entsorgeLeiche = 'streue pulver ueber leiche',
}


local function gilden_schaetz(objekt)
  local gildeSchaetz = gilde.schaetz or 'schaetz'
  if (type(gildeSchaetz) == 'function') then
    gilde.schaetz(objekt)
  else
    client.send(gildeSchaetz..' '..objekt)
  end
end

local function gilden_identifiziere(objekt)
  local gildeId = gilde.identifiziere or 'identifiziere'
  if (type(gildeId) == 'function') then
    gildeId(objekt)
  else
    client.send(gildeId..' '..objekt)
  end
end


local para = 0

local function set_para_welt(welt)
  logger.info('Setze Para-Welt: '..welt)
  para = tonumber(welt)
end


local status_ids = {}
local status_werte = {}
local status_key_supressed = {}

local function getGildenStatusLine()
  local status = ''
  for _,id in ipairs(status_ids) do
    if status ~= '' then
      status = status..'_'
    end
    local val = status_werte[id]
    if val == true then
      status = status..id
    else
      if status_key_supressed[id] then
        status = status..val
      else
        status = status..id..':'..val
      end
    end
  end
  return string.gsub(status, ' ', '_')
end

local function statusUpdate(id, optVal)
  status_werte[id] = optVal or true
  raiseEvent('gilde.statusline.update')
end

-- nur id: es wird 'id' angezeigt
-- mit val und ohne flag: Anzeige 'id:val'
-- mit val und mit flag: Anzeige 'val'
local function statusAdd(id, optVal, optShowValOnly)
  if not tools.listContains(status_ids, id) then
    status_ids[#status_ids+1] = id
  end
  status_key_supressed[id] = optShowValOnly
  statusUpdate(id, optVal)
end

local function statusRemove(id)
  status_werte[id] = nil
  status_key_supressed[id] = nil
  tools.listRemove(status_ids, id)
  raiseEvent('gilde.statusline.update')
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
client.createStandardAlias('para', 1, set_para_welt)


-- ---------------------------------------------------------------------------
-- module definition

return {
  initCharakter = initCharakter,
  keymap = keymap,
  eval = eval,
  dokey = dokey,
  registerEventHandler = registerEventHandler,
  raiseEvent = raiseEvent,
  gagNextLine = gagNextLine,
  getPersistentTable = getPersistentTable,
  getCommonPersistentTable = getCommonPersistentTable,
  setCommonPersistentTableDirty = setCommonPersistentTableDirty,
  gilde = gilde,
  statusAdd = statusAdd,
  statusUpdate = statusUpdate,
  statusRemove = statusRemove,
  getGildenStatusLine = getGildenStatusLine,
  addResetHook = addResetHook,
  charName = function() return character_name end,
  charGuild = function() return character_guild end,
  charRace = function() return character_race end,
  charWizlevel = function() return character_wizlevel end,
  para = function() return para end,
  setPara = set_para_welt,
}
