
local reduce = require "reduce"


local function test()
  assert("Matrix ganz ohne colon" == reduce.substring_ab("Matrix ganz ohne colon", ": "))
  assert("foobar" == reduce.substring_ab("Matrix: foobar", ": "))

  assert("Mgka" == reduce.karatekuerzen("Mae-geri-keage"))
  assert("Motsu" == reduce.karatekuerzen("Morote-tsukami-uke"))
  assert("FggBb" == reduce.karatekuerzen("Fabusi-genomo-geronimo-Blafasel-basba"))
  
  assert('Vampirsc' == reduce.namekuerzen("dem Vampirschwert", 8))
  assert('Vampirsc' == reduce.namekuerzen("Vampirschwert", 8))
  assert('Vampirschwer' == reduce.namekuerzen("Vampirschwert", 12))
  assert('Vampirsc' == reduce.namekuerzen("demVampirschwert", 8))
  assert('Stab der Elf', reduce.namekuerzen("dem heiligen Stab der Elfen", 12))

  assert('Nasir' == reduce.genitiv_loeschen("Nasirs"))
  assert('Nasirs' == reduce.genitiv_loeschen("Nasirs'"))
  assert('Nasir' == reduce.genitiv_loeschen("Nasir"))
  assert("Na'sir" == reduce.genitiv_loeschen("Na'sir"))
end


return {
  run = test
}
