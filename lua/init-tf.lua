local mg_lua_dir = os.getenv('MG_LUA_DIR')
package.path = package.path..';'..mg_lua_dir..'/lua/?.lua'

local mg_custom_dir = os.getenv('MG_LUA_CUSTOM_DIR')
if mg_custom_dir ~= nil then
  package.path = package.path..';'..mg_custom_dir..'/lua/?.lua'
end

client = require 'tf.tf-adapter'
require 'tf.tf-specific'
require 'init'
