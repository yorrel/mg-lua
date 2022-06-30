-- Bierschuettler

local base   = require 'base'
local inv    = require 'inventory'
local pub    = require 'pub'
local room   = require 'room'
local timer  = require 'timer'

local logger = client.createLogger('bierschuettler')
local trigger = {}


-- ---------------------------------------------------------------------------
-- Statuszeile

local statusConf = '{haarwuchs:2} {schimmer:2} {beruhige:2}'

local function statusUpdate(id, optVal)
  return
    function()
      base.statusUpdate({id, optVal})
    end
end

-- haarwuchs
trigger[#trigger+1] = client.createSubstrTrigger('Dir wachsen ueberall Haare.', statusUpdate('haarwuchs', 'Ha'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Deine Haare fallen aus.', statusUpdate('haarwuchs'), {'<red>'})

-- schimmer
trigger[#trigger+1] = client.createSubstrTrigger('Dein Koerper faengt an zu schimmern.', statusUpdate('schimmer', 'Sc'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Der Schimmer, der Dich umgibt, verblasst.', statusUpdate('schimmer'), {'<red>'})

-- beruhige
trigger[#trigger+1] = client.createSubstrTrigger('Du bist die Ruhe selbst.', statusUpdate('beruhige', 'Be'), {'<green>'})
trigger[#trigger+1] = client.createSubstrTrigger('Du wirst wieder unruhiger.', statusUpdate('beruhige'), {'<red>'})

client.disableTrigger(trigger)


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
  -- Standardfunktionen ------------------------------------------------------
  base.statusConfig(statusConf)

  pub.setOrderCmd(
    function(id)
      local cmd = room.getLabel() == 'bkneipe' and 'bkaufe' or 'bestelle'
      client.send(cmd..' '..id)
    end
  )

  -- Trigger -----------------------------------------------------------------
  -- schuettelstarre
  client.createRegexTrigger(
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
  client.enableTrigger(trigger)

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
  keymap.M_i = 'beruhige'
  keymap.M_k = 'kneipen'
  keymap.M_l = 'licht'
  keymap.M_m = 'schimmer'
  keymap.M_r = 'rkaufe'
  keymap.M_t = 'fliesse'
  keymap.M_v = function() inv.doWithHands(1, 'haarwuchs') end
  keymap.M_z = function() inv.doWithHands(2, 'massiere') end
end


return Bierschuettler
