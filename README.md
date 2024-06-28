# Features

## guild.*

Enthält gildenspezifische Funktionen, Trigger und Tastenbelegungen.

Einige Tastenbelegungen sind nach Möglichkeit gildenübergreifend ähnlich.

- F5 bis F8 (mit/ohne Shift): Angriff
- M-g Gegner schwächen
- M-j kampfwille
- M-k fokus
- M-l licht/nachtsicht
- M-m schutz (ggf. magisch)
- M-p paralyse
- M-t teleport
- M-v schutz
- M-x schnell
- M-z Vorbereitung (bete, meditiere, Waffe schaerfen, ...)

Möchte man eigene Belegungen nutzen, muss man sie nachträglich ändern.

Farbcode der Trigger:

- grün: Skill wird aktiv oder ist es noch
- gelb: Warnung zu baldigem Skill-Ende
- rot: Skill endet
- magenta: Fehlschlag, Skill nicht möglich, Problem oder wichtige Meldung
- cyan: andere Meldungen

## inventory.lua

Ausrüstung:
- #ww id       - wechselt Waffe; flags -1 und -2 für abweichend ein-/zweihändig
- #ws id       - wechselt Schild
- #w typ id    - wechselt Ausrüstung vom Typ typ in id
- #w -l        - Liste aller aktuellen Items

Ausrüstung speichern:
- #k -w id     - speichert aktuelle Ausrüstung unter dem Namen id
- #k -rm id    - löscht Ausrüstungskonfiguration id
- #k id        - wechselt auf Ausrüstungskonfiguration id
- #k -l        - Liste alle Ausrüstungskonfigurationen

id kann dabei ein Kürzel aus der itemdb sein, ansonsten wird einfach die id als
Name verwendet.

Container:
- #ci id                - untersucht container
- #c cont1 cont2 item   - bewegt item von cont1 zu cont2 (- = in mir)
- #cont id name         - setzt container für id
- #r2b item             - bewegt item von container r zu b (beutel)
- #r2t item             - bewegt item von container r zu t (truhe)
- usw.

## reduce.lua

Basiert ursprünglich auf reduce.tf. Für mehrzeilige Trigger (siehe
createMultiLineRegexTrigger) ist der Ansatz, dass ein fest definierter Präfix eindeutig
den Trigger identifziert und auslöst. Folgezeilen werden in einen Buffer gepackt, bis der
Satz endet. Danach wird dann der Gesamttext mit einer regex-Lib gematcht um alle captures
zu berechnen.

Da blightmud keine Trigger-Prio kennt, müssen Trigger niedrigerer Prio am Ende definiert
werden.

## room.lua

In-Game Notizen, Standard-Aktionen, raumspezifische Ausgänge.

- #room name ssp - vergibt Id 'ssp' für den aktuellen Raum
- #room alias ssp2 - vergibt alternativen Namen (nur für diesen Charakter)
- #room alias -g ssp3 - vergibt alternativen Namen (charakterübergreifend)
- #room exit ob kletter hoch - setzt abweichende Kommandos für M-n, M-s usw.
- #room fr n - setzt default Fluchtrichtung für aktuellen Raum
- #room npc titan - setzt default Gegner für aktuellen Raum
- #room note Vorsicht: Gegner n! - setzt Notiz für aktuellen Raum

Mit Flag -rm kann man die Daten des Raums zurücksetzen, z.B. löscht folgendes
Kommando die raumspezifischen Bewegungskommandos: #room exit -rm

## utils-mg.lua

- F1 - schau
- S-F1 - sich selbst ansehen
- F2 - inventory
- S-F2 - info
- F12 - dschinn
- M-n - norden
- M-o - osten
- M-s - sueden
- M-w - westen
- M-h - oben
- M-u - unten

## ways.lua

Funktionsumfang:
- Programmatische Konfiguration von Wegen.
- Wegesuche zu einem Wegpunkt von dem durch room.lua erkannten Wegpunkt aus.
- Merken des vorigen Wegpunkts und Rückkehr zu diesem (mittels M-7).
- Flexible Erweiterung mittels Wege-Handlern in Wegskripten, z.B. für
  Blocker-Erkennung.

