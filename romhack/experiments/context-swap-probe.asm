incsrc "../patch.asm"

org $A0800C
    jsl PollMultitap
    jsl ContextRoundTripProbe
    jml $809C10

org $A08700
ContextRoundTripProbe:
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda.l $7E01BA
    cmp #$02
    bne .done

    lda #$7F
    pha
    plb
    lda $2000
    bne .done
    inc $2000

    ; Probe only: the CPU copy is intentionally exhaustive and can span an
    ; entire frame. Prevent a nested NMI from re-entering the hook before the
    ; native slots are restored. The headless test exits immediately afterward.
    lda #$00
    sta.l $004200

    rep #$30
    ldx #$0000
    ldy #$0000
    jsr SaveNativeSlot
    ldx #$0100
    ldy #$0400
    jsr SaveNativeSlot

    ldy #$0800
    lda #$3333
.fillP3:
    sta $0000,y
    iny
    iny
    cpy #$0C00
    bne .fillP3

    ldy #$0C00
    lda #$4444
.fillP4:
    sta $0000,y
    iny
    iny
    cpy #$1000
    bne .fillP4

    ldx #$0000
    ldy #$0800
    jsr LoadNativeSlot
    ldx #$0100
    ldy #$0C00
    jsr LoadNativeSlot

    ldx #$0000
    ldy #$0800
    jsr SaveNativeSlot
    ldx #$0100
    ldy #$0C00
    jsr SaveNativeSlot

    ldx #$0000
    ldy #$0000
    jsr LoadNativeSlot
    ldx #$0100
    ldy #$0400
    jsr LoadNativeSlot

.done:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    rtl

SaveNativeSlot:
    phx
    phy
    tya
    clc
    adc #$0100
    sta $1FF0
.saveLoop:
    lda.l $7E0D7C,x
    sta $0000,y
    lda.l $7E0F7C,x
    sta $0100,y
    lda.l $7E117C,x
    sta $0200,y
    lda.l $7E137C,x
    sta $0300,y
    inx
    inx
    iny
    iny
    cpy $1FF0
    bne .saveLoop
    ply
    plx
    rts

LoadNativeSlot:
    phx
    phy
    tya
    clc
    adc #$0100
    sta $1FF0
.loadLoop:
    lda $0000,y
    sta.l $7E0D7C,x
    lda $0100,y
    sta.l $7E0F7C,x
    lda $0200,y
    sta.l $7E117C,x
    lda $0300,y
    sta.l $7E137C,x
    inx
    inx
    iny
    iny
    cpy $1FF0
    bne .loadLoop
    ply
    plx
    rts

assert pc() <= $A08900
