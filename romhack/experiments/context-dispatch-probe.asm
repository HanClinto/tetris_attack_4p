incsrc "../patch.asm"

org $829E49
    jsl ContextDispatchPreHook

org $829E6E
    jsl ContextDispatchPostHook

org $A08B00
ContextDispatchPreHook:
    jsl $86D343
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda.l $7F2000
    cmp #$A5
    bne .done
    lda #$00
    sta.l $7F2000
    lda #$5A
    sta.l $7F2001

    rep #$30
    ldx #$0100
    ldy #$0000
    jsr SaveNativeSlotBlockMove
    ldx #$0100
    ldy #$0800
    jsr SaveNativeSlotBlockMove

.done:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    rtl

org $A08B80
ContextDispatchPostHook:
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda.l $7F2001
    cmp #$5A
    bne .done
    lda #$00
    sta.l $7F2001

    rep #$30
    ldx #$0100
    ldy #$0800
    jsr SaveNativeSlotBlockMove
    ldx #$0000
    ldy #$0100
    jsr LoadNativeSlotBlockMove

    sep #$20
    lda.l $7F2002
    inc
    sta.l $7F2002

.done:
ContextDispatchPostComplete:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    jsl $85B9C1
    rtl

org $A08C00
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

assert ContextDispatchPostComplete == $A08BB6
assert pc() <= $A08E00