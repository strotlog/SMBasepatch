; data and code moved from items.asm to reduce usage of very in-demand bank $84 (PLMs bank)

; Graphics pointers for items (by item index)
; relocatable to any bank
sm_item_graphics:
    ; highest bit clear means this item type's gfx is always loaded already,
    ; and the value is an item gfx index that can be stored directly at $7e:df0c,x
    dw $0008 ; Energy Tank
    dw $000A ; Missile
    dw $000C ; Super Missile
    dw $000E ; Power Bomb
    ; pointers to a 10-byte graphics data entry anywhere in bank $84 (this value will be saved by $84:8764 Load item PLM GFX)
    ; for example: $84:E12F in vanilla ROM contains: $8000 (implied bank $89:8000: bomb plm graphic data), followed by 8 palette indices
    ;              $84:E12F: $8000,00,00,00,00,00,00,00,00
    dw $E12F ; Bombs (graphics at $89:8000)
    dw $E15D ; Charge (graphics at $89:8B00)
    dw $E18B ; Ice Beam (graphics at $89:8C00)
    dw $E1B9 ; Hi-Jump (graphics at $89:8400)
    dw $E1E7 ; Speed booster (graphics at $89:8A00)
    dw $E215 ; Wave beam (graphics at $89:8D00)
    dw $E243 ; Spazer (graphics at $89:8F00)
    dw $E271 ; Spring ball (graphics at $89:8200)
    dw $E2A3 ; Varia suit (graphics at $89:8300)
    dw $E2D8 ; Gravity suit (graphics at $89:8100)
    dw $E30D ; X-ray scope (graphics at $89:8900)
    dw $E33A ; Plasma beam (graphics at $89:8E00)
    dw $E368 ; Grapple beam (graphics at $89:8800)
    dw $E395 ; Space jump (graphics at $89:8600)
    dw $E3C3 ; Screw attack (graphics at $89:8500)
    dw $E3F1 ; Morph ball (graphics at $89:8700)
    dw $E41F ; Reserve tank (graphics at $89:9000)
    dw plm_graphics_entry_offworld_progression_item
    dw plm_graphics_entry_offworld_item

i_item_setup_shared:
    phy : phx
    tyx
    lda.l $7e1dc7, x                    ; Load PLM room argument (tells us which of the 100 items this is)
    asl #3                          ; Multiply by 8 for table width
    tax
    lda.l rando_item_table+$2, x       ; Load item id from item table
    cmp #$0015
    bmi .all_items
    ; offworld item:
    lda #$0015              ; item ids over 20 (#$0015 and up) are used to display off-world item names, but the graphics are always either item gfx #$0015 or #$0016
    clc : adc.l rando_item_table+$6, x      ; add one if off-world item isnt progression
.all_items
    asl ; multiply by 2 for table width
    tax
    lda.l sm_item_graphics, x
    bpl .alwaysloaded   ; if high bit is not set, this isn't a pointer

    plx : ply
    rtl

.alwaysloaded
    plx : ply
    tyx
    sta.l $7edf0c, x
    rtl

