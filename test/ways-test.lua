
local ws     = require 'ways'

local wegdef = ws.def
local wegdefx = ws.defx

wegdefx('zwerge_sp', 'p4', '/dopath n w 3 n w')
wegdefx('p4', 'ssp', '/dopath w 3 n nw 3 ob')

local expected = {
  'ultrakurz',
  'u','u','u','so','s','s','s','o',
  'o','s','s','s','o','s',
  'lang'
}

local function runTests()
  client.resetMudOutput()
  client.testExecuteStandardAlias('go', 2, 'ssp', 'zwerge_sp')
  local cmds = client.getMudOutput()
  assert(#expected == #cmds)
  for i=1,#cmds do
    assert(expected[i] == cmds[i])
  end
end

return {
  run = runTests
}
