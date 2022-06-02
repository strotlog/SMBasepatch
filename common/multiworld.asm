; SM Multiworld support
;

; New multiworld communication stuff
!SRAM_MW_ITEMS_RECV = $702000
!SRAM_MW_ITEMS_RECV_RPTR = $702600
!SRAM_MW_ITEMS_RECV_WPTR = $702602
!SRAM_MW_ITEMS_RECV_SPTR = $702604  ; This gets updated on game save and reloaded into RPTR on game load

!SRAM_MW_ITEMS_SENT_RPTR = $702680
!SRAM_MW_ITEMS_SENT_WPTR = $702682
!SRAM_MW_ITEMS_SENT = $702700       ; [worldId, itemId, itemIndex] (need unique item index to prevent duping)

!SRAM_MW_INITIALIZED = $7026fe

!Big = #$825A
!Small = #$8289
!EmptySmall = #$8436
!Shot = #$83C5
!Dash = #$83CC
!EmptyBig = #message_EmptyBig
!PlaceholderBig = #message_PlaceholderBig

mw_init_memory:
    rep #$30
    lda.l config_multiworld
    beq +
    jsl mw_init         ; Init multiworld
+
    ;jsl $8b9146
    ; restore overwritten instructions before returning:
    sep #$30
    lda #$8F
    rtl

mw_init:
    pha : phx : phy : php
    %ai16()

    ; If already initialized, don't do it again
    lda.l !SRAM_MW_INITIALIZED
    cmp #$cafe
    beq .end

    lda #$0000
    ldx #$0000

-
    sta.l !SRAM_MW_ITEMS_RECV, x
    sta.l !SRAM_MW_ITEMS_RECV+$0400, x
    sta.l !SRAM_MW_ITEMS_RECV+$0800, x
    sta.l !SRAM_MW_ITEMS_RECV+$0C00, x
    inx : inx
    cpx #$0400
    bne -

    lda #$cafe
    sta.l !SRAM_MW_INITIALIZED

.end
    plp : ply : plx : pla
    rtl

; Write multiworld item message
; A = item id, X = byte offset of item location's row in rando_item_table (ie, location id * 8), Y = world id (all 16-bit)
mw_write_message:
    pha : phx ; for preserving
    phx : pha ; for pulling into A to write out
    lda.l !SRAM_MW_ITEMS_SENT_WPTR
    asl #3 : tax
    tya
    sta.l !SRAM_MW_ITEMS_SENT, x
    pla
    sta.l !SRAM_MW_ITEMS_SENT+$2, x
    pla
    sta.l !SRAM_MW_ITEMS_SENT+$4, x

    lda.l !SRAM_MW_ITEMS_SENT_WPTR
    inc a
    sta.l !SRAM_MW_ITEMS_SENT_WPTR
    plx : pla
    rtl

mw_save_sram:
    pha : php
    %ai16()
    lda.l !SRAM_MW_ITEMS_RECV_RPTR
    sta.l !SRAM_MW_ITEMS_RECV_SPTR
    plp : pla
    ; restore overwritten instructions
    tax
    ldy #$0000
    rtl

mw_load_sram:
    pha : php
    %ai16()
    lda.l !SRAM_MW_ITEMS_RECV_SPTR
    sta.l !SRAM_MW_ITEMS_RECV_RPTR
    plp : pla
    rtl

; Display message that we picked up someone elses item
; X = item id, Y = world id aka item owner
mw_display_item_sent:
    stx.b $c1
    sty.b $c3
    ;lda #$0168       ; With fanfare skip, no need to queue room track
    ;jsl $82e118      ; Queue room track after item fanfare
    lda #$7b49 ; magic number
    sta.b $cc
    lda #$0300 ; item sent message box override
    sta.b $ce
    lda #$0019 ; param to function: message box id of something fake but known. 19h = reserve tank. will be overridden by $ce
    jsl $858080
    stz.b $c1
    stz.b $c3
    stz.b $cc
    stz.b $ce
    rtl

