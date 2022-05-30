-- Kneipen

local room   = require 'room'
local base   = require 'base'
local ME     = require 'gmcp-data'

local logger = client.createLogger('kneipe')
local keymap = base.keymap


local kneipen = {}

-- bestellungen muss table sein {typ -> {name, lp, kp}}
local function defPub(wegpunkt, bestellungen, toilettengang)
  kneipen[wegpunkt] = {
    bestellungen = bestellungen,
    toilettengang = toilettengang,
  }
end

local function getAktuelleKneipe()
  local wp = room.getRoomName()
  if wp == nil then
    return nil
  end
  return kneipen[wp]
end

local function isRoomKnownPub()
  return getAktuelleKneipe() ~= nil
end


-- ---------------------------------------------------------------------------
-- tanken

local last_tanke_zeitpunkt = os.time() - 100
local lp_start = 0
local kp_start = 0
local lp_getankt = 0
local kp_getankt = 0

local default_order_cmd = function(id) client.send('bestelle '..id) end
local order_cmd = default_order_cmd

local function tanke(typ)
  local kneipe = getAktuelleKneipe()
  if kneipe == nil then
    logger.warn('Aktueller Raum ist keine bekannte Kneipe!')
    return
  end
  local b = kneipe.bestellungen[typ]
  if b == nil then
    logger.warn('Typ '..typ..' ist fuer aktuelle Kneipe nicht definiert')
    return
  end
  if os.difftime(os.time(), last_tanke_zeitpunkt) > 20 then
    lp_start = ME.lp
    kp_start = ME.kp
    lp_getankt = 0
    kp_getankt = 0
  end
  last_tanke_zeitpunkt = os.time()
  order_cmd(b.id)

  lp_getankt = lp_getankt + (b.lp or 0)
  kp_getankt = kp_getankt + (b.kp or 0)
  logger.info(
    'LP+'..(b.lp or '?')..' -> '..(lp_start+lp_getankt) .. ' / '
      ..'KP+'..(b.kp or '?')..' -> '..(kp_start+kp_getankt))
end

local function toilette()
  local kneipe = getAktuelleKneipe()
  if kneipe == nil then
    logger.warn('Aktueller Raum ist keine bekannte Kneipe!')
    return
  end
  client.send('ultrakurz')
  kneipe.toilettengang()
  client.send('lang')
end


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.F3   = function() tanke('lp1') end
keymap.S_F3 = function() tanke('lp2') end
keymap.F4   = function() tanke('kp1') end
keymap.S_F4 = function() tanke('kp2') end
keymap.M_c  = toilette


-- ---------------------------------------------------------------------------
-- Aliases

client.createStandardAlias('tk',  1, tanke)


return {
  defPub = defPub,
  isRoomKnownPub = isRoomKnownPub,
  setOrderCmd = function(cmd) order_cmd = cmd or default_order_cmd end,
  order = tanke,
}
