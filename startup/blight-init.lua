-- adapt and copy this file to $HOME/.config/blightmud/

-- (1) using script.load
script.load('path_to_mg_lua/mg-lua/main.lua')
script.load('path_to_mg_custom/mg-custom/main.lua')
script.load('path_to_worlds_mg/worlds_mg.lua')

-- (2) using blightmud plugin
--[[
plugin.add(url_mg_lua)
plugin.add(url_mg_custom)
plugin.update('mg-lua')
plugin.update('mg-custom')
plugin.load('mg-lua')
plugin.load('mg-custom')
script.load('path_to_worlds_mg/worlds_mg.lua')
]]
