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

local totalDamage = 0
local number = 0
local active = false
  
local function reduceOutputListener(output)
  if string.match(output, '->') then
    output = string.gsub(output, '@{%w*}', '')
    output = string.gsub(output, '.*-> ', '')
    local dmg = damages[output]
    if dmg ~= nil then
      totalDamage = totalDamage + dmg
      number = number + 1
    else
      logger.warn('damage value not found for output: '..output)
    end
  end
end

local function startDamageMetrics()
  if not active then
    logger.info('start damage metrics')
    reduce.setOutputListener(reduceOutputListener)
    active = true
  end
  if number > 0 then
    logger.info('#measures: '..number..', average damage: '..(totalDamage/number))
  end
  totalDamage = 0
  number = 0
end

local function stopDamageMetrics()
  if active then
    logger.info('stop damage metrics')
    reduce.setOutputListener(nil)
    active = false
  end
end
    
client.createStandardAlias('dmg', 0, startDamageMetrics)
client.createStandardAlias('dmg_end', 0, stopDamageMetrics)