; A = item id
mw_receive_item:
    pha : phx
    cmp #$0016
    beq .end                 ; skip receiving if its a Nothing item
    cmp #$0017
    beq .end                 ; skip receiving if its a No Energy item
    asl ; X =
    tax ;     byte offset within sm_item_plm_pickup_sequence_pointers for this item
    ; sound:
    lda #$0001 ; sound number
    sta.b $cc
    ldy #$00cc ; pointer to sound number
    phb ; data bank cannot be C0+ since SETFX reads from 0000,y and must access WRAM that way
    pea $7e7e
    plb : plb ; DB = $7E
    jsl SETFX
    plb ; restore DB
    lda #$0037
    jsl $809049 ; play sound #$37, or was it 1, idk TODO document
    stz.b $cc
    ; message box:
    lda #$7b49 ; magic number
    sta.b $cc
    lda #$0301 ; item received message box override
    sta.b $ce
    ; X is still the param: byte offset into sm_item_plm_pickup_sequence_pointers per above
    jsl perform_item_pickup   ; Call original item receive code in bank $84 (will eventually read the message box index from $ce)
.end
    stz.b $ce
    stz.b $cc
    plx : pla
    rts

; from varia endingtotals.asm - code copied to here so we don't depend on any jsl address without a symbol
;                               (and in order to save precious room in bank $84 for optional varia decoupling)
; Params:
;     A:     item location id (aka A parameter to $80:818E)
; Returns:
;     A/X:   Byte index ([A] >> 3)
;     $05E7: Bitmask (1 << ([A] &  7))
!CollectedItems  = $7ED86E
COLLECTTANK:
    PHA
    LDA.l !CollectedItems
    INC A
    STA.l !CollectedItems
    PLA
    ; bit math in preparation for storing to world item states bit array 
    JSL $80818E ; $80:818E: Change bit index to byte index and bitmask
    RTL


; point-in-time documentation of all item interactions (anything involving a message box) june 2022:
; mw_handle_queue (multiworld.asm) <-- receive item from network
;    sta $c3
;    if own item received from network (under remote items config) && location is not already marked collected:
;       COLLECTTANK (copied into multiworld.asm - keeps track of item count &
;                    calls vanilla helper that helps set up for setting the item location bit as collected in SRAM)
;    sta $c1
;    mw_receive_item (multiworld.asm)
;       SETFX (nofanfare.asm)
;       $80:9049 play sound
;       sta $cc, ce
;       perform_item_pickup (items.asm)
;          $84:($0000,x) x <-- x = sm_item_table[A].0
;             ends up in $85:8080 like below (see below for details)
; 
;       stz $cc, ce
;     stz $c1, c3
; 
; 
; all plms' instruction lists (i_live_pickup in items.asm)
;    i_live_pickup_multiworld (multiworld.asm)
;       mw_write_message (multiworld.asm) <- to SRAM/network, A=item, always performed
;       if we touched ANOTHER player's item:
;          mw_display_item_sent (multiworld.asm) <- show message box for other player's items
;             sta $c1, c3, cc, ce
;             $85:8080 A=message box index
;                $85:8241 Initialise message box (normally calls into function table)
;                   multiworld_messagebox_function_pointerish_calls (multiworld.asm)
;                      lda $ce
;                      PlaceholderBig (multiworld.asm)
;                          write_placeholders (multiworld.asm)
;                             lda $c1 $c3
;                      { $85:8289 small                         }
;                      {  or                                    }
;                      { $85:825A large (all multiworld boxes)  }
;                      both call:
;                         $85:82B8 Write message tilemap
;                             hook_tilemap_calc (multiworld.asm)
;                                lda $ce
;              stz $c1, c3, cc, ce
;       else - ie - we are picking up our OWN item within our world:
;          perform_item_pickup (items.asm) A=0..20
;             $84:($0000,x) <-- x = sm_item_table[A].0
;                 this ends up in $85:8080 as well (see above), but uses the vanilla message table instead of multiworld boxes


