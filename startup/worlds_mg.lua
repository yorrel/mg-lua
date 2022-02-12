
-- login: #keno

local function addWorld(id, name, pwd)
  client.createStandardAlias(
    id,
    0,
    function()
      client.login('mg.mud.de', 23, name, pwd)
    end
  )
end

addWorld('keno',   'Keno',     'super-geheim')
