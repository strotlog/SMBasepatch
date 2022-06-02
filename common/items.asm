!IBranchItem = #$887C
!ISetItem = #$8899
!ILoadSpecialGraphics = #$8764
!ISetGoto = #$8A24
!ISetPreInstructionCode = #$86C1
!IDrawCustom1 = #$E04F
!IDrawCustom2 = #$E067
!IGoto = #$8724
!IKill = #$86BC
!IPlayTrackNow = #$8BDD
!IJSR = #$8A2E
!ISetCounter8 = #$874E
!IGotoDecrement = #$873F
!IGotoIfDoorSet = #$8A72
!ISleep = #$86B4
!IVisibleItem = #i_visible_item
!IChozoItem = #i_chozo_item
!IHiddenItem = #i_hidden_item
!ILoadCustomGraphics = #i_load_custom_graphics
!IPickup = #i_live_pickup
!IStartDrawLoop = #i_start_draw_loop
!IStartHiddenDrawLoop = #i_start_hidden_draw_loop

!ITEM_RAM = $7E09A2

; SM Item Patches (bank $84)

;pushpc
;org $8095f7
;    jsl nmi_read_messages : nop
;pullpc

; Add custom PLM that can asynchronously load in items
; ALL items in archipelago sm will use one of these 3 PLMs:
archipelago_visible_item_plm:
    dw i_visible_item_setup, v_item       ;f870 if we're org'ed at $84f870
archipelago_chozo_item_plm:
    dw i_visible_item_setup, c_item       ;f874 if we're org'ed at $84f870
archipelago_hidden_item_plm:
    dw i_hidden_item_setup,  h_item       ;f878 if we're org'ed at $84f870


; new PLM graphics (only 2)
; each entry is the full set of arguments (10 bytes) for vanilla function $84:8764 Instruction - load item PLM GFX
;     see e.g. vanilla $84:E15B-E167 for an example structure of the data (charge beam plm)
;     this table is at $84f87c IF we're orged at $84f870
plm_graphics_entry_offworld_progression_item:
    dw offworld_graphics_data_progression_item    ; off-world progression item (pointer = $9100)
prog_item_eight_palette_indices: ; symbol provided for AP patcher to overwrite these 8 bytes:
    db $00, $00, $00, $00, $00, $00, $00, $00
; table entry 2 of 2:
plm_graphics_entry_offworld_item:
    dw offworld_graphics_data_item    ; off-world item (pointer = $9200)
nonprog_item_eight_palette_indices: ; symbol provided for AP patcher to overwrite these 8 bytes:
    db $00, $00, $00, $00, $00, $00, $00, $00

pushpc
org $899100
offworld_graphics_data_progression_item:
org $899200
offworld_graphics_data_item:
; the randomizer's patcher will write the actual graphics here at $89:9100 and $89:9200
pullpc ; back to bank $84
v_item:
    dw !IVisibleItem
c_item:
    dw !IChozoItem
h_item:
    dw !IHiddenItem


