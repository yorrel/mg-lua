-- Karateka

local base   = require 'base'
local kampf  = require 'battle'

local keymap = base.keymap


local function state()
  return base.getPersistentTable('karate')
end


-- daempfung (spart KP)
-- daempfung [keine|schwach|mittel|stark|absolut]
-- keine bedeutet voll zuschlagen, absolut bedeutet super-schwach
local daempfung_liste = { 'keine', 'schwach', 'mittel', 'stark', 'absolut' }

local function daempfungSteigern()
  local _akt = state().daempfung or 1
  local _neu = _akt+1
  if _neu > #daempfung_liste then
    _neu = #daempfung_liste
  end
  state().daempfung = _neu
  client.send('daempfung '..daempfung_liste[_neu])
end

local function daempfungReduzieren()
  local _akt = state().daempfung or 1
  local _neu = _akt-1
  if _neu < 1 then
    _neu = 1
  end
  state().daempfung = _neu
  client.send('daempfung '..daempfung_liste[_neu])
end

local function konzentrationAufGegner()
  client.send('konzentration auf '..kampf.getGegner())
end


-- ---------------------------------------------------------------------------
-- Standardfunktionen aller Gilden

local function karateka_info()
  client.send('angriff')
  client.send('abwehr')
  client.send('daempfung')
end

base.gilde.info = karateka_info


-- ---------------------------------------------------------------------------
-- Tastenbelegung

keymap.F5   = daempfungReduzieren
keymap.S_F5 = daempfungSteigern
keymap.F6   = 'angriff mit ssu'
keymap.S_F6 = 'angriff mit ueu'     -- standard ist wohl oeu
keymap.F7   = 'angriff mit fg, fog'
keymap.S_F7 = 'angriff mit cz'
keymap.F8   = 'toete alle'
keymap.S_F8 = 'angriff mit allem'

-- kampfwille der karateka
keymap.M_j = 'nemoku-owaru'
keymap.M_k = konzentrationAufGegner