Nutzung:
- #go nachWegpunkt (von einem bekannten Wegpunkt aus)
- #go vonWegpunkt nachWegpunkt
- #go -x (bricht aktuellen Weg ab)
- M-7 - gehe zu letzten Startpunkt zurück

Wege müssen programmiert werden. Mit wegdef wird ein einfacher Weg definiert. Mit wegdefx
wird auch der Rückweg definiert (wenn denn alle einzelnen Schritte umdrehbar sind). Mit
'/dopath' können dabei auch tf-artige /dopath-Teilwege genutzt werden.

    local ws     = require 'ways'
    ws.wegdefx('p3', 'gob', '/dopath 2 o 2 s sw;w;w')

## base.lua

Um verschiedene Terminals und Clients zu unterstützten, beschränken sich die Keybindings
auf folgende Tasten:

- F1 bis F12
- S-F1 bis S-F8
- M-0 bis M-9
- M-a bis M-z
- C-a bis C-z

Tasten können mit table base.keymap belegt werden:

    local base = require 'base'
    base.keymap.M_a = function() ... end
    base.keymap.C_n = 'nordoben'

Der Zustand wird zweigeteilt in json-Files gespeichert:
- charname.json speichert den charakterspezifischen Zustand (Items usw.)
- common.json speichert globale Daten (Raumnotizen usw.) - bei Nutzung mehrerer Charaktere
  werden diese Daten ggf. überschrieben!
- Mit der Environment-Variable MG\_LUA\_SAVE\_DIR wird das zum Speichern genutzte
  Verzeichnis konfiguriert.

Nutzung:
- #reboot - reset alle Module
- #s ...  - schaetz für alle Gilden
- #i ...  - identifiziere für alle Gilden
- #se     - save and sleep
- #para n - setzt Para-Welt n


# Client-Unterstützung

Alle Skripte nutzen client-spezifische Funktionen nur über einen Adapter. Dieser
wird global unter `client` erwartet und von `main.lua` geladen.

API des Adapters:

```lua
return {
  useKeyListener,
  createLogger,
  line,
  cecho,
  createStandardAlias,
  executeStandardAlias,
  createSubstrTrigger,
  createRegexTrigger,
  createMultiLineRegexTrigger,
  enableTrigger,
  disableTrigger,
  killTrigger,
  createTimer,
  send,
  xtitle,
  json,
  regex,
  login,
  startLog,
  stopLog
}
```

## regex
```lua
local re = client.regex(pattern)
local result = re:replace(s, replacement)
```
Ersetzt alle Vorkommen von pattern in s durch replacement.

```lua
local re = client.regex(pattern)
local matches = re:match(s)
```
Liefert nil, wenn s nicht auf pattern passt. Ansonsten wird eine Table
aller Matches geliefert: `matches = {match1, match2, ...}`


# mg-lua im Client nutzen

siehe Skripte unter startup/


# Client installieren

## blightmud

### rust with cargo

fedora:
- sudo dnf install rust cargo 

ubuntu:
- sudo snap install rustup
- rustup toolchain install stable

### dependencies

fedora:
- sudo dnf install pkg-config g++
- sudo dnf install openssl-devel alsa-lib-devel clang

ubuntu:
- sudo apt install pkg-config
- sudo apt install libssl-dev libasound2-dev clang

### compile & install (& update)

- cargo install --git https://github.com/blightmud/blightmud blightmud

oder

- git clone https://github.com/blightmud/blightmud
- cd blightmud
- cargo install --path .

## tf rebirth

### dependencies von mg-lua

lua-Libs:
- luarocks --local install luafilesystem
- luarocks --local install luajson
- luarocks --local install lrexlib-pcre2

### compile & install

packages (ubuntu):
- lua5.4
- liblua5.4-0
- libpcre3-dev

packages (fedora):
- pcre-devel
- lua-devel

tools:
- gcc
- make

- Quelle: https://github.com/ingwarsw/tinyfugue.git
- tf rebirth mit gmcp+lua
- ./configure --enable-gmcp --enable-lua
- make install

## mudlet

Die Anbindung an Mudlet ist veraltet und funktioniert derzeit nicht.
- Pfad anpassen in:
  mudlet/start-externe-skripte.xml
- mudlet starten und folgende packages importieren:
  mudlet/start-externe-skripte.xml
  mudlet/dokey-package.xml
- settings -> GMCP aktivieren
