
if blight then
  client = require 'client.blight.blight-adapter'
  require 'client.blight.blight-specific'
else
  local mg_lua_dir = os.getenv('MG_LUA_DIR')
  package.path = package.path..';'..mg_lua_dir..'/?.lua'
  local mg_custom_dir = os.getenv('MG_LUA_CUSTOM_DIR')
  if mg_custom_dir ~= nil then
    package.path = package.path..';'..mg_custom_dir..'/?.lua'
  end
  client = require 'client.tf.tf-adapter'
  require 'client.tf.tf-specific'
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
require 'utils.tools'
require 'utils-mg'
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

local guildClasses = {}

for _,guild in ipairs(allGuilds) do
  guildClasses[guild] = require('guild.'..guild)
end

local logger = client.createLogger('base')

base.registerEventHandler(
  'base.char.init.done',
  function()
    local guildName = base.charGuild()
    local guildClass = guildClasses[guildName]
    if guildClass ~= nil then
      local guild = guildClass()
      guild:enable()
      base.setGuild(guild)
      logger.info('Code zur Gilde \''..(guildName or '')..'\' aktiviert')
    end
  end
)
