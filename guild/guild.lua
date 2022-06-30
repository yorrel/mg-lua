local class = require 'utils.class'
local kampf = require 'battle'
local inv   = require 'inventory'

local Guild = class(function(a,name)
    a.name = name
 end)

function Guild.attackFunWithEnemy(skill, hands)
  return function()
    local attack = skill .. ' ' .. kampf.getGegner()
    if hands == nil then
      client.send(attack)
    else
      inv.doWithHands(hands, attack)
    end
  end
end

function Guild:identifiziere(item)
    client.send('identifiziere '..item)
end

function Guild:schaetz(item)
    client.send('schaetz '..item)
end

function Guild:entsorgeLeiche()
    client.send('streue pulver ueber leiche')
end

function Guild:info()
end

function Guild:enable()
end

return Guild
