-- Bierschuettler

local ME     = require 'gmcp-data'
local base   = require 'base'
local inv    = require 'inventory'
local pub    = require 'pub'
local room   = require 'room'
local timer  = require 'timer'
local kampf  = require 'battle'

local logger = client.createLogger('bierschuettler')
local keymap = base.keymap


pub.setOrderCmd(
  function(id)
    local cmd = room.getLabel() == 'bkneipe' and 'bkaufe' or 'bestelle'
    client.send(cmd..' '..id)
  end
)


-- schuettelstarre
client.createRegexTrigger(
  ME.name .. ' starrt .* an\\.',
  function()
    timer.enqueue(
      150,
      function()
        logger.info('schuettelstarre wieder moeglich (2:30 min um)')
      end
    )
  end,
  {'<blue>'}
)


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

base.gilde.info = nil
base.gilde.schaetz = 'beobachte'
base.gilde.identifiziere = function(item) inv.doWithHands(1, 'schuettele '..item) end


-- ---------------------------------------------------------------------------
-- Tastenbelegung

-- F5-F8: Angriffs-Zauber
keymap.F5 = kampf.createAttackFunctionWithEnemy('nebel', 2)
keymap.F6 = kampf.createAttackFunctionWithEnemy('alkoholgift', 1)
keymap.F7 = function() inv.doWithHands(2, 'erdbeben') end
keymap.F8 = kampf.createAttackFunctionWithEnemy('hitzeschlag', 1)

-- M-*
keymap.M_b = function() inv.doWithHands(2, 'sand') end
keymap.M_e = 'nuechtern'
keymap.M_f = kampf.createAttackFunctionWithEnemy('schuettelstarre')
keymap.M_g = 'floesse'
keymap.M_i = 'beruhige'
keymap.M_k = 'kneipen'
keymap.M_l = 'licht'
keymap.M_m = 'schimmer'
keymap.M_r = 'rkaufe'
keymap.M_t = 'fliesse'
keymap.M_v = function() inv.doWithHands(1, 'haarwuchs') end
keymap.M_z = function() inv.doWithHands(2, 'massiere') end
