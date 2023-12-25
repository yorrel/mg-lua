-- Bierschuettler

local base   = require 'base'
local inv    = require 'inventory'
local pub    = require 'pub'
local room   = require 'room'
local timer  = require 'timer'

local logger = client.createLogger('bierschuettler')
local trigger = {}


-- ---------------------------------------------------------------------------
-- Guild class Bierschuettler

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Bierschuettler = class(Guild)

function Bierschuettler:identifiziere(item)
  inv.doWithHands(1, 'schuettele '..item)
end

function Bierschuettler:schaetz(item)
  client.send('beobachte '..item)
end

function Bierschuettler:enable()
  -- Statuszeile -------------------------------------------------------------
  local statusConf = '{haarwuchs:2} {schimmer:2} {beruhige:2}'
  base.statusConfig(statusConf)

  local function statusUpdate(id, optVal)
    return
      function()
        base.statusUpdate({id, optVal})
      end
  end

  -- haarwuchs
  self:createSubstrTrigger('Dir wachsen ueberall Haare.', statusUpdate('haarwuchs', 'Ha'), {'<green>'})
  self:createSubstrTrigger('Deine Haare fallen aus.', statusUpdate('haarwuchs'), {'<red>'})

  -- schimmer
  self:createSubstrTrigger('Dein Koerper faengt an zu schimmern.', statusUpdate('schimmer', 'Sc'), {'<green>'})
  self:createSubstrTrigger('Der Schimmer, der Dich umgibt, verblasst.', statusUpdate('schimmer'), {'<red>'})

  -- beruhige
  self:createSubstrTrigger('Du bist die Ruhe selbst.', statusUpdate('beruhige', 'Be'), {'<green>'})
  self:createSubstrTrigger('Du wirst wieder unruhiger.', statusUpdate('beruhige'), {'<red>'})

  -- Standardfunktionen ------------------------------------------------------
  pub.setOrderCmd(
    function(id)
      local cmd = room.getLabel() == 'bkneipe' and 'bkaufe' or 'bestelle'
      client.send(cmd..' '..id)
    end
  )

  -- Trigger -----------------------------------------------------------------
  -- schuettelstarre
  self:createRegexTrigger(
    base.charName() .. ' starrt .* an\\.',
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

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5 = Guild.attackFunWithEnemy('nebel', 2)
  keymap.F6 = Guild.attackFunWithEnemy('alkoholgift', 1)
  keymap.F7 = function() inv.doWithHands(2, 'erdbeben') end
  keymap.F8 = Guild.attackFunWithEnemy('hitzeschlag', 1)

  keymap.M_b = function() inv.doWithHands(2, 'sand') end
  keymap.M_e = 'nuechtern'
  keymap.M_f = Guild.attackFunWithEnemy('schuettelstarre')
  keymap.M_g = 'floesse'
  keymap.M_i = 'kneipen'
  keymap.M_k = 'beruhige'
  keymap.M_l = 'licht'
  keymap.M_m = 'schimmer'
  keymap.M_r = 'rkaufe'
  keymap.M_t = 'fliesse'
  keymap.M_v = function() inv.doWithHands(1, 'haarwuchs') end
  keymap.M_z = function() inv.doWithHands(2, 'massiere') end
end


return Bierschuettler
