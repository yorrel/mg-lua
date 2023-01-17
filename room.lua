-- room.lua - raumspezifische Funktionen
--
-- #room sub_cmd
--   name <name>      : globalen Namen für Raum setzen
--   alias -g <name>  : globalen Alias für den Raumnamen setzen
--   alias <name>     : Char-spezifischen Raum-Alias setzen
--   note <text>      : In-Game-Notizen
--   npc <name>       : Default-NPC
--   kraut <name>     : pflueckbares Kraut (M-6)
--   action1 <cmd>    : Aktion (M-5)
--   action2 <cmd>    : Aktion (M-6)
--   exit <dir> <cmd> : Kommando statt o/w/n/s/ob/u
--   fr <cmd>         : raumspezifische Fluchtrichtung

local base   = require 'base'
local ME     = require 'gmcp-data'
local tools  = require 'utils.tools'

local keymap = base.keymap
local logger = client.createLogger('room')


-- ---------------------------------------------------------------------------
-- common state - room specific properties

local function getOrCreateRoomProperties()
  local state = base.getCommonPersistentTable('room')
  local id = ME.raum_id
  state[id] = state[id] or {}
  return state[id]
end

local function setRoomProperty(key, val)
  local props = getOrCreateRoomProperties()
  props[key] = val
  base.setCommonPersistentTableDirty()
end

local function getRoomProperty(key)
  local state = base.getCommonPersistentTable('room')
  local props = state[ME.raum_id]
  if props == nil then
    return nil
  end
  return props[key]
end

local function getGlobalRoomAliases()
  return base.getCommonPersistentTable('room_alias')
end


-- ---------------------------------------------------------------------------
-- char specific state

local function charSpecificState()
  return base.getPersistentTable('room')
end

local function getPersonalRoomAliases()
  charSpecificState().aliases = charSpecificState().aliases or {}
  return charSpecificState().aliases
end

local function getRoomName()
  return getRoomProperty('wp')
end

local function roomAlias(args, flags)
  local alias = args[1]
  if not alias then
    logger.error('Aliasname muss angegeben werden!')
    return
  end
  local wegesystemState = charSpecificState()
  wegesystemState.aliases = wegesystemState.aliases or {}
  local global = tools.listContains(flags, '-g')
  local rm_flag = tools.listContains(flags, '-rm')
  if rm_flag then
    if global then
      local global_aliases = getGlobalRoomAliases()
      logger.info('Entferne globalen Alias '..alias)
      global_aliases[alias] = nil
      base.setCommonPersistentTableDirty()
    else
      logger.info('Entferne persoenlichen Alias '..alias)
      wegesystemState.aliases[alias] = nil
    end
    return
  end
  local wp = getRoomName()
  if wp == nil then
    logger.error('Aktueller Wegpunkt nicht bekannt!')
    return
  end
  if global then
    local global_aliases = getGlobalRoomAliases()
    global_aliases[alias] = wp
    logger.info('Setze globalen Alias '..alias..' fuer Wegpunkt '..wp)
    base.setCommonPersistentTableDirty()
  else
    wegesystemState.aliases[alias] = wp
    logger.info('Setze persoenlichen Alias '..alias..' fuer Wegpunkt '..wp)
  end
end


-- sorgt fuer alias-Ersetzung, alle von aussen kommenden Wegpunkte muessen ueber
-- diese Funktion ersetzt werden
local function getWegpunktNachAliasErsetzung(wp)
  local personal_aliases = getPersonalRoomAliases()
  local global_aliases = getGlobalRoomAliases()
  return personal_aliases[wp] or global_aliases[wp] or wp
end

local function getRoomIdForRoomName(wegpunkt)
  local state = base.getCommonPersistentTable('room')
  for raumId,props in pairs(state) do
    if wegpunkt == props['wp'] then
      return raumId
    end
  end
  return nil
end

