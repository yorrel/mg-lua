
local ws     = require 'ways'

local logger = client.createLogger('ways')


------------------------------------------------------------------------------
-- /await + /await_re : Ereignisse abwarten ----------------------------------

local await_trigger = {}

local function handle_await(pattern, triggerFactory)
  local id = await_trigger[pattern]
  if id == nil then
    id = triggerFactory(
      pattern,
      function()
        client.disableTrigger(id)
        ws.continue()
      end
    )
    await_trigger[pattern] = id
  else
    client.enableTrigger(id)
  end
end

ws.defHandler(
  '/await',
  function(pattern)
    handle_await(pattern, client.createSubstrTrigger)
  end
)
ws.defHandler(
  '/await_re',
  function(pattern)
    handle_await(pattern, client.createRegexTrigger)
  end
)


------------------------------------------------------------------------------
-- /blocker : Blocker-Erkennung ----------------------------------------------

local lastBlocker = ''
local aktiverSpezialTrigger
local spezialBlockerTrigger = {}

local defaultBlockerTrigger = {}
defaultBlockerTrigger[#defaultBlockerTrigger+1] = client.createSubstrTrigger(
  'Du verwuschelst',
  function()
    logger.error('Blocker!  - '..lastBlocker)
    client.disableTrigger(defaultBlockerTrigger)
    if aktiverSpezialTrigger ~= nil then
      client.disableTrigger(aktiverSpezialTrigger)
      aktiverSpezialTrigger = nil
    end
  end,
  {'g'}
)
local function blockerAbwesend()
  logger.info('(Blocker \''..lastBlocker..'\' nicht da)')
  client.disableTrigger(defaultBlockerTrigger)
  if aktiverSpezialTrigger ~= nil then
    client.disableTrigger(aktiverSpezialTrigger)
    aktiverSpezialTrigger = nil
  end
  ws.continue(true)
end
defaultBlockerTrigger[#defaultBlockerTrigger+1] = client.createSubstrTrigger(
  'Wen willst Du',
  blockerAbwesend,
  {'g'}
)
client.disableTrigger(defaultBlockerTrigger)


-- args: name_npc[/<not present message>]
local function handle_blocker(npc)
  local msgSeparator = string.find(npc,'/')
  if msgSeparator ~= nil then
    local notPresentMsg = npc:sub(msgSeparator+1)
    npc = npc:sub(1,msgSeparator-1)
    aktiverSpezialTrigger = spezialBlockerTrigger[notPresentMsg]
    if aktiverSpezialTrigger == nil then
      spezialBlockerTrigger[notPresentMsg] = client.createSubstrTrigger(
        notPresentMsg,
        blockerAbwesend,
        {'g'}
      )
      aktiverSpezialTrigger = spezialBlockerTrigger[notPresentMsg]
    else
      client.enableTrigger(aktiverSpezialTrigger)
    end
  end
  logger.debug('Blocker \''..npc..'\' pruefen...')
  lastBlocker = npc
  client.enableTrigger(defaultBlockerTrigger)
  client.send('wuschel '..npc)
  -- ggf. diesen schritt erneut ausfuehren
  return true
end

ws.defHandler('/blocker', handle_blocker)
