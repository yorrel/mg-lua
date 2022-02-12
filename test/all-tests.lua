
local home = os.getenv("HOME")
package.path = package.path..";"..home.."/work/mg-lua/test/?.lua"

local tools_test = require "tools-test"
tools_test.run()

local reduce_test = require "reduce-test"
reduce_test.run()

local reduce_inttest = require "reduce-inttest"
reduce_inttest.run()