-- Speichert die RaumId fuer den angegebenen Wegpunkt
local function saveRoomId(wp)
  if wp == nil then
    logger.info('Loesche Wegpunkt fuer aktuellen Raum!')
    setRoomProperty('wp', nil)
    return
  end
  -- RaumID zum Wegpunkt speichern
  local raumId = ME.raum_id
  local alterRaumName = getRoomName()
  local vorhandenerRaumMitWp = getRoomIdForRoomName(wp)
  if raumId == vorhandenerRaumMitWp then
    logger.info('Wegpunkt '..wp..' ist bereits fuer diesen Raum gesetzt.')
    return
  end
  if vorhandenerRaumMitWp ~= nil and raumId ~= vorhandenerRaumMitWp then
    logger.warn('Wegpunkt '..wp..' war bereits fuer Raum '..vorhandenerRaumMitWp..' gesetzt, entferne ihn dort!')
    base.getCommonPersistentTable('room')[vorhandenerRaumMitWp]['wp'] = nil
  end
  if alterRaumName ~= wp then
    setRoomProperty('wp', wp)
    if alterRaumName == nil then
      logger.info('Raum '..raumId..' hat jetzt Wegpunkt '..wp)
    else
      logger.warn('Raum '..raumId..' hat jetzt Wegpunkt '..wp..' (vorher '..alterRaumName..')!')
    end
  end
end

local function roomName(args, flags)
  if flags[1] == '-rm' then
    saveRoomId(nil)
  else
    saveRoomId(args[1])
  end
end


-- ausloggen der RaumIds aktivieren
local boolean logRoomIdsAktiv = false
local function logRoomIds()
  if not logRoomIdsAktiv then
    logRoomIdsAktiv = true
    base.registerEventHandler(
      'gmcp.MG.room.info',
      function()
        logger.info('Raum: ' .. (ME.raum_id or ''))
      end
    )
  end
end

local function args2lines(args)
  local s = tools.listJoin(args, ' ')
  local lines = tools.splitString(s, ';')
  return lines
end


-- ---------------------------------------------------------------------------
-- room default npc

local function getRoomNPC()
  return getRoomProperty('npc')
end

local function roomNPC(args, flags)
  if flags[1] == '-rm' then
    setRoomProperty('npc', nil)
  else
    local npc = tools.listJoin(args, ' ')
    setRoomProperty('npc', npc)
  end
end


-- ---------------------------------------------------------------------------
-- room label

local function getRoomLabel()
  return getRoomProperty('label')
end

local function roomLabel(args, flags)
  if flags[1] == '-rm' then
    setRoomProperty('label', nil)
  else
    setRoomProperty('label', args[1])
  end
end


-- ---------------------------------------------------------------------------
-- room specific escape cmd

local function getRoomEscape()
  return getRoomProperty('fr')
end

local function roomEscape(args, flags)
  if flags[1] == '-rm' then
    setRoomProperty('fr', nil)
  else
    local lines = args2lines(args)
    if #lines > 0 then
      setRoomProperty('fr', lines)
    end
  end
end


-- ---------------------------------------------------------------------------
-- room specific exits

local function getRoomSpecificExit(dir)
  local exitTable = getRoomProperty('e')
  if exitTable ~= nil then
    return exitTable[dir]
  else
    return nil
  end
end

local function getRoomExitsView()
  local exitTable = getRoomProperty('e')
  if exitTable == nil then
    return nil
  end
  local v = ''
  for dir,cmd in pairs(exitTable) do
    if v ~= '' then
      v = v..'+'
    end
    v = v..dir
  end
  return v
end

local function roomExit(args, flags)
  if flags[1] == '-rm' then
    setRoomProperty('e', nil)
  else
    local exitTable = getRoomProperty('e')
    if exitTable == nil then
      exitTable = {}
      setRoomProperty('e', exitTable)
    end
    local dir = table.remove(args, 1)
    local cmd = tools.listJoin(args, ' ')
    exitTable[dir] = cmd
    base.setCommonPersistentTableDirty()
  end
end


-- ---------------------------------------------------------------------------
-- in-game room notes

local function getRoomNotes()
  return getRoomProperty('n')
end

local function roomNotes(args, flags)
  if flags[1] == '-rm' then
    setRoomProperty('n', nil)
  else
    local lines = args2lines(args)
    if #lines > 0 then
      setRoomProperty('n', lines)
    end
  end
end


-- ---------------------------------------------------------------------------
-- room specific actions

local function getRoomActions(nr)
  return getRoomProperty(nr)
end

