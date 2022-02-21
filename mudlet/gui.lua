
local ME   = require 'gmcp-data'
local base = require 'base'


-- Einstellungen fuer Farben Allgemein
farben = {}
farben.vg = 
  { komm = 'cyan',
    ebenen = 'magenta',
    info = 'green',
    alarm = 'white',
    script = 'dark_green' }
farben.hg = 
  { komm = 'black',
    ebenen = 'black',
    info = 'black', 
    alarm = 'red',
    script = 'black' }

-- komm: Kommunikation wie teile-mit
-- ebenen: Einfaerben der 'normalen' Ebenen
-- info: Einfaerben von Informationen des Muds (Status Gegner)
-- alarm: Alarm-Nachrichten
-- script: Nachrichten, die nicht vom Mud, sondern von einem Script stammen.

-- Einstellungen fuer Farben Kampfscroll

local function msg (type, what)
  -- setzt VG und HG je nach Typ der Kommunikation
  local vg = farben.vg[type]
  local hg = farben.hg[type]

  if vg and hg then
    cecho('<'..vg..':'..hg..'>'..what)
  else
    echo(what)
  end
end


-- Variablen zum Spieler

GUI = {}
GUI.angezeigt = false
GUI.lp_anzeige_blinkt = false



local function initGMCP() 
  sendGMCP( [[Core.Supports.Debug 20 ]])
  sendGMCP( [[Core.Supports.Set [ 'MG.char 1', 'MG.room 1' ] ]])
end


local function initGUI()

  -- Textfenster begrenzen
  setBorderTop(0)
  setBorderBottom(65) -- bisschen Platz fuer Statuszeile
  setBorderLeft(0)
  setBorderRight(0)

  -- Statuszeile malen. Layout wie folgt:
  -- Zeile 1: charbar_1 (Name, Stufe), gift_balken, spacer, charbar_2 (Vorsicht, Fluchtrichtung)
  -- Zeile 2: ortbar_2 (Region, Raumnummer, Para), ortbar_1 (Ort kurz)
  -- Zeile 3: hpbar_name, hpbar (Lebenspunkte-Anzeige), mpbar_name, mpbar (KP-Anzeige), spacer2

  GUI.statuszeile = Geyser.Container:new({name = 'statuszeile', x=0, y=-70, width = 600, height=70})

  -- Zeile 1
  GUI.spieler = Geyser.Label:new({
    name = 'spieler',
    x = 0, y = -65,
    width = 150, height = 20}, GUI.statuszeile)

  GUI.gift = Geyser.Label:new({
    name = 'gift',
    x = 150, y = -65,
    width = 50, height = 20}, GUI.statuszeile)

  GUI.trenner_1 = Geyser.Label:new({
    name = 'trenner_1',
    x = 200, y = -65,
    width = 50, height = 20}, GUI.statuszeile)

  GUI.vorsicht = Geyser.Label:new({
    name = 'vorsicht',
    x = 250, y = -65,
    width = 350, height = 20}, GUI.statuszeile)

  -- Zeile 2
  GUI.ort_raum = Geyser.Label:new({
    name = 'ort_raum',
    x = 250, y = -45,
    width = 350, height = 20}, GUI.statuszeile)

  GUI.ort_region = Geyser.Label:new({
    name = 'ort_region',
    x = 0, y = -45,
    width = 250, height = 20}, GUI.statuszeile)

  -- Zeile 3
  GUI.lp_titel = Geyser.Label:new({
    name = 'lp_titel',
    x = 0, y = -25,
    width = 100, height = 20}, GUI.statuszeile)
  GUI.lp_titel:echo('Lebenspunkte:')

  GUI.lp_anzeige = Geyser.Gauge:new({
    name = 'lp_anzeige',
    x = 100, y = -25,
    width = 140, height = 20}, GUI.statuszeile)
  GUI.lp_anzeige:setColor(0, 255, 50)

  GUI.kp_titel = Geyser.Label:new({
    name = 'kp_titel',
    x = 240, y = -25,
    width = 110, height = 20}, GUI.statuszeile)
  GUI.kp_titel:echo('&nbsp;Konzentration:')

  GUI.kp_anzeige = Geyser.Gauge:new({
    name = 'kp_anzeige',
    x = 350, y = -25,
    width = 150, height = 20}, GUI.statuszeile)
  GUI.kp_anzeige:setColor(0, 50, 250)

  GUI.trenner_2 = Geyser.Label:new({
    name = 'trenner_2',
    x = 500, y = -25,
    width = 100, height = 20}, GUI.statuszeile)

