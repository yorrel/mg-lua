
local tools = require "tools"


local function test()
  local t1 = tools.splitString("a b c d", " ")
  assert("a,b,c,d" == table.concat(t1, ","))

  local t2 = tools.splitString("abbb bc cdd de", " ")
  assert("abbb,bc,cdd,de" == table.concat(t2, ","))

  local t3 = tools.splitString(" a b c d ", " ")
  assert(",a,b,c,d" == table.concat(t3, ","))

  local t4 = tools.splitString("std_11", "#")
  assert(1 == #t4)
  assert("std_11" == t4[1])

  local t5 = tools.splitString(" a  b c  d ", " ")
  assert(",a,,b,c,,d" == table.concat(t5, ","))


  local w1 = tools.splitWords(" a  b c  d", " ")
  print(table.concat(w1, ","))
  assert("a,b,c,d" == table.concat(w1, ","))
end


return {
  run = test
}
