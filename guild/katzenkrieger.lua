-- Katzenkrieger

local base   = require 'base'


-- ---------------------------------------------------------------------------
-- Guild class Katzenkrieger

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Katzenkrieger = class(Guild)

function Katzenkrieger:enable()
  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5   = Guild.attackFunWithEnemy('krallenschlag', 1)
  keymap.F6   = Guild.attackFunWithEnemy('blitz', 1)
  keymap.M_l = 'nachtsicht'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills', 0, function() client.send('tm xelonir faehigkeiten') end
  )
end


return Katzenkrieger
