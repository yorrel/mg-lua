
;; die eigentlichen Werte kommen aus den lua-Skripten

/set LP=999
/set LP_STYLE=B
/set GIFT=_
/set GIFT_STYLE=B
/set KP=999
/set VORSICHT=
/set FLUCHTRICHTUNG=
/set PARA=?
/set PARA_STYLE=B
/set EBLOCK_LOCKED=_
/set EBLOCK_VOLL=_
/set ROOMID=_____

/set status_attr=B
/set STATUS_LP=
/set STATUS_STD=
/set STATUS_GILDE=
/set STATUS_VSFR=VS:999_FR:_____
/set STATUS_PARA=P9

;/status_rm @more
/status_rm @world
/status_rm @read
/status_rm @active
/status_rm @log
/status_rm @mail
/status_rm insert
/status_rm kbnum
/status_rm @clock
;; eigene Felder
/status_add STATUS_LP:6:B
/status_add -ASTATUS_LP -s0 STATUS_GIFT:1:B
/status_add STATUS_STD:7:BCcyan :1
/status_add STATUS_GILDE:27:B :1
/status_add STATUS_VSFR:15:Cgreen
/status_add STATUS_PARA:2:B
/status_add ROOMID:6:B

;; aufzurufen nachdem die aktuellen LP gesetzt wurden in Variable LP
/def update_status_fields = \
  /status_edit STATUS_LP:6:%{LP_STYLE} %; \
  /status_edit STATUS_GIFT:1:%{GIFT_STYLE} %; \
  /status_edit STATUS_PARA:2:%{PARA_STYLE}

;; aufzurufen nach Aktualisierung LP/KP, Para, VS/FR, EBlock
/def status_update = \
  /let _para=__%; \
  /if ({PARA}>0) /let _para=$[strcat("P", {PARA})]%; /endif %; \
  /set STATUS_PARA=%{_para}%; \
  \
  /let _fl=$[substr(strcat({FLUCHTRICHTUNG},"_____"), 0, 5)]%; \
  /set STATUS_VSFR=$[pad("VS:", 3, {VORSICHT}, 3, "_FR:", 4, {_fl}, 5)]%; \
  \
  /set STATUS_LP=$[pad("LP:", 3, {LP}, 3)]%; \
  /set STATUS_GIFT=%{GIFT}%; \
  /set STATUS_STD=$[pad("KP", 2, {EBLOCK_LOCKED}, 1, {EBLOCK_VOLL}, 1, {KP}, 3)]%; \
  /update_status_fields

