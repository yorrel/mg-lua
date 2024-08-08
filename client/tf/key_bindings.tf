;; Alle Tasten werden direkt auf eine zentrale lua-Funktion gemappt.
;; In tf können keine Tasten belegt werden.
;;
;; Fn
;; S_Fn
;; C_x
;; M_x


;; ---------------------------------------------------------------------------
;; Ctrl-<key>
;; C_c and C_l - reserved by blightmud
;; C_m and C_z - reserved by tf

/unbind ^X^R
/unbind ^X^V
/unbind ^X^?
/unbind ^X[
/unbind ^X]
/unbind ^X{
/unbind ^X}

/def -b'^a' = /callLuaKey C_a
/def -b'^b' = /callLuaKey C_b
/def -b'^d' = /callLuaKey C_d
/def -b'^e' = /callLuaKey C_e
/def -b'^f' = /callLuaKey C_f
/def -b'^g' = /callLuaKey C_g
/def -b'^h' = /callLuaKey C_h
/def -b'^i' = /callLuaKey C_i
/def -b'^j' = /callLuaKey C_j
/def -b'^k' = /callLuaKey C_k
/def -b'^n' = /callLuaKey C_n
/def -b'^o' = /callLuaKey C_o
/def -b'^p' = /callLuaKey C_p
/def -b'^q' = /callLuaKey C_q
/def -b'^r' = /callLuaKey C_r
/def -b'^s' = /callLuaKey C_s
/def -b'^t' = /callLuaKey C_t
/def -b'^u' = /callLuaKey C_u
/def -b'^v' = /callLuaKey C_v
/def -b'^w' = /callLuaKey C_w
/def -b'^x' = /callLuaKey C_x
/def -b'^y' = /callLuaKey C_y


;; ---------------------------------------------------------------------------
;; Funktionstasten

/def key_f1 = /callLuaKey F1
/def key_f2 = /callLuaKey F2
/def key_f3 = /callLuaKey F3
/def key_f4 = /callLuaKey F4
/def key_f5 = /callLuaKey F5
/def key_f6 = /callLuaKey F6
/def key_f7 = /callLuaKey F7
/def key_f8 = /callLuaKey F8
/def key_f9 = /callLuaKey F9
/def key_f10 = /callLuaKey F10
/def key_f11 = /callLuaKey F11
/def key_f12 = /callLuaKey F12

;; standard key bindings fuer S_Fn
/def key_shift_f1 = /callLuaKey S_F1
/def key_shift_f2 = /callLuaKey S_F2
/def key_shift_f3 = /callLuaKey S_F3
/def key_shift_f4 = /callLuaKey S_F4
/def key_shift_f5 = /callLuaKey S_F5
/def key_shift_f6 = /callLuaKey S_F6
/def key_shift_f7 = /callLuaKey S_F7
/def key_shift_f8 = /callLuaKey S_F8
/def key_shift_f9 = /callLuaKey S_F9
/def key_shift_f10 = /callLuaKey S_F10
/def key_shift_f11 = /callLuaKey S_F11
/def key_shift_f12 = /callLuaKey S_F12

;; alternative key bindings fuer Fn und S_Fn
/def -b'^[[1;2P'  = /callLuaKey S_F1
/def -b'^[[1;2Q'  = /callLuaKey S_F2
/def -b'^[[1;2R'  = /callLuaKey S_F3
/def -b'^[[1;2S'  = /callLuaKey S_F4
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

/def -b'^[a' = /callLuaKey M_a
/def -b'^[b' = /callLuaKey M_b
/def -b'^[c' = /callLuaKey M_c
/def -b'^[d' = /callLuaKey M_d
/def -b'^[e' = /callLuaKey M_e
/def -b'^[f' = /callLuaKey M_f
/def -b'^[g' = /callLuaKey M_g
/def -b'^[h' = /callLuaKey M_h
/def -b'^[i' = /callLuaKey M_i
/def -b'^[j' = /callLuaKey M_j
/def -b'^[k' = /callLuaKey M_k
/def -b'^[l' = /callLuaKey M_l
/def -b'^[m' = /callLuaKey M_m
/def -b'^[n' = /callLuaKey M_n
/def -b'^[o' = /callLuaKey M_o
/def -b'^[p' = /callLuaKey M_p
/def -b'^[q' = /callLuaKey M_q
/def -b'^[r' = /callLuaKey M_r
/def -b'^[s' = /callLuaKey M_s
/def -b'^[t' = /callLuaKey M_t
/def -b'^[u' = /callLuaKey M_u
/def -b'^[v' = /callLuaKey M_v
/def -b'^[w' = /callLuaKey M_w
/def -b'^[x' = /callLuaKey M_x
/def -b'^[y' = /callLuaKey M_y
/def -b'^[z' = /callLuaKey M_z

/def -b'^[0' = /callLuaKey M_0
/def -b'^[1' = /callLuaKey M_1
/def -b'^[2' = /callLuaKey M_2
/def -b'^[3' = /callLuaKey M_3
/def -b'^[4' = /callLuaKey M_4
/def -b'^[5' = /callLuaKey M_5
/def -b'^[6' = /callLuaKey M_6
/def -b'^[7' = /callLuaKey M_7
/def -b'^[8' = /callLuaKey M_8
/def -b'^[9' = /callLuaKey M_9


;; ---------------------------------------------------------------------------
;; Sondertasten

;; M_,
/def -b'^[,' = /dokey_home %; /let _v=$[input("#go ")] %; /dokey NEWLINE