mw_handle_queue: ; receive only
    pha : phx

.loop
    lda.l !SRAM_MW_ITEMS_RECV_RPTR
    cmp.l !SRAM_MW_ITEMS_RECV_WPTR
    beq .end

    asl #2 : tax
    lda.l !SRAM_MW_ITEMS_RECV, x
    sta.b $c3
    lda.l !SRAM_MW_ITEMS_RECV+$2, x
    sta.b $c1
    lda.l config_remote_items
    bit #$0002
    beq .perform_receive
    lda.b $c1
    and #$FF00
    cmp #$FF00
    beq .perform_receive
    lsr #8

    ; check that item has not already been collected
    ; A = item location id
    phx
    pha
    jsl $80818E ; $80:818E: Change bit index to byte index and bitmask
    ; X:        item byte
    ; $7e:05e7: item bit (mask)
    lda $7ed870, X
    and.l $7e05e7 ; check if item bit was already collected
    beq .new_remote_item
    ; item location collection bit is already set (this happens when our own game touched the item)
    pla
    plx
    bra .next

.new_remote_item
    ; item not yet collected:
    ; save remote item as collected
    pla ; A = item location id
    jsl COLLECTTANK
    ; X:        item byte
    ; $7e:05e7: item bit (mask)
    lda $7ed870, X ; re-load item collection array byte
    ora.l $7e05e7 ; set this location's bit to '1' (collected)
    sta $7ed870, X
    plx
    ; now show message box

.perform_receive
    lda.b $c1
    and #$00FF
    sta.b $c1
    jsr mw_receive_item

.next
    lda.l !SRAM_MW_ITEMS_RECV_RPTR
    inc a
    sta.l !SRAM_MW_ITEMS_RECV_RPTR

    bra .loop

.end
    stz.b $c1
    stz.b $c3
    plx : pla
    rts


i_live_pickup_multiworld: ; touch PLM code
    phx : phy : php
    lda.l $1dc7, x              ; Load PLM room argument (item location id)
    asl #3 : tax                ; index by item location id into rando_item_table (entry size 8 bytes)

    lda.l rando_item_table+$4, x    ; Load item owner into Y
    tay
    lda.l rando_item_table+$2, x    ; Load original item id into A
    cmp #$0015
    bmi .local_item_or_offworld
    ; off-world item:
    lda #$0015              ; ids over 0n20 are only used to display off-world item names
.local_item_or_offworld
    ; params: A = item id, X = byte offset of item location's row in rando_item_table (ie, location id * 8), Y = world id aka item owner (all 16-bit)
    jsl mw_write_message       ; Send message over network/SRAM
    lda.l rando_item_table, x  ; Load item type
    beq .own_item
    ; type of item == #$0001: other player's item:
    lda.l rando_item_table+$2, x    ; Load original item id again, we'll then put it into X this time
    tax
    ; params: X = item id, Y = world id aka item owner
    jsl mw_display_item_sent     ; Display custom message box
    bra .end

.own_item
    lda.l rando_item_table+$2, x ; Load item id
    cmp #$0015
    bmi .own_item1
    lda #$0014              ; self item id >= 0n21 should never happen... but just call it a reserve tank (0n20) to avoid a crash
.own_item1
    ; param X = byte offset of item data within sm_item_plm_pickup_sequence_pointers for this item
    asl
    tax
    jsl perform_item_pickup
    bra .end

.end
    plp : ply : plx
    rtl


mw_hook_main_game:
    jsl $A09169     ; Last routine of game mode 8 (main gameplay)
    lda.l config_multiworld
    beq +
    lda.l $7e0998
    cmp #$0008
    bne +
    jsr mw_handle_queue     ; Handle MW RECVQ only in gamemode 8
+
    rtl

