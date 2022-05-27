pushpc
org $8b8078 ; hook start of gameplay @ $8B:8000
    ldx #$0000
    jsl start_item
    nop
    nop
pullpc ; resume the org directive previously specified (by the parent file that includes this one)


start_item_data_major:
    dw $0000, $0000, $0000, $0000
start_item_data_minor:
    dw $0063, $0063, $0000, $0000
    dw $0000, $0000, $0000, $0000
start_item_data_reserve:
    dw $0000, $0000

start_item:
-
    lda start_item_data_major, x
    sta $7E09A2, x
    inx 
    inx
    cpx #$0008
    bne -
    ldx #$0000
-
    lda start_item_data_minor, x
    sta $7E09C2, x
    inx
    inx
    cpx #$0010
    bne -
    ldx #$0000
-
    lda start_item_data_reserve, x
    sta $7E09D4, x
    inx
    inx
    cpx #$0004
    bne -
    jsr update_graphic

    ; restore overwritten instructions
    stz $0590
    stz $099E
    stz $0723
    rtl

update_graphic:
    cmp #$0000
    beq +
    lda #$0001
    sta $7E09C0    
 +   
    lda $7E09A2
    bit #$4000
    beq +
    jsl $809A2E   ; thanks PierRoulette
+    
    lda $7E09A2
    bit #$8000
    beq +
    jsl $809A3E   ; thanks PierRoulette
+
    jsl $90AC8D   ; thanks PierRoulette
    rts
