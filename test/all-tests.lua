
client = require 'test.mock-client'

local tools_test = require 'test.tools-test'
tools_test.run()

local ways_test = require 'test.ways-test'
ways_test.run()

local reduce_test = require 'test.reduce-test'
reduce_test.run()

local reduce_inttest = require 'test.reduce-inttest'
reduce_inttest.run()
