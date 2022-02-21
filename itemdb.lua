-- db der bekannten items

local tools = require 'tools'

local logger = client.createLogger('itemdb')


-- itemdb: enthaelt kuerzel zu bekannten waffen und die waffendaten
local itemdb = {}
itemdb.sticky = itemdb.sticky or {}
itemdb.waffen = itemdb.waffen or {}
itemdb.schilde = itemdb.schilde or {}
-- konfigurierbare ausruestungstypen (z.B. Typ a kann fuer Amulett verwendet werden)
itemdb.typen = itemdb.typen or {}
itemdb.typenlangnamen = itemdb.typenlangnamen or {}
itemdb.items = itemdb.items or {}


-- WAFFENLISTE: kuerzel langname haende <schadensarten>
-- Aufbau der Datenbank zu den Waffen
-- args: id langname anzahl_haende schadensart_1 ... schadensart_n
local function configWaffe(id, langname, anzahlhaende, damagestring)
  local schadenarten = tools.splitString(damagestring, ' ')
  itemdb.waffen[id] = { long=langname, hands=anzahlhaende, damage=schadenarten }
end

-- definiert alle items eines ausruestungstyps
-- args: id langname map{key1='item1', key2='item2', ...}
local function configSchilde(itemmap)
  itemdb.schilde = itemmap
end

-- definiert alle items eines ausruestungstyps
-- args: id langname map{key1='item1', key2='item2', ...}
local function configItems(id, langname, itemmap)
  itemdb.items[id] = itemmap
  itemdb.typenlangnamen[id] = langname
  itemdb.typen[#itemdb.typen + 1] = id
end

local function configSticky(...)
  for _, e in ipairs{...} do
    itemdb.sticky[e] = true
  end
end


local function isSticky(item)
  return itemdb.sticky[item]
end

local function waffenName(item)
  local werte = itemdb.waffen[item]
  if (werte == nil) then
    return item
  else
    return werte.long
  end
end

local function getWaffenWerte(id)
  return itemdb.waffen[id]
end

local function getSchild(id)
  return itemdb.schilde[id]
end

local function getItem(typ, id)
  local typDB = itemdb.items[typ]
  if typDB == nil then
    logger.warn('Item-Typ '..typ..' nicht konfiguriert!')
  else
    return typDB[id] or id
  end
end

local function getItemTypen()
  return itemdb.typen
end

local function getTypLangname(typ)
  return itemdb.typenlangnamen[typ]
end


-- ---------------------------------------------------------------------------
-- module definition

return {
  configWaffe = configWaffe,
  configSchilde = configSchilde,
  configItems = configItems,
  configSticky = configSticky,
  isSticky = isSticky,
  waffenName = waffenName,
  waffe = getWaffenWerte,
  schild = getSchild,
  item = getItem,
  typen = getItemTypen,
  typLangname = getTypLangname,
}
