-- Urukhai

local base   = require 'base'
local inv    = require 'inventory'
local kampf  = require 'battle'

local logger = client.createLogger('urukhai')
local keymap = base.keymap


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.F5 = kampf.createAttackFunctionWithEnemy('beisse')
keymap.F6 = kampf.createAttackFunctionWithEnemy('ruelpse')
keymap.F7 = kampf.createAttackFunctionWithEnemy('spucke')

keymap.M_l = 'nachtsicht'
keymap.M_v = 'steinhaut'
keymap.M_x = 'wirbelwind'


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('skills', 0, 'tm hragznor faehigkeiten')
