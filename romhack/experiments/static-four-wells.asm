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

    sep #$20
    lda.l $7E01BA
    cmp #$02
    bne .done

    lda #$80
    sta.l $002115

    rep #$30
    lda #$6020                     ; BG3 vertical-offset row
    sta.l $002116
    ldx #$0000
.writeVerticalOffsets:
    lda.l FourWellVerticalOffsets,x
    sta.l $002118
    inx
    inx
    cpx #$0040
    bne .writeVerticalOffsets

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

.done:
    rep #$30
    ply
    plx
    pla
    plp
    rtl

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

FourWellVerticalOffsets:
    dw $0000
    dw $4000,$4000,$4000,$4000,$4000,$4000
    dw $0000,$0000
    dw $4008,$4008,$4008,$4008,$4008,$4008
    dw $0000,$0000
    dw $4010,$4010,$4010,$4010,$4010,$4010
    dw $0000,$0000
    dw $4018,$4018,$4018,$4018,$4018,$4018
    dw $0000

assert pc() <= $A08600
