
if blight then
  client = require 'blight.blight-adapter'
  require 'blight.blight-specific'
else
  local mg_lua_dir = os.getenv('MG_LUA_DIR')
  package.path = package.path..';'..mg_lua_dir..'/?.lua'
  local mg_custom_dir = os.getenv('MG_LUA_CUSTOM_DIR')
  if mg_custom_dir ~= nil then
    package.path = package.path..';'..mg_custom_dir..'/?.lua'
  end
  client = require 'tf.tf-adapter'
  require 'tf.tf-specific'
end

local base = require 'base'
require 'battle'
require 'damage'
require 'gmcp-data'
require 'guild.common'
require 'inventory'
require 'itemdb'
require 'pub'
require 'reduce'
require 'report'
require 'room'
require 'timer'
require 'tools'
require 'utils'
require 'ways'
require 'ways-extensions'


local allGuilds = {
  'bierschuettler',
  'chaos',
  'common',
  'dunkelelfen',
  'kaempfer',
  'karate',
  'katzenkrieger',
  'klerus',
  'tanjian',
  'urukhai',
  'zauberer'
}

local guildModules = {}

for _,guild in ipairs(allGuilds) do
  guildModules[guild] = require('guild/'..guild)
end

local logger = client.createLogger('base')

base.registerEventHandler(
  'base.char.init.done',
  function()
    guildModules[base.charGuild()].enable()
    logger.info('Code zur Gilde \''..(guild or '')..'\' aktiviert')
  end
)