patch_load_multiworld:
    lda $7e0952
    clc
    adc #$0010
    jsl mw_load_sram
    ; restore overwritten & skipped instructions
    ply
    plx
    clc
    plb
    rtl

pushpc
org $8B914A ; hook boot @ $8B:9146 Initialise IO registers and display Nintendo logo
    ; Multiworld init
    jsl mw_init_memory

org $8180f7
    jml patch_load_multiworld

org $818027 ; hook saving @ $81:8000 Save to SRAM (after VARIA randomizer's hook - point being to not collide)
    jsl mw_save_sram

org $828BB3
    jsl mw_hook_main_game

namespace message
org $859963

table box_yellow.tbl,rtl
item_names:
    dw "___      AN ENERGY TANK      ___"
    dw "___         MISSILES         ___"
    dw "___       SUPER MISSILES     ___"
    dw "___        POWER BOMBS       ___"
    dw "___          BOMBS           ___"
    dw "___       CHARGE BEAM        ___"
    dw "___         ICE BEAM         ___"
    dw "___       HI-JUMP BOOTS      ___"
    dw "___       SPEED BOOSTER      ___"
    dw "___        WAVE BEAM         ___"
    dw "___       S P A Z E R        ___"
    dw "___       SPRING BALL        ___"
    dw "___        VARIA SUIT        ___"
    dw "___       GRAVITY SUIT       ___"
    dw "___       X-RAY SCOPE        ___"
    dw "___       PLASMA BEAM        ___"
    dw "___      GRAPPLING BEAM      ___"
    dw "___        SPACE JUMP        ___"
    dw "___       SCREW ATTACK       ___"
    dw "___       MORPHING BALL      ___"
    dw "___      A RESERVE TANK      ___"

    ; add 100 more entries for worst case of a different item at each location
    ; to be filled by patcher
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
    dw "________________________________"
cleartable


table box.tbl,rtl
    ;   0                              31
item_sent:
    dw "___         YOU FOUND        ___"
    dw "___      ITEM NAME HERE      ___"
    dw "___           FOR            ___"
    dw "___          PLAYER          ___"
item_sent_end:

item_received:
    dw "___       YOU RECEIVED       ___"
    dw "___      ITEM NAME HERE      ___"
    dw "___           FROM           ___"
    dw "___          PLAYER          ___"
item_received_end:

cleartable


write_placeholders:
    phx : phy

.adjust
    lda.b $c1                 ; Load item id
    asl #6 : tay
    ldx #$0000
    phb
    phk : plb ; DB = program bank register.
              ; note, item_names must be in an exlpicitly known bank (here, same bank as this asm)
              ; .. in order to index into it with lda ,y (there is no lda.l ,y)
-
    lda item_names, y       ; Write item name to box
    sta.l $7e3280, x
    inx #2 : iny #2
    cpx #$0040
    bne -

    plb ; restore previous DB
    lda.b $c3                 ; Load player 1
    ldx #$0000
.loop
    cpx #$0190              ; 200 entries
    beq .notfound
    inx #2   
    cmp.l rando_player_id_table-$2, x
    bne .loop
    dex #2
    txa
    bra .value_ok
.notfound   
    lda #$0000
.value_ok
    asl #3 : tax
    ldy #$0000
-
    lda.l rando_player_table, x
    and #$00ff
    phx
    asl : tax               ; Put char table offset in X
    lda.l char_table-$40, x 
    tyx
    sta.l $7e3310, x        ; 16 bytes player name now instead of 12
    iny #2
    plx
    inx
    cpy #$0020              ; 16 bytes player name now instead of 12
    bne -
    rep #$30

.end
    ply : plx
    lda #$0020
    rts

char_table:
    ;  <sp>     !      "      #      $      %      %      '      (      )      *      +      ,      -      .      /
    dw $384E, $38FF, $38FD, $38FE, $38FE, $380A, $38FE, $38FD, $38FE, $38FE, $38FE, $38FE, $38FB, $38FC, $38FA, $38FE
    ;    0      1      2      3      4      5      6      7      8      9      :      ;      <      =      >      ?
    dw $3809, $3800, $3801, $3802, $3803, $3804, $3805, $3806, $3807, $3808, $38FE, $38FE, $38FE, $38FE, $38FE, $38FE
    ;    @      A      B      C      D      E      F      G      H      I      J      K      L      M      N      O
    dw $38FE, $38E0, $38E1, $38E2, $38E3, $38E4, $38E5, $38E6, $38E7, $38E8, $38E9, $38EA, $38EB, $38EC, $38ED, $38EE
    ;    P      Q      R      S      T      U      V      W      X      Y      Z      [      \      ]      ^      _
    dw $38EF, $38F0, $38F1, $38F2, $38F3, $38F4, $38F5, $38F6, $38F7, $38F8, $38F9, $38FE, $38FE, $38FE, $38FE, $38FE

PlaceholderBig:
    ; warning: if calling directly, caller must restore their own register widths, since $85:841D calls $85:831E, which blithely SEPs #$20
    REP #$30
    JSR write_placeholders
    LDY #$0000
    JMP $841D

; if we need a multiworld message box, call its setup functions
; else go back to the vanilla way of init'ing a message box
; return value:
;   sec if multiworld functions called
;   clc if vanilla behavior should continue
multiworld_init_new_messagebox_if_needed:
    pha
    lda.b $cc     ; if $cc and $ce are set, they override the message box
    cmp #$7b49 ; magic number
    bne .vanilla
    lda.b $ce
    cmp #$0300
    beq .msgbox_mwsend
    cmp #$0301
    beq .msgbox_mwrecv
.vanilla
    ; restore original code
    pla
    dec
    asl
    sta.b $34
    asl
    clc
    rts
.msgbox_mwsend
.msgbox_mwrecv
    ; simulate table entry: dw !PlaceholderBig, !Big, item_sent
    ;       or table entry: dw !PlaceholderBig, !Big, item_received
    jsr $825A ; vanilla large message box init routine $85:825A (no parameters)
    php
    jsr PlaceholderBig
    plp
    pla
    sec ; set carry, indicating skip normal table-based function calls
    rts

; if we need a multiworld message box, calculate its data source
; else restore vanilla code
; return value:
;   if multiworld, these values are modified from original code:
;      in mem location $00: message tilemap source (like memcpy src) (bank $85 implied)
;      in mem location $09: message tilemap size   (like memcpy n bytes)
;      in A:                ^same value as held in $09 (next vanilla instruction to execute in all cases will be sta.b $09 btw)
hook_tilemap_calc:
    ; orig code figures out source and size based on table value math; for the 2 multiworld messages, no message table, we set fixed sources and sizes in the code here
    pha
    lda.b $ce     ; if $ce is set, it overrides the message box
    cmp #$0300
    beq .msgbox_mwsend
    cmp #$0301
    beq .msgbox_mwrecv
.vanilla
    ; restore original code
    pla
    sec
    sbc.b $00
    rts
.msgbox_mwsend
    pla
    stz.b $ce
    lda #item_sent ; 16-bit pointer to sent box template
    sta.b $00 ; $00 = message tilemap source
    lda #(item_sent_end-item_sent)
    sta.b $09 ; $09 = message tilemap size
    rts
.msgbox_mwrecv
    pla
    stz.b $ce
    lda #item_received ; 16-bit pointer to receive box template
    sta.b $00 ; $00 = message tilemap source
    lda #(item_received_end-item_received)
    sta.b $09 ; $09 = message tilemap size
    rts
    

; hook the relevant locations where an item's message box index will be read from $1c1f in RAM and used
org $858246 ; inside $85:8241 Initialise message box
    jsr multiworld_init_new_messagebox_if_needed
    bcc .normal
    rts ; functions were already called, don't call again
.normal

org $8582F9 ; inside $85:82B8 Write message tilemap
    jsr hook_tilemap_calc

pullpc
namespace off
