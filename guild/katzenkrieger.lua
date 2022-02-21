-- Katzenkrieger

local base   = require 'base'
local kampf  = require 'battle'

local keymap = base.keymap


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.F5   = kampf.createAttackFunctionWithEnemy('krallenschlag', 1)
keymap.F6   = kampf.createAttackFunctionWithEnemy('blitz', 1)

keymap.M_l = 'nachtsicht'


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('skills', 0, 'tm xelonir faehigkeiten')
