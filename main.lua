
if blight then

  client = require 'blight.blight-adapter'
  require 'blight.blight-specific'
  require 'init'

else
  
  client = require 'tf.tf-adapter'
  require 'tf.tf-specific'

end

require 'init'
