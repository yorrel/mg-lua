-- Urukhai

local base   = require 'base'
local kampf  = require 'battle'


-- ---------------------------------------------------------------------------
-- Guild class Urukhai

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Urukhai = class(Guild)

function Urukhai:enable()
  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5 = kampf.createAttackFunctionWithEnemy('beisse')
  keymap.F6 = kampf.createAttackFunctionWithEnemy('ruelpse')
  keymap.F7 = kampf.createAttackFunctionWithEnemy('spucke')

  keymap.M_l = 'nachtsicht'
  keymap.M_v = 'steinhaut'
  keymap.M_x = 'wirbelwind'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills', 0, function() client.send('tm hragznor faehigkeiten') end
  )
end

return Urukhai
