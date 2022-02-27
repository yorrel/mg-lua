-- Katzenkrieger

local base   = require 'base'
local kampf  = require 'battle'


-- ---------------------------------------------------------------------------
-- Guild class Katzenkrieger

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Katzenkrieger = class(Guild)

function Katzenkrieger:enable()
  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5   = kampf.createAttackFunctionWithEnemy('krallenschlag', 1)
  keymap.F6   = kampf.createAttackFunctionWithEnemy('blitz', 1)
  keymap.M_l = 'nachtsicht'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias('skills', 0, 'tm xelonir faehigkeiten')
end


return Katzenkrieger
