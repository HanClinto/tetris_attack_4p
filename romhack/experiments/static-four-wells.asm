incsrc "../patch.asm"

org $808E4D
    jsl EarlyFourWellHook

org $808E7B
    jsl EarlyFourWellHook

org $A08400
EarlyFourWellHook:
    jsl $8090F3
    jsl RenderFourWells
    rtl

org $A08500
RenderFourWells:
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda #$7F
    pha
    plb

    lda.l $7E01BA
    cmp #$02
    beq .mode2

    stz $FE3E
    brl .done

.mode2:
    lda $FE3E
    bne .initialized

    inc $FE3E
    rep #$20
    lda #$0000
    sta $FE30
    lda #$0008
    sta $FE32
    lda #$0010
    sta $FE34
    lda #$0018
    sta $FE36

.initialized:
    rep #$30
    lda $FE00
    ldx #$FE30
    jsr UpdateWellScroll
    lda $FE02
    ldx #$FE32
    jsr UpdateWellScroll
    lda $FE04
    ldx #$FE34
    jsr UpdateWellScroll
    lda $FE06
    ldx #$FE36
    jsr UpdateWellScroll

    sep #$20
    lda #$80
    sta.l $002115

    rep #$30
    lda #$6020                     ; BG3 vertical-offset row
    sta.l $002116
    lda #$0000
    sta.l $002118
    lda $FE30
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118
    sta.l $002118
    lda $FE32
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118
    sta.l $002118
    lda $FE34
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118
    sta.l $002118
    lda $FE36
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118

    ldx #$0000
.rowLoop:
    txa
    asl
    asl
    asl
    asl
    asl
    clc
    adc #$78C0                     ; BG2 row 6
    tay

    iny                            ; Board 1 starts at column 1
    jsr DrawWellRow
    tya
    clc
    adc #$0002                     ; Skip columns 7-8
    tay
    jsr DrawWellRow
    tya
    clc
    adc #$0002                     ; Skip columns 15-16
    tay
    jsr DrawWellRow
    tya
    clc
    adc #$0002                     ; Skip columns 23-24
    tay
    jsr DrawWellRow

    inx
    cpx #$000C
    bne .rowLoop

    sep #$20
    lda #$00
    sta.l $00210F
    sta.l $00210F
    sta.l $002110
    sta.l $002110

    lda #$02                       ; Experiment only: show BG2 without UI layers
    sta.l $7E01E2
    sta.l $00212C

.done:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    rtl

UpdateWellScroll:
    tay
    bit #$0800                     ; Up
    beq .checkDown
    lda $0000,x
    dec
    and #$03FF
    sta $0000,x
    rts

.checkDown:
    tya
    bit #$0400                     ; Down
    beq .noChange
    lda $0000,x
    inc
    and #$03FF
    sta $0000,x

.noChange:
    rts

WriteOffsetGroup:
    and #$03FF
    ora #$4000                     ; Enable vertical offset for BG2
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    rts

DrawWellRow:
    tya
    sta.l $002116
    lda #$0000                     ; Tile 0 is a flat gray field in this scene
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    tya
    clc
    adc #$0006
    tay
    rts

assert pc() <= $A08700
