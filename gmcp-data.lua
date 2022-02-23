
local base  = require 'base'
local json   = client.json

local ME = {}


-- default-Werte
ME.name = 'Jemand'
ME.level = 0
ME.guild_level = 0
ME.vorsicht = 0
ME.fluchtrichtung = ''
ME.lp_alt = 0
ME.wizlevel = 0


local function process_MG_char_base(s)
  local data = json.decode(s)
  ME.name  = data.name
  ME.guild = data.guild
  ME.race = data.race
  ME.wizlevel = data.wizlevel
  base.initCharakter(ME.name, ME.guild, ME.race, ME.wizlevel)
  base.raiseEvent('gmcp.MG.char.base')
end

local function process_MG_char_info(s)
  local data = json.decode(s)
  ME.level = data.level
  ME.guild_level = data.guild_level
  base.raiseEvent('gmcp.MG.char.info')
end

local function process_MG_char_maxvitals(s)
  local data = json.decode(s)
  ME.lp_max = data.max_hp
  ME.kp_max = data.max_sp or 0
  base.raiseEvent('gmcp.MG.char.maxvitals')
end

local function process_MG_char_vitals(s)
  local data = json.decode(s)
  ME.lp   = data.hp
  ME.kp   = data.sp or 0
  ME.gift = data.poison or 0
  base.raiseEvent('gmcp.MG.char.vitals')
end

local function process_MG_char_wimpy(s)
  local data = json.decode(s)
  ME.vorsicht       = data.wimpy or 0
  ME.fluchtrichtung = data.wimpy_dir or ''
  base.raiseEvent('gmcp.MG.char.wimpy')
end

local function process_MG_room_info(s)
  local data = json.decode(s)
  ME.raum_kurz     = data.short
  ME.raum_region   = data.domain
  ME.raum_id       = data.id
  ME.raum_exits    = data.exits
  ME.raum_id_short = string.sub(data.id, 1, 5)
  base.raiseEvent('gmcp.MG.room.info')
end

ME.accept = {}
ME.accept['MG.char.base'] = process_MG_char_base
ME.accept['MG.char.info'] = process_MG_char_info
ME.accept['MG.char.maxvitals'] = process_MG_char_maxvitals
ME.accept['MG.char.vitals'] = process_MG_char_vitals
ME.accept['MG.char.wimpy'] = process_MG_char_wimpy
ME.accept['MG.room.info'] = process_MG_room_info

return ME
