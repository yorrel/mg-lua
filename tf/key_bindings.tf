;; Alle Tasten werden direkt auf eine zentrale lua-Funktion gemappt.
;; In tf können keine Tasten belegt werden.
;;
;; Fn
;; S-Fn  
;; M-x
;; C-xa

;; fuehrt die Funktion einer Taste aus, nur intern zu verwenden (einfach alle nach lua mappen)
/def keydo = /callLuaKey $[replace("-","_",{*})]


;; ---------------------------------------------------------------------------
;; Ctrl-<key>
;; C-c and C-l - reserved by blightmud
;; C-m and C-z - reserved by tf

/unbind ^X^R
/unbind ^X^V
/unbind ^X^?
/unbind ^X[
/unbind ^X]
/unbind ^X{
/unbind ^X}

/def -b'^a' = /keydo C-a
/def -b'^b' = /keydo C-b
/def -b'^d' = /keydo C-d
/def -b'^e' = /keydo C-e
/def -b'^f' = /keydo C-f
/def -b'^g' = /keydo C-g
/def -b'^h' = /keydo C-h
/def -b'^i' = /keydo C-i
/def -b'^j' = /keydo C-j
/def -b'^k' = /keydo C-k
/def -b'^n' = /keydo C-n
/def -b'^o' = /keydo C-o
/def -b'^p' = /keydo C-p
/def -b'^q' = /keydo C-q
/def -b'^r' = /keydo C-r
/def -b'^s' = /keydo C-s
/def -b'^t' = /keydo C-t
/def -b'^u' = /keydo C-u
/def -b'^v' = /keydo C-v
/def -b'^w' = /keydo C-w
/def -b'^x' = /keydo C-x
/def -b'^y' = /keydo C-y


;; ---------------------------------------------------------------------------
;; Funktionstasten

/def key_f1 = /keydo F1
/def key_f2 = /keydo F2
/def key_f3 = /keydo F3
/def key_f4 = /keydo F4
/def key_f5 = /keydo F5
/def key_f6 = /keydo F6
/def key_f7 = /keydo F7
/def key_f8 = /keydo F8
/def key_f9 = /keydo F9
/def key_f10 = /keydo F10
/def key_f11 = /keydo F11
/def key_f12 = /keydo F12

;; standard key bindings fuer S-Fn
/def key_shift_f1 = /keydo S-F1
/def key_shift_f2 = /keydo S-F2
/def key_shift_f3 = /keydo S-F3
/def key_shift_f4 = /keydo S-F4
/def key_shift_f5 = /keydo S-F5
/def key_shift_f6 = /keydo S-F6
/def key_shift_f7 = /keydo S-F7
/def key_shift_f8 = /keydo S-F8
/def key_shift_f9 = /keydo S-F9
/def key_shift_f10 = /keydo S-F10
/def key_shift_f11 = /keydo S-F11
/def key_shift_f12 = /keydo S-F12

;; alternative key bindings fuer Fn und S-Fn
/def -b'^[[1;2P'  = /keydo S-F1
/def -b'^[[1;2Q'  = /keydo S-F2
/def -b'^[[1;2R'  = /keydo S-F3
/def -b'^[[1;2S'  = /keydo S-F4
/def key_f13 = /key_shift_f1
/def key_f14 = /key_shift_f2
/def key_f15 = /key_shift_f3
/def key_f16 = /key_shift_f4
/def key_f17 = /key_shift_f5
/def key_f18 = /key_shift_f6
/def key_f19 = /key_shift_f7
/def key_f20 = /key_shift_f8


;; ---------------------------------------------------------------------------
;; Meta-<key>

/def -b'^[a' = /keydo M-a
/def -b'^[b' = /keydo M-b
/def -b'^[c' = /keydo M-c
/def -b'^[d' = /keydo M-d
/def -b'^[e' = /keydo M-e
/def -b'^[f' = /keydo M-f
/def -b'^[g' = /keydo M-g
/def -b'^[h' = /keydo M-h
/def -b'^[i' = /keydo M-i
/def -b'^[j' = /keydo M-j
/def -b'^[k' = /keydo M-k
/def -b'^[l' = /keydo M-l
/def -b'^[m' = /keydo M-m
/def -b'^[n' = /keydo M-n
/def -b'^[o' = /keydo M-o
/def -b'^[p' = /keydo M-p
/def -b'^[q' = /keydo M-q
/def -b'^[r' = /keydo M-r
/def -b'^[s' = /keydo M-s
/def -b'^[t' = /keydo M-t
/def -b'^[u' = /keydo M-u
/def -b'^[v' = /keydo M-v
/def -b'^[w' = /keydo M-w
/def -b'^[x' = /keydo M-x
/def -b'^[y' = /keydo M-y
/def -b'^[z' = /keydo M-z

/def -b'^[0' = /keydo M-0
/def -b'^[1' = /keydo M-1
/def -b'^[2' = /keydo M-2
/def -b'^[3' = /keydo M-3
/def -b'^[4' = /keydo M-4
/def -b'^[5' = /keydo M-5
/def -b'^[6' = /keydo M-6
/def -b'^[7' = /keydo M-7
/def -b'^[8' = /keydo M-8
/def -b'^[9' = /keydo M-9


;; ---------------------------------------------------------------------------
;; Sondertasten

;; M-komma
/def -b'^[,' = /dokey_home %; /let _v=$[input("#go ")] %; /dokey NEWLINE
