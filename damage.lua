-- Schadenshoehe mitschneiden und Statistiken berechnen

local reduce = require 'reduce'

local logger = client.createLogger('damage')

local damages = {}
damages['verfehlt'] = 0
damages['gekitzelt'] = 1
damages['gekratzt'] = (2+3)/2
damages['getroffen'] = (4+5)/2
damages['hart'] = (6+10)/2
damages['sehr hart'] = (11+20)/2
damages['Krachen'] = (21+30)/2
damages['Schmettern'] = (31+50)/2
damages['zu Brei'] = (51+75)/2
damages['Pulver'] = (76+100)/2
damages['zerstaeubt'] = (101+150)/2
damages['atomisiert'] = (151+200)/2
damages['vernichtet'] = 225

local hits_in_count = 0
local hits_in_damage = 0
local hits_out_count = 0
local hits_out_damage = 0
local metrics_active = false

local function reduceOutputListener(output)
  if string.match(output, '%->') then
    output = string.gsub(output, '<[a-z]*>', '')
    output = string.gsub(output, '.* %-> ', '')
    local dmg = damages[output]
    if dmg ~= nil then
      hits_out_damage = hits_out_damage + dmg
      hits_out_count = hits_out_count + 1
    else
      logger.warn('damage value not found for output: '..output)
    end
  end
  if string.match(output, '<%-') then
    output = string.gsub(output, '<[a-z]*>', '')
    output = string.gsub(output, '.* <%- ', '')
    local dmg = damages[output]
    if dmg ~= nil then
      hits_in_damage = hits_in_damage + dmg
      hits_in_count = hits_in_count + 1
    else
      logger.warn('damage value not found for output: '..output)
    end
  end
end

local function startDamageMetrics()
  if not metrics_active then
    logger.info('start damage metrics')
    reduce.setOutputListener(reduceOutputListener)
    metrics_active = true
  end
  if hits_out_count > 0 then
    logger.info('-> damage avg : '..(hits_out_damage/hits_out_count))
    logger.info('-> damage sum : '..hits_out_damage)
    logger.info('-> count      : '..hits_out_count)
    logger.info('<- damage avg : '..(hits_in_damage/hits_in_count))
    logger.info('<- damage sum : '..hits_in_damage)
    logger.info('<- count      : '..hits_in_count)
  end
  hits_out_count = 0
  hits_out_damage = 0
  hits_in_count = 0
  hits_in_damage = 0
end

local function stopDamageMetrics()
  if metrics_active then
    logger.info('stop damage metrics')
    reduce.setOutputListener(nil)
    metrics_active = false
  end
end

local cmds = {
  start = startDamageMetrics,
  stop = stopDamageMetrics
}

client.createStandardAlias(
  'dmg',
  1,
  function(arg)
    local cmd = cmds[arg]
    if cmd == nil then
      logger.error('unbekanntes Kommando '..arg)
    else
      cmd()
    end
  end,
  function(arg)
    return { 'start', 'stop' }
  end
)
