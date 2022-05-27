pushpc
org $81b303 ; hook New save file function ($81:B2CB) at a point such that after we return, it won't zero anything we wrote
    jsl start_item
    nop
    nop
pullpc ; resume the org directive previously specified (by the parent file that includes this one)


; the data here is designed to be overwritten by the rando patcher in order to yield the player's desired starting loadout:
; whatever's here overwrites $7e:09a2 : equipped items, collected items, equipped beams, and collected beams
start_item_data_major:
    dw $0000, $0000, $0000, $0000
; whatever's here overwrites $7e:09c2 : health and the 3 ammo counts (current and max of each)
start_item_data_minor:
    dw $0063, $0063, $0000, $0000
    dw $0000, $0000, $0000, $0000
; whatever's here overwrites $7e:09d4 : current and max reserve
start_item_data_reserve:
    dw $0000, $0000

start_item:
    ldx #$0000
-
    lda.l start_item_data_major, x
    sta.l $7E09A2, x
    inx 
    inx
    cpx #$0008
    bne -
    ldx #$0000
-
    lda.l start_item_data_minor, x
    sta.l $7E09C2, x
    inx
    inx
    cpx #$0010
    bne -
    ldx #$0000
-
    lda.l start_item_data_reserve, x
    sta.l $7E09D4, x
    inx
    inx
    cpx #$0004
    bne -
    jsr update_graphic

    ; (no overwritten instructions to return - we overwrote zeroing reserves - and A is safe to clobber)
    rtl

update_graphic:
    cmp #$0000
    beq +
    lda #$0001
    sta.l $7E09C0
 +   
    lda.l $7E09A2
    bit #$4000 ; grapple equipped bit
    beq +
    jsl $809A2E   ; thanks PierRoulette - adds grapple beam to hud
+    
    lda.l $7E09A2
    bit #$8000 ; x-ray equipped bit
    beq +
    jsl $809A3E   ; thanks PierRoulette - adds xray scope to hud
+
    jsl $90AC8D   ; thanks PierRoulette - updates beam tiles and palette
    rts