sm_item_table:
    ; pickup, qty,   msg,   type,  ext2,  ext3,  loop,  hloop
    dw $8968, $0064, $0000, $0000, $0000, $0000, #p_etank_loop, #p_etank_hloop     ; E-Tank
    dw $89A9, $0005, $0000, $0001, $0000, $0000, #p_missile_loop, #p_missile_hloop ; Missiles
    dw $89D2, $0005, $0000, $0002, $0000, $0000, #p_super_loop, #p_super_hloop     ; Super Missiles
    dw $89FB, $0005, $0000, $0003, $0000, $0000, #p_pb_loop, #p_pb_hloop           ; Power Bombs
        
    dw $88F3, $1000, $0013, $0004, $0000, $0000, $0000, $0000      ; Bombs
    dw $88B0, $1000, $000E, $0005, $0000, $0000, $0000, $0000      ; Charge beam
    dw $88B0, $0002, $000F, $0005, $0000, $0000, $0000, $0000      ; Ice beam
    dw $88F3, $0100, $000B, $0004, $0000, $0000, $0000, $0000      ; Hi-jump
    dw $88F3, $2000, $000D, $0004, $0000, $0000, $0000, $0000      ; Speed booster
    dw $88B0, $0001, $0010, $0005, $0000, $0000, $0000, $0000      ; Wave beam
    dw $88B0, $0004, $0011, $0005, $0000, $0000, $0000, $0000      ; Spazer
    dw $88F3, $0002, $0008, $0004, $0000, $0000, $0000, $0000      ; Spring ball
    dw $88F3, $0001, $0007, $0004, $0000, $0000, $0000, $0000      ; Varia suit
    dw $88F3, $0020, $001A, $0004, $0000, $0000, $0000, $0000      ; Gravity suit
    dw $8941, $8000, $0000, $0004, $0000, $0000, $0000, $0000      ; X-ray scope
    dw $88B0, $0008, $0012, $0005, $0000, $0000, $0000, $0000      ; Plasma
    dw $891A, $4000, $0000, $0004, $0000, $0000, $0000, $0000      ; Grapple
    dw $88F3, $0200, $000C, $0004, $0000, $0000, $0000, $0000      ; Space jump
    dw $88F3, $0008, $000A, $0004, $0000, $0000, $0000, $0000      ; Screw attack
    dw $88F3, $0004, $0009, $0004, $0000, $0000, $0000, $0000      ; Morph ball
    dw $8986, $0064, $0000, $0006, $0000, $0000, $0000, $0000      ; Reserve tank
    dw $88F3, $0004, $0009, $0004, $0000, $0000, $0000, $0000      ; off-world progression item
    dw $88F3, $0004, $0009, $0004, $0000, $0000, $0000, $0000      ; off-world item

i_visible_item:
    lda #$0006
    jsr i_load_rando_item
    rts

i_chozo_item:
    lda #$0008
    jsr i_load_rando_item
    rts

i_hidden_item:
    lda #$000A
    jsr i_load_rando_item
    rts

p_etank_loop:
    dw $0004, $a2df
    dw $0004, $a2e5
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_etank_loop

p_missile_loop:
    dw $0004, $A2EB
    dw $0004, $A2F1
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_missile_loop

p_super_loop:
    dw $0004, $A2F7
    dw $0004, $A2FD
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_super_loop

p_pb_loop:
    dw $0004, $A303
    dw $0004, $A309
    dw !IBranchItem, p_visible_item_end
    dw !IGoto, p_pb_loop

p_etank_hloop:
    dw $0004, $a2df
    dw $0004, $a2e5
    dw !IGotoDecrement, p_etank_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_missile_hloop:
    dw $0004, $A2EB
    dw $0004, $A2F1
    dw !IGotoDecrement, p_missile_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_super_hloop:
    dw $0004, $A2F7
    dw $0004, $A2FD
    dw !IGotoDecrement, p_super_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_pb_hloop:
    dw $0004, $A303
    dw $0004, $A309
    dw !IGotoDecrement, p_pb_hloop
    dw !IJSR, $e020
    dw !IGoto, p_hidden_item_loop2

p_visible_item:
    dw !ILoadCustomGraphics
    dw !IBranchItem, .end
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !IStartDrawLoop
    .loop
    dw !IBranchItem, .end
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGoto, .loop
    .trigger
    dw !ISetItem
    dw SOUNDFX_84 : db !Click
    dw !IPickup
    .end
    dw !IGoto, $dfa9

p_chozo_item:
    dw !ILoadCustomGraphics
    dw !IBranchItem, .end
    dw !IJSR, $dfaf
    dw !IJSR, $dfc7
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !ISetCounter8 : db $16
    dw !IStartDrawLoop
    .loop
    dw !IBranchItem, .end
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGoto, .loop
    .trigger
    dw !ISetItem
    dw SOUNDFX_84 : db !Click
    dw !IPickup
    .end
    dw $0001, $a2b5
    dw !IKill   

