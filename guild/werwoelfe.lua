-- Werwoelfe

local base   = require 'base'

local logger = client.createLogger('werwoelfe')


-- ---------------------------------------------------------------------------
-- Guild class Werwoelfe

local class  = require 'utils.class'
local Guild  = require 'guild.guild'
local Werwoelfe = class(Guild)

function Werwoelfe:enable()
  -- Statuszeile -------------------------------------------------------------
  local statusConf = '{rage:2} {fellwuchs:2} {form:8} {leuchten:1}'
  base.statusConfig(statusConf)
  local function statusUpdate(id, optVal)
    return
      function()
        base.statusUpdate({id, optVal})
      end
  end

  -- Wolfsform
  local formen = {
    Wolf = { color = '<green>', form = 'Wolf' },
    Halbwolf = { color = '<yellow>', form = 'Ghourdal' },
    Wolfmensch = { color = '<magenta>', form = 'Horpas' },
    Wolfsmensch = { color = '<magenta>', form = 'Horpas' },
    Menschwolf = { color = '<red>', form = 'Galbrag' }
  }
  local formen_extra_trigger = {}
  formen_extra_trigger[#formen_extra_trigger+1] = client.createRegexTrigger(
    '^drueckst Du den Ruecken durch\\.$', nil, {'g'}
  )
  formen_extra_trigger[#formen_extra_trigger+1] = client.createRegexTrigger(
    '^Du bist jetzt ein (Wolf|Halbwolf|Wolfmensch|Menschwolf)\\.',
    function(m)
      client.disableTrigger(formen_extra_trigger)
      local form = formen[m[1]].form
      base.statusUpdate({'form', form})
      logger.info('Wolfsform: '..m[1]..' / '..formen[m[1]].color..form)
    end,
    {'g'}
  )
  client.disableTrigger(formen_extra_trigger)
  self:createRegexTrigger(
    '^(Du laesst Dich auf alle 4 Beine nieder und stoesst ein Heulen aus|Gross und maechtig willst Du werden\\. Du reckst Dich zum Himmel|Du bueckst Dich ein wenig und heulst leise)',
    function()
      client.enableTrigger(formen_extra_trigger)
    end,
    {'g'}
  )
  self:createRegexTrigger(
    '^Du bist schon in einer anderen Form\\.$', nil, {'<yellow>'}
  )
  self:createRegexTrigger(
    '^Du bist doch schon ein (Wolf|Halbwolf|Menschwolf|Wolfsmensch)\\.$',
    function(m)
      local form = formen[m[1]].form
      base.statusUpdate({'form', form})
      logger.info('bereits in Wolfsform: '..m[1]..' / '..formen[m[1]].color..form)
    end,
    {'g'}
  )
  local form_wechsel_sperre
  form_wechsel_sperre = client.createRegexTrigger(
    '^nicht lang genug her\\.',
    function(m)
      client.disableTrigger(form_wechsel_sperre)
      logger.warn('Noch kein Formwechsel moeglich')
    end,
    {'g'}
  )
  client.disableTrigger(form_wechsel_sperre)
  self:createRegexTrigger(
    '^Du kannst noch nicht wieder die Form wechseln, der letzte Versuch ist noch',
    function()
      client.enableTrigger(form_wechsel_sperre)
    end,
    {'g'}
  )
  self:createRegexTrigger(
    '^Du bemerkst, wie Du Dich wieder in Deine urspruengliche Form verwandelst\\.',
    function()
      logger.info('<red>Verwandlung beendet')
      base.statusUpdate({'form'})
    end,
    {'g'}
  )

  -- Leuchten
  self:createRegexTrigger(
    '^Du beginnst zu leuchten\\.',
    statusUpdate('leuchten', 'L'),
    {'<green>'}
  )
  self:createRegexTrigger(
    '^Du leuchtest doch bereits\\.',
    nil,
    {'<yellow>'}
  )
  self:createRegexTrigger(
    '^Das Leuchten um Dich herum verblasst\\.',
    statusUpdate('leuchten'),
    {'<red>'}
  )

  -- Tasten ------------------------------------------------------------------
  local keymap = base.keymap
  keymap.F5 = Guild.attackFunWithEnemy('biss')
  keymap.F6 = Guild.attackFunWithEnemy('kralle', 1)

  keymap.M_i = 'wolf'
  keymap.M_g = 'galbrag'
  keymap.M_j = 'horpas'
  keymap.M_k = 'ghourdal'
  keymap.M_l = 'leuchten'
  keymap.M_t = 'mondbruecke'

  -- Aliases -----------------------------------------------------------------
  client.createStandardAlias(
    'skills',
    0,
    function()
      client.send('tm mondheuler faehigkeiten', 'tm mondheuler talente')
    end
  )
end

return Werwoelfe
