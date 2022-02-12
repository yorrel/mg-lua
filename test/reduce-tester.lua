
local reduce = require "reduce"

-- ---------------------------------------------------------------------------
-- framework
-- ---------------------------------------------------------------------------

local tests = {}
local tests_error = {}
local tests_running = {}

local function msg(m)
  client.cecho(m)
end

local function msgError(m)
  tests_error[#tests_error+1] = m
end

-- test definition with fluent api
local function test(name)
  local test = {}
  test.name = name
  tests[#tests+1] = test
  return {
    onTrigger =
      function(...)
        test.trigger =  {...}
        return {
          expect =
            function(s)
              test.expect = s
            end
        }
      end
  }
end

local function run_test(test)
  tests_running[#tests_running+1] = test
  for _,s in ipairs(test.trigger) do
    tf_eval('/trigger "'..s..'"')
  end
end

local function create_test_report()
  if #tests_error > 0 then
    msg('@{Cred}TESTS ERRORS@{n}')
    for _,m in ipairs(tests_error) do
      msg(m)
    end
  else
    msg('@{Cgreen}tests ok@{n}')
  end
end

local index_run = 1
local function reduce_output_listener(actual)
  local output_raw = string.gsub(actual, '@{%w*}', '')
  local test = tests_running[index_run]
  local name = test.name
  local expect = test.expect
  if output_raw == expect then
    msg('\n@{Cgreen}(+)@{n} '..name)
  else
    msgError('\n@{Cred}(-)@{n} '..name)
    msgError('e='..expect)
    msgError('a='..(output_raw or 'nil'))
  end
  index_run = index_run + 1
end

local count = 1
local function runAllTests()
  count = 1
  index_run = 1
  reduce.setOutputListener(reduce_output_listener)
  tests_error = {}
  for _,test in pairs(tests) do
    msg("running test " .. count .. "/" .. #tests .. ": " .. test.name)
    count = count + 1
    run_test(test)
  end
  create_test_report()
end


-- ---------------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------------

return {
  test = test,
  run = runAllTests
}
