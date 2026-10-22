-- Katzenkrieger

local base   = require 'base'


-- ---------------------------------------------------------------------------
-- Guild class Katzenkrieger

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Katzenkrieger = class(Guild)

function Katzenkrieger:enable()
  -- Lernerfolg
  self:createRegexTrigger('^Du lernst aus Deine(n Fehlern|m Erfolg)\\.$', nil, {'<magenta>'})

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5   = Guild.attackFunWithEnemy('blitz', 1)
  keymap.F6   = Guild.attackFunWithEnemy('wasserstrahl', 2)
  keymap.F7   = Guild.attackFunWithEnemy('winterhauch', 2)
  keymap.S_F8   = Guild.attackFunWithEnemy('krallenschlag', 1)
  keymap.F8   = Guild.attackFunWithEnemy('todeskralle', 2)
  keymap.M_a = 'ausweichen'
  keymap.M_d = 'ausweichen'
  keymap.M_e = 'schleichen'
  keymap.M_g = 'pflanzenfessel'
  keymap.M_l = 'nachtsicht'
  keymap.M_x = 'schnell'
  keymap.M_z = 'doese'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills', 0, function() client.send('tm xelonir faehigkeiten') end
  )
end


return Katzenkrieger
