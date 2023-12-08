
local function addWorld(id, name, pwd)
  client.createStandardAlias(
    id,
    0,
    function()
      if blight then
        client.login('mg.mud.de', 4712, name, pwd, true, false)
      else
        client.login('mg.mud.de', 23, name, pwd)
      end
    end
  )
end

-- login: #keno
addWorld('keno',   'Keno',     'super-geheim')
