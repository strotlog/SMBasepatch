;
; Patches to support starting at any given location in the game
; by injecting a save station at X/Y coordinates in the specified room.
; 
; Requires adding a new save station with ID: 7 for the correct region in the save station table as well.
;

!savestation_id = $07

org $82e8d5
    jsl inject_savestation
org $82eb8b
    jsl inject_savestation
org $82804e
    jsr start_anywhere

org $8ffd00
startroom_region:
    dw $0000
startroom_id:
    dw $92fd
startroom_save_plm:
    dw $b76f : db $05, $0a : dw $0007

org $82fd00
start_anywhere:
    lda.l startroom_id
    beq .ret

    ; Make sure game mode is 1f
    lda.l $7e0998
    cmp.w #$001f
    bne .ret
    
    ; Check if samus saved energy is 00, if it is, run startup code
    lda.l $7ed7e2
    bne .ret

    lda.l startroom_region
    sta.l $7e079F
    lda #$0007
    sta.l $7e078B

.ret
    jsr $819B
    rts

inject_savestation:
    lda.l $7e079b    ; Load room id
    cmp.l startroom_id
    bne .end
                 
    lda.l #startroom_save_plm
    tax
    lda.l $8f0000, x   ; (rom PLM room population definitions are always in bank $8f)
    jsl $84846a  ; create PLM

.end
    jsl $8FE8A3  ; Execute door ASM
    rtl
