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
  keymap.F8 = Guild.attackFunWithEnemy('hammerfaust')

  keymap.M_g = Guild.attackFunWithEnemy('furcht')
  keymap.M_j = 'riesenpranke'
  keymap.M_k = 'trollstaerke'
  keymap.M_l = 'nachtsicht'
  keymap.M_r = 'leichenfledder'
  keymap.M_v = 'steinhaut'
  keymap.M_x = 'wirbelwind'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills', 0, function() client.send('tm hragznor faehigkeiten') end
  )
end

return Urukhai
