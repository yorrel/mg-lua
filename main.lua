
if blight then

  client = require 'blight.blight-adapter'
  require 'blight.blight-specific'

else
  
  client = require 'tf.tf-adapter'
  require 'tf.tf-specific'

end

require 'base'
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
