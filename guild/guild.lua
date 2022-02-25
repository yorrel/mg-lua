local class = require 'class'

local Guild = class(function(a,name)
    a.name = name
 end)

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