p_hidden_item:
    dw !ILoadCustomGraphics
    .loop2
    dw !IJSR, $e007
    dw !IBranchItem, .end
    dw !ISetGoto, .trigger
    dw !ISetPreInstructionCode, $df89
    dw !ISetCounter8 : db $16
    dw !IStartHiddenDrawLoop
    .loop
    dw !IBranchItem, .end
    dw !IDrawCustom1
    dw !IDrawCustom2
    dw !IGotoDecrement, .loop
    dw !IJSR, $e020
    dw !IGoto, .loop2
    .trigger
    dw !ISetItem
    dw SOUNDFX_84 : db !Click
    dw !IPickup
    .end
    dw !IJSR, $e032
    dw !IGoto, .loop2

SOUNDFX_84:
    jsl SOUNDFX
    rts

i_start_draw_loop:
    phy : phx
    lda $1dc7, x              ; Load PLM room argument
    asl #3 : tax
    lda.l rando_item_table+$2, x ; Load item id
    cmp #$0015
    bmi .all_items
    ; offworld item:
    lda #$0015              ; item ids over 20 (#$0015 and up) are used to display off-world item names, but the graphics are always either item gfx #$0015 or #$0016
    clc : adc.l rando_item_table+$6, x      ; add one if off-world item isnt progression
.all_items
    asl #4
    clc : adc #$000C
    tax
    lda sm_item_table, x      ; Load next loop point if available
    beq .custom_item
    plx : ply
    tay
    rts

.custom_item
    plx
    ply
    rts

i_start_hidden_draw_loop:
    phy : phx
    lda $1dc7, x              ; Load PLM room argument
    asl #3 : tax
    lda.l rando_item_table+$2, x ; Load item id
    cmp #$0015
    bmi .all_items
    ; offworld item:
    lda #$0015              ; item ids over 20 (#$0015 and up) are used to display off-world item names, but the graphics are always either item gfx #$0015 or #$0016
    clc : adc.l rando_item_table+$6, x      ; add one if off-world item isnt progression
.all_items
    asl #4
    clc : adc #$000E
    tax
    lda sm_item_table, x      ; Load next loop point if available
    beq .custom_item
    plx : ply
    tay
    rts

.custom_item
    plx
    ply
    rts


i_load_custom_graphics:
    phy : phx : phx
    lda $1dc7, x                   ; Load PLM room argument (tells us which of the 100 items this is)
    asl #3                         ; Multiply by 8 for table width
    tax
    lda.l rando_item_table+$2, x      ; Load item id from item table
    cmp #$0015
    bmi .all_items
    ; offworld item:
    lda #$0015              ; item ids over 20 (#$0015 and up) are used to display off-world item names, but the graphics are always either item gfx #$0015 or #$0016
    clc : adc.l rando_item_table+$6, x      ; add one if off-world item isnt progression
.all_items
    plx

    asl ; multiply by 2 for table width
    tax
    lda.l sm_item_graphics, x
    bpl .alwaysloaded   ; if high bit is not set, this isn't a pointer
    tay ; Y = pointer to 10-byte graphics entry to load (implied bank $84)
    plx ; X = PLM index again
    jsr $8764               ; Jump to original PLM graphics loading routine ($84:8764)
    ply
    rts

.alwaysloaded
    tax
    lda.b $00, x
    plx ; X = PLM index again
    sta.l $7edf0c, x
    ply
    rts

i_visible_item_setup:
    jsl i_item_setup_shared
    jmp $ee64 ; generic visible item setup

i_hidden_item_setup:
    jsl i_item_setup_shared
    jmp $ee8e


i_load_rando_item:
    cmp #$0006 : bne +
    ldy #p_visible_item
    bra .end
+   cmp #$0008 : bne +    
    ldy #p_chozo_item
    bra .end
+   ldy #p_hidden_item

.end
    rts

; Pick up SM item
i_live_pickup:
    jsl i_live_pickup_multiworld
    rts

; Item index to receive in A (any item in this world touched by samus)
perform_item_pickup:
    asl : asl : asl : asl
    phx
    clc
    adc #sm_item_table ; A contains pointer to pickup routine from item table
    tax
    tay
    iny : iny          ; Y points to data to be used in item pickup routine
    jsr ($0000,x)
    plx
    rtl
