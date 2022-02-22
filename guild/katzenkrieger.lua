-- Katzenkrieger

local base   = require 'base'
local kampf  = require 'battle'


-- ---------------------------------------------------------------------------
-- module definition

local function enable()
  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5   = kampf.createAttackFunctionWithEnemy('krallenschlag', 1)
  keymap.F6   = kampf.createAttackFunctionWithEnemy('blitz', 1)
  keymap.M_l = 'nachtsicht'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias('skills', 0, 'tm xelonir faehigkeiten')
end


return {
  enable = enable
}
