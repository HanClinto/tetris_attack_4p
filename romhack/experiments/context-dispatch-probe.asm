incsrc "../patch.asm"

org $829D93
    jsl P1DispatchPreHook

org $829DB8
    jsl P1DispatchPostHook

org $829E49
    jsl P2DispatchPreHook

org $829E6E
    jsl P2DispatchPostHook

org $A08B00
P1DispatchPreHook:
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
    lda.l $7F2004
    eor #$01
    sta.l $7F2004
    beq .done
    lda #$03
    sta.l $7F2001
    rep #$30
    jsr BeginVirtualP3

.done:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    rtl

org $A08B80
P1DispatchPostHook:
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda #$00
    sta.l $7F2005
    lda.l $7F2001
    cmp #$03
    bne .done
    rep #$30
    ldx #$0000
    ldy #$0800
    jsr SaveNativeSlotBlockMove
    ldx #$0000
    jsl SaveP1ScalarState
    jsl RestoreP1ScalarState
    jsl RestoreP1InputState
    ldx #$0000
    ldy #$0000
    jsr LoadNativeSlotBlockMove

    sep #$20
    lda #$03
    sta.l $7F2005
    lda.l $7F2006
    inc
    sta.l $7F2006
    lda #$00
    sta.l $7F2001
    lda.l $7F2002
    inc
    sta.l $7F2002

.done:
    jml P1DispatchPostComplete

assert pc() <= $A08BF0

org $A08BF0
P1DispatchPostComplete:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    jsl $85B9C1
    rtl

org $A08C00
P2DispatchPreHook:
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
    lda.l $7F200A
    eor #$01
    sta.l $7F200A
    beq .done
    lda #$04
    sta.l $7F2001
    rep #$30
    jsr BeginVirtualP4

.done:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    rtl

org $A08C80
P2DispatchPostHook:
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda #$00
    sta.l $7F2005
    lda.l $7F2001
    cmp #$04
    bne .done
    rep #$30
    ldx #$0100
    ldy #$1000
    jsr SaveNativeSlotBlockMove
    ldx #$0800
    jsr SaveP2ScalarState
    jsr RestoreP2ScalarState
    jsr RestoreP2InputState
    ldx #$0400
    ldy #$0100
    jsr LoadNativeSlotBlockMove

    sep #$20
    lda #$04
    sta.l $7F2005
    lda.l $7F2007
    inc
    sta.l $7F2007
    lda #$00
    sta.l $7F2001
    lda.l $7F2002
    inc
    sta.l $7F2002

.done:
    jml P2DispatchPostComplete

assert pc() <= $A08CF0

org $A08CF0
P2DispatchPostComplete:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    jsl $85B9C1
    rtl

org $A09200
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

assert pc() <= $A09300

org $A08D00
SaveP2ScalarState:
    lda.l $7E03A6
    sta.l $7F0C26,x
    lda.l $7E03AA
    sta.l $7F0C28,x
    lda.l $7E03AE
    sta.l $7F0C2A,x
    lda.l $7E03B2
    sta.l $7F0C2C,x
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

RestoreP2ScalarState:
    ldx #$0100
LoadP2ScalarState:
    lda.l $7F0C26,x
    sta.l $7E03A6
    lda.l $7F0C28,x
    sta.l $7E03AA
    lda.l $7F0C2A,x
    sta.l $7E03AE
    lda.l $7F0C2C,x
    sta.l $7E03B2
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

SaveP2InputState:
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

    rts

LoadVirtualInputState:
    lda.l $7F0000,x
    sta.l $7E00B5
    lda.l $7F000A,x
    sta.l $7E00B9
    lda.l $7F000C,x
    sta.l $7E00BD
    lda.l $7F0006,x
    sta.l $7E00C7
    lda.l $7F0008,x
    sta.l $7E00CD
    lda #$0000
    sta.l $7F000A,x
    sta.l $7F000C,x
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

org $A09000
BeginVirtualP3:
    ldx #$0000
    ldy #$0000
    jsr SaveNativeSlotBlockMove
    ldx #$0180
    jsl SaveP1ScalarState
    jsl SaveP1InputState

    sep #$20
    lda.l $7F2008
    bne .load
    inc
    sta.l $7F2008
    rep #$30
    ldx #$0000
    ldy #$0800
    jsr SaveNativeSlotBlockMove
    ldx #$0000
    jsl SaveP1ScalarState
    bra .input

.load:
    rep #$30
    ldx #$0800
    ldy #$0000
    jsr LoadNativeSlotBlockMove
    ldx #$0000
    jsl LoadP1ScalarState

.input:
    ldx #$FE10
    jsl LoadVirtualInputP1
    rts

BeginVirtualP4:
    ldx #$0100
    ldy #$0400
    jsr SaveNativeSlotBlockMove
    ldx #$0100
    jsr SaveP2ScalarState
    jsr SaveP2InputState

    sep #$20
    lda.l $7F2009
    bne .load
    inc
    sta.l $7F2009
    rep #$30
    ldx #$0100
    ldy #$1000
    jsr SaveNativeSlotBlockMove
    ldx #$0800
    jsr SaveP2ScalarState
    bra .input

.load:
    rep #$30
    ldx #$1000
    ldy #$0100
    jsr LoadNativeSlotBlockMove
    ldx #$0800
    jsr LoadP2ScalarState

.input:
    ldx #$FE20
    jsr LoadVirtualInputState
    rts

assert P1DispatchPostComplete == $A08BF0
assert P2DispatchPostComplete == $A08CF0
assert pc() <= $A09300

org $A18000
SaveP1ScalarState:
    lda.l $7E03A4
    sta.l $7F0C26,x
    lda.l $7E03A8
    sta.l $7F0C28,x
    lda.l $7E03AC
    sta.l $7F0C2A,x
    lda.l $7E03B0
    sta.l $7F0C2C,x
    lda.l $7E03EE
    sta.l $7F0C00,x
    lda.l $7E0400
    sta.l $7F0C02,x
    lda.l $7E0424
    sta.l $7F0C04,x
    lda.l $7E0428
    sta.l $7F0C06,x
    lda.l $7E042C
    sta.l $7F0C08,x
    lda.l $7E0440
    sta.l $7F0C0A,x
    lda.l $7E0444
    sta.l $7F0C0C,x
    lda.l $7E0448
    sta.l $7F0C0E,x
    lda.l $7E044C
    sta.l $7F0C10,x
    lda.l $7E0450
    sta.l $7F0C12,x
    lda.l $7E0454
    sta.l $7F0C14,x
    lda.l $7E0458
    sta.l $7F0C16,x
    lda.l $7E045C
    sta.l $7F0C18,x
    lda.l $7E046C
    sta.l $7F0C1A,x
    lda.l $7E0470
    sta.l $7F0C1C,x
    lda.l $7E04BE
    sta.l $7F0C1E,x
    lda.l $7E04E8
    sta.l $7F0C20,x
    lda.l $7E04F4
    sta.l $7F0C22,x
    lda.l $7E04F8
    sta.l $7F0C24,x
    rtl

RestoreP1ScalarState:
    ldx #$0180
LoadP1ScalarState:
    lda.l $7F0C26,x
    sta.l $7E03A4
    lda.l $7F0C28,x
    sta.l $7E03A8
    lda.l $7F0C2A,x
    sta.l $7E03AC
    lda.l $7F0C2C,x
    sta.l $7E03B0
    lda.l $7F0C00,x
    sta.l $7E03EE
    lda.l $7F0C02,x
    sta.l $7E0400
    lda.l $7F0C04,x
    sta.l $7E0424
    lda.l $7F0C06,x
    sta.l $7E0428
    lda.l $7F0C08,x
    sta.l $7E042C
    lda.l $7F0C0A,x
    sta.l $7E0440
    lda.l $7F0C0C,x
    sta.l $7E0444
    lda.l $7F0C0E,x
    sta.l $7E0448
    lda.l $7F0C10,x
    sta.l $7E044C
    lda.l $7F0C12,x
    sta.l $7E0450
    lda.l $7F0C14,x
    sta.l $7E0454
    lda.l $7F0C16,x
    sta.l $7E0458
    lda.l $7F0C18,x
    sta.l $7E045C
    lda.l $7F0C1A,x
    sta.l $7E046C
    lda.l $7F0C1C,x
    sta.l $7E0470
    lda.l $7F0C1E,x
    sta.l $7E04BE
    lda.l $7F0C20,x
    sta.l $7E04E8
    lda.l $7F0C22,x
    sta.l $7E04F4
    lda.l $7F0C24,x
    sta.l $7E04F8
    rtl

SaveP1InputState:
    lda.l $7E00B3
    sta.l $7F0D50
    lda.l $7E00B7
    sta.l $7F0D52
    lda.l $7E00BB
    sta.l $7F0D54
    lda.l $7E00BF
    sta.l $7F0D56
    lda.l $7E00C5
    sta.l $7F0D58
    rtl

LoadVirtualInputP1:
    lda.l $7F0000,x
    sta.l $7E00B3
    lda.l $7F000A,x
    sta.l $7E00B7
    lda.l $7F000C,x
    sta.l $7E00BB
    lda.l $7F0006,x
    sta.l $7E00BF
    lda.l $7F0008,x
    sta.l $7E00C5
    lda #$0000
    sta.l $7F000A,x
    sta.l $7F000C,x
    rtl

RestoreP1InputState:
    lda.l $7F0D50
    sta.l $7E00B3
    lda.l $7F0D52
    sta.l $7E00B7
    lda.l $7F0D54
    sta.l $7E00BB
    lda.l $7F0D56
    sta.l $7E00BF
    lda.l $7F0D58
    sta.l $7E00C5
    rtl

assert pc() <= $A18400