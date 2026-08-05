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
    ldx #$0100
    jsr SaveP2ScalarState
    ldx #$0000
    jsr SaveP2ScalarState
    jsr LoadP3ScalarState
    jsr LoadP3InputState

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
    jsr SaveP3ScalarState
    jsr RestoreP2ScalarState
    jsr RestoreP2InputState
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

org $A08D00
SaveP2ScalarState:
    lda.l $7E03F0
    sta.l $7F0C00,x
    lda.l $7E0402
    sta.l $7F0C02,x
    lda.l $7E0426
    sta.l $7F0C04,x
    lda.l $7E042A
    sta.l $7F0C06,x
    lda.l $7E042E
    sta.l $7F0C08,x
    lda.l $7E0442
    sta.l $7F0C0A,x
    lda.l $7E0446
    sta.l $7F0C0C,x
    lda.l $7E044A
    sta.l $7F0C0E,x
    lda.l $7E044E
    sta.l $7F0C10,x
    lda.l $7E0452
    sta.l $7F0C12,x
    lda.l $7E0456
    sta.l $7F0C14,x
    lda.l $7E045A
    sta.l $7F0C16,x
    lda.l $7E045E
    sta.l $7F0C18,x
    lda.l $7E046E
    sta.l $7F0C1A,x
    lda.l $7E0472
    sta.l $7F0C1C,x
    lda.l $7E04C0
    sta.l $7F0C1E,x
    lda.l $7E04EA
    sta.l $7F0C20,x
    lda.l $7E04F6
    sta.l $7F0C22,x
    lda.l $7E04FA
    sta.l $7F0C24,x
    rts

LoadP3ScalarState:
    ldx #$0000
    bra LoadP2ScalarState

RestoreP2ScalarState:
    ldx #$0100
LoadP2ScalarState:
    lda.l $7F0C00,x
    sta.l $7E03F0
    lda.l $7F0C02,x
    sta.l $7E0402
    lda.l $7F0C04,x
    sta.l $7E0426
    lda.l $7F0C06,x
    sta.l $7E042A
    lda.l $7F0C08,x
    sta.l $7E042E
    lda.l $7F0C0A,x
    sta.l $7E0442
    lda.l $7F0C0C,x
    sta.l $7E0446
    lda.l $7F0C0E,x
    sta.l $7E044A
    lda.l $7F0C10,x
    sta.l $7E044E
    lda.l $7F0C12,x
    sta.l $7E0452
    lda.l $7F0C14,x
    sta.l $7E0456
    lda.l $7F0C16,x
    sta.l $7E045A
    lda.l $7F0C18,x
    sta.l $7E045E
    lda.l $7F0C1A,x
    sta.l $7E046E
    lda.l $7F0C1C,x
    sta.l $7E0472
    lda.l $7F0C1E,x
    sta.l $7E04C0
    lda.l $7F0C20,x
    sta.l $7E04EA
    lda.l $7F0C22,x
    sta.l $7E04F6
    lda.l $7F0C24,x
    sta.l $7E04FA
    rts

SaveP3ScalarState:
    ldx #$0000
    jsr SaveP2ScalarState
    rts

LoadP3InputState:
    lda.l $7E00B5
    sta.l $7F0D40
    lda.l $7E00B9
    sta.l $7F0D42
    lda.l $7E00BD
    sta.l $7F0D44
    lda.l $7E00C7
    sta.l $7F0D46
    lda.l $7E00CD
    sta.l $7F0D48
    lda.l $7FFE10
    sta.l $7E00B5
    lda.l $7FFE12
    sta.l $7E00B9
    lda.l $7FFE14
    sta.l $7E00BD
    lda.l $7FFE16
    sta.l $7E00C7
    lda.l $7FFE18
    sta.l $7E00CD
    rts

RestoreP2InputState:
    lda.l $7F0D40
    sta.l $7E00B5
    lda.l $7F0D42
    sta.l $7E00B9
    lda.l $7F0D44
    sta.l $7E00BD
    lda.l $7F0D46
    sta.l $7E00C7
    lda.l $7F0D48
    sta.l $7E00CD
    rts

assert ContextDispatchPostComplete == $A08BBF
assert pc() <= $A09000