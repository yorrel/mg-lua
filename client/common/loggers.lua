-- logger factory

local debug_on = false

local function createLogger(komponente, cecho)
  local kmp = '['..komponente:sub(1,5)..']'
  kmp = kmp..string.sub('     ',1,7-#kmp)
  return {
    debug =
      function(msg)
        if debug_on then
          cecho('<cyan>[DEBUG] '..kmp..' '..msg..'<reset>')
        end
      end,
    info =
      function(msg)
        cecho('<cyan>>>> '..kmp..' '..msg..'<reset>')
      end,
    warn =
      function(msg)
        cecho('<bgyellow>>>> '..kmp..' '..msg..'<reset>')
      end,
    error =
      function(msg)
        cecho('<bgred>>>> '..kmp..' '..msg..'<reset>')
      end
  }
end

local function toggleDebug()
  local logger = client.createLogger('debug')
  debug_on = not debug_on
  logger.info('Debug: '..(debug_on and 'on' or 'off'))
end


-- ---------------------------------------------------------------------------
-- module definition

return {
  createLogger = createLogger,
  toggleDebug = toggleDebug,
}