local function execActions(nr)
  local actions = getRoomProperty(nr)
  if actions ~= nil then
    base.eval(actions)
  else
    logger.info('Keine Raumaktion fuer diesen Raum vorhanden.')
  end
end

local function executeRoomActions1()
  execActions('a1')
end

local function executeRoomActions2()
  execActions('a2')
end

local function roomActions(nr, args, flags)
  if flags[1] == '-rm' then
    setRoomProperty(nr, nil)
  else
    local lines = args2lines(args)
    if #lines > 0 then
      setRoomProperty(nr, lines)
    end
  end
end


-- ---------------------------------------------------------------------------
-- room herb

local function getRoomHerb()
  return getRoomProperty('k')
end

local function roomHerb(args, flags)
  if flags[1] == '-rm' then
    setRoomProperty('k', nil)
  else
    local kraut = tools.listJoin(args, ' ')
    setRoomProperty('k', kraut)
  end
end


-- ---------------------------------------------------------------------------
-- Room-Info-Ausgabe

local function addRoomInfoHelper(msg, key, data)
  if data ~= nil then
    if msg:len() > 0 then msg = msg .. ' / ' end
    local data_string = data
    if type(data) == 'table' then
      data_string = tools.listJoin(data, '; ')
    end
    msg = msg .. key .. ': ' .. data_string
  end
  return msg
end

local function roomInfo()
  local msg = ''
  local wp = getRoomName()
  if wp ~= nil then
    msg = 'WP \''..wp..'\''
  end
  msg = addRoomInfoHelper(msg, 'FR', getRoomEscape())
  msg = addRoomInfoHelper(msg, 'A1', getRoomActions('a1'))
  msg = addRoomInfoHelper(msg, 'A2', getRoomActions('a2'))
  msg = addRoomInfoHelper(msg, 'K', getRoomHerb())
  msg = addRoomInfoHelper(msg, 'N', getRoomNotes())
  msg = addRoomInfoHelper(msg, 'E', getRoomExitsView())
  if msg:len() > 0 then
    logger.info(msg)
  end
end

base.registerEventHandler('gmcp.MG.room.info', roomInfo)


local function showStatus()
  local msg = 'Region: '..ME.raum_region..' / Raum-Id: '..(ME.raum_id_short or '')
  local label = getRoomLabel()
  if label ~= nil then
    msg = msg..' / Label: '..label
  end
  logger.info(msg)
  local notizen = getRoomNotes()
  if notizen ~= nil then
    local notizenMsg = addRoomInfoHelper('', 'Notiz', notizen)
    logger.info(notizenMsg)
  end
end


-- ---------------------------------------------------------------------------
-- Keys

keymap.M_5 = executeRoomActions1
keymap.M_6 = executeRoomActions2


-- ---------------------------------------------------------------------------
-- Aliases

local room_sub_cmds = {
  name = roomName,
  alias = roomAlias,
  exit = roomExit,
  fr = roomEscape,
  npc = roomNPC,
  label = roomLabel,
  note = roomNotes,
  action1 = function(args, flags) roomActions('a1', args, flags) end,
  action2 = function(args, flags) roomActions('a2', args, flags) end,
  kraut = roomHerb,
  log = logRoomIds,
}

client.createStandardAlias(
  'room',
  1,
  function(s)
    local args, flags = tools.parseArgs(s)
    local cmd = table.remove(args, 1) or ''
    local sub_cmd = room_sub_cmds[cmd]
    if not sub_cmd then
      logger.error('unbekanntes Subcommand '..cmd)
      return
    end
    sub_cmd(args, flags)
  end,
  function(arg)
    local cmds = {}
    for cmd,_ in pairs(room_sub_cmds) do
      if cmd:sub(1,#arg) == arg then
        table.insert(cmds, cmd)
      end
    end
    return cmds
  end
)


-- ---------------------------------------------------------------------------
-- module definition

return {
  getWegpunktNachAliasErsetzung = getWegpunktNachAliasErsetzung,
  getRoomName = getRoomName,
  execAction1 = executeRoomActions1,
  execAction2 = executeRoomActions2,
  getCmdForExit = getRoomSpecificExit,
  getEscape = getRoomEscape,
  getHerb = getRoomHerb,
  getLabel = getRoomLabel,
  getNPC = getRoomNPC,
  showStatus = showStatus,
}
