-- Urukhai

local base   = require 'base'
local kampf  = require 'battle'


-- ---------------------------------------------------------------------------
-- module definition

local function enable()
  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5 = kampf.createAttackFunctionWithEnemy('beisse')
  keymap.F6 = kampf.createAttackFunctionWithEnemy('ruelpse')
  keymap.F7 = kampf.createAttackFunctionWithEnemy('spucke')

  keymap.M_l = 'nachtsicht'
  keymap.M_v = 'steinhaut'
  keymap.M_x = 'wirbelwind'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias('skills', 0, 'tm hragznor faehigkeiten')
end


return {
  enable = enable
}
