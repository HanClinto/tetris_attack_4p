incsrc "../patch.asm"

org $A0800C
    jsl PollMultitap
    jsl RenderLayerProbe
    jml $809C10

org $A08400
RenderLayerProbe:
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

    rep #$20
    ldx #$0000
.rowLoop:
    txa
    asl
    asl
    asl
    asl
    asl
    clc
    adc #$7800
    sta.l $002116

    lda #$0000
    sep #$20
    ldy #$0008
.columnLoop:
    sta.l $002118
    xba
    sta.l $002119
    xba
    dey
    bne .columnLoop

    rep #$20
    inx
    cpx #$001C
    bne .rowLoop

.done:
    rep #$30
    ply
    plx
    pla
    plp
    rtl

assert pc() <= $A08500