end

local function initBase() 
  if not GUI.angezeigt then
    initGUI()
    GUI.angezeigt = true
  end
end


local function zeigeVitaldaten()

  -- Werte der Balken aktualisieren
  
  GUI.lp_anzeige:setValue(ME.lp, ME.lp_max, 
      '<b> ' .. ME.lp .. '/' .. ME.lp_max .. '</b> ')

  GUI.kp_anzeige:setValue(ME.kp, ME.kp_max, 
      '<b> ' .. ME.kp .. '/' .. ME.kp_max .. '</b> ')

  -- Treffer? Dann LP Balken blinken lassen

  if ME.lp < ME.lp_alt then
    -- echo('Au!')
    lp_anzeige_blinken(0.2)
  else
    if not GUI.lp_anzeige_blinkt then
      lp_anzeige_faerben()
    end
  end
  ME.lp_alt = ME.lp

end


local function lp_anzeige_faerben()

  -- Je nach LP Verlust wird Farbe gruen/gelb/rot

  local lp_quote = ME.lp / ME.lp_max
  GUI.lp_anzeige:setColor(255 * (1 - lp_quote), 
                          255 * lp_quote, 
                          50)
end


local function lp_anzeige_blinken(dauer)

  GUI.lp_anzeige_blinkt = true
  GUI.lp_anzeige:setColor(255, 0, 50) -- rot
  tempTimer(dauer, [[ lp_anzeige_entblinken() ]])

end


local function lp_anzeige_entblinken()

  GUI.lp_anzeige_blinkt = false
  lp_anzeige_faerben()

end


local function zeigeGift()

  local zeile = ''

  -- vergiftet?

  local r = 30
  local g = 30
  local b = 30
  if ME.gift > 0 then
    -- Farbuebergang gelb->orange->rot
    r = 255
    g = 255 - ME.gift * 25
    b = 0
    zeile = '<black>G I F T'
  end

  -- Statuszeile aktualisieren

  GUI.gift:echo(zeile)
  GUI.gift:setColor(r, g, b)

end


local function zeigeVorsicht()

  -- Prinz Eisenherz?
  show_vs = ME.vorsicht
  if ME.vorsicht == 0 then
    show_vs = 'NIX'
  end

  local zeile = 'Vorsicht: ' .. show_vs

  -- Fluchtrichtung anzeigen, nur wenn gesetzt

  if ME.fluchtrichtung ~= 0 then
    zeile = zeile .. ', FR: ' .. ME.fluchtrichtung
  end

  -- Statuszeile aktualisieren

  GUI.vorsicht:echo(zeile)

end


local function zeigeRaum()

  -- Para?

  local r = 30
  local g = 30
  local b = 30
  if ME.para > 0 then
    ME.raum_region = 'Para-' .. ME.raum_region
    r = 255
    g = 0
    b = 0
  end

  -- Statuszeile aktualisieren

  GUI.spieler:echo(ME.name .. ' [' .. ME.level .. ']')

  GUI.ort_raum:echo(ME.raum_kurz)
  GUI.ort_region:echo(ME.raum_region .. ' [' .. ME.raum_id_short .. ']')

  GUI.ort_raum:setColor(r, g, b)
  GUI.ort_region:setColor(r, g, b)

end


base.registerEventHandler('gmcp.Char', initGMCP)

base.registerEventHandler('gmcp.MG.char.base', initBase)
base.registerEventHandler('gmcp.MG.char.info', initBase)
base.registerEventHandler('gmcp.MG.char.vitals', zeigeVitaldaten)
base.registerEventHandler('gmcp.MG.char.maxvitals', zeigeVitaldaten)
base.registerEventHandler('gmcp.MG.char.vitals', zeigeGift)
base.registerEventHandler('gmcp.MG.char.wimpy', zeigeVorsicht)
base.registerEventHandler('gmcp.MG.room', zeigeRaum)
