-- Urukhai

local base   = require 'base'


-- ---------------------------------------------------------------------------
-- Guild class Urukhai

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Urukhai = class(Guild)

function Urukhai:enable()
  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5 = Guild.attackFunWithEnemy('beisse')
  keymap.F6 = Guild.attackFunWithEnemy('ruelpse')
  keymap.F7 = Guild.attackFunWithEnemy('spucke')

  keymap.M_l = 'nachtsicht'
  keymap.M_v = 'steinhaut'
  keymap.M_x = 'wirbelwind'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills', 0, function() client.send('tm hragznor faehigkeiten') end
  )
end

return Urukhai
