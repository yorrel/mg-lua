
;; fuer /xtitle
/REQUIRE tools.tf
;; fuer /alias
/REQUIRE alias.tf


;; allgemeine Einstellungen
/more off
;; mehr Warnungen zum Code ausgeben
/set pedantic=on


;; Laden weiterer tf-Skripte
/def kload = /load %{MG_LUA_DIR}/tf/%{*}


;; ---------------------------------------------------------------------------
;; weitere Module laden

/kload key_bindings.tf
/kload status.tf


;; ---------------------------------------------------------------------------
;; tf5 rebirth: Schnittstelle tf <-> lua

;; Aufruf von lua: lua-definierten Keys und Aliases
/def callLuaAlias = /calllua callLuaAlias %{*}
/def callLuaKey = /calllua tf_dokey %{*}

;; Erzeugung von tf-Aliases aus lua heraus
/def createLuaAlias = \
  /alias #%{*} /callLuaAlias %{*},%%{*}

;; Erzeugung von Triggern aus lua heraus
/set LUA_TF_BRIDGE_TRIGGER_TYP=%;
/set LUA_TF_BRIDGE_TRIGGER_SWITCHES=%;
/set LUA_TF_BRIDGE_TRIGGER_PATTERN=%;
/set LUA_TF_BRIDGE_TRIGGER_NAME=%;
/set LUA_TF_BRIDGE_TRIGGER_ID=%;

;; arg: varname
/def unmask_pattern = \
  /let _val=%; \
  /test _val:=%{1}%; \
  /let _val=$[replace("&backslash&","\\\\",_val)]%;\
  /let _val=$[replace("&dollar&","$",_val)]%;\
  /set %{1}=%{_val}

/def createLuaTrigger = \
  /def -m%{LUA_TF_BRIDGE_TRIGGER_TYP} %{LUA_TF_BRIDGE_TRIGGER_SWITCHES} -t'%{LUA_TF_BRIDGE_TRIGGER_PATTERN}' %{LUA_TF_BRIDGE_TRIGGER_NAME} = /callluaTriggerCmd %{LUA_TF_BRIDGE_TRIGGER_ID}#%%{*}#

;; aus lua erzeugt tf-Trigger aufrufen und Matches mitgeben
;; regex+substr: %{*} hat die Form ID#full_text# (ohne fuehrende Spaces)
/def callluaTriggerCmd = \
  /calllua _executeTriggerCmd #%{P1}#%{P2}#%{P3}#%{P4}#%{P5}#%{P6}#%{P7}#%{P8}#%{*}#


;; ---------------------------------------------------------------------------
;; lua starten

/echo >>> starte lua...
/eval /loadlua %{MG_LUA_DIR}/main.lua


;; ---------------------------------------------------------------------------
;; gmcp

;; gmcp nach lua weiterleiten
/def -h'GMCP' _gmcp_catch_all = \
  /calllua parseGmcpData %{*}

;; gmcp starten
/def start_gmcp = \
  /echo -aCcyan >>> GMCP starten! %; \
  /let helloMsg=Core.Hello { "client": "TinyFugue", "version": "5.0" }%;\
  /test gmcp({helloMsg}) %; \
  /test gmcp("Core.Debug 1") %; \
  /let activateMsg=Core.Supports.Set [ "MG.char 1", "MG.room 1" ]%; \
  /test gmcp({activateMsg})

;; nach dem connect gmcp starten
/def -h"CONNECT" _gmcp_init = /repeat -0:0:1 1 /start_gmcp

;; Tests ausfuehren
/def all_tests = /loadlua %{MG_LUA_DIR}/test/all-tests.lua
