incsrc "../patch.asm"

org $A0800C
    jsl PollMultitap
    jsl ContextBlockMoveRoundTripProbe
    jml $809C10

org $A08700
ContextBlockMoveRoundTripProbe:
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda.l $7E01BA
    cmp #$02
    beq .checkDone
    jmp .done

.checkDone:
    lda #$7F
    pha
    plb
    lda $2000
    beq .firstRun
    jmp .done

.firstRun:
    inc $2000

    rep #$30
    ldx #$0000
    ldy #$0000
    jsr SaveNativeSlotBlockMove
    ldx #$0100
    ldy #$0400
    jsr SaveNativeSlotBlockMove

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

    ldx #$0800
    ldy #$0000
    jsr LoadNativeSlotBlockMove
    ldx #$0C00
    ldy #$0100
    jsr LoadNativeSlotBlockMove

    ldx #$0000
    ldy #$0800
    jsr SaveNativeSlotBlockMove
    ldx #$0100
    ldy #$0C00
    jsr SaveNativeSlotBlockMove

    ldx #$0000
    ldy #$0000
    jsr LoadNativeSlotBlockMove
    ldx #$0400
    ldy #$0100
    jsr LoadNativeSlotBlockMove

.done:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    rtl

SaveNativeSlotBlockMove:
    txa
    clc
    adc #$0D7C
    tax

    lda #$00FF
    mvn $7F,$7E
    txa
    clc
    adc #$0100
    tax
    lda #$00FF
    mvn $7F,$7E
    txa
    clc
    adc #$0100
    tax
    lda #$00FF
    mvn $7F,$7E
    txa
    clc
    adc #$0100
    tax
    lda #$00FF
    mvn $7F,$7E
    rts

LoadNativeSlotBlockMove:
    tya
    clc
    adc #$0D7C
    tay

    lda #$00FF
    mvn $7E,$7F
    tya
    clc
    adc #$0100
    tay
    lda #$00FF
    mvn $7E,$7F
    tya
    clc
    adc #$0100
    tay
    lda #$00FF
    mvn $7E,$7F
    tya
    clc
    adc #$0100
    tay
    lda #$00FF
    mvn $7E,$7F
    rts

assert pc() <= $A08900