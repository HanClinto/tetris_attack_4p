!multitapPadA = $FE00
!multitapPadB = $FE02
!multitapPadC = $FE04
!multitapPadD = $FE06
!savedWrio = $FE08
!p3Current = $FE10
!p3Pressed = $FE12
!p3Repeat = $FE14
!p3Previous = $FE16
!p3RepeatTimer = $FE18
!p4Current = $FE20
!p4Pressed = $FE22
!p4Repeat = $FE24
!p4Previous = $FE26
!p4RepeatTimer = $FE28

org $A08200
PollMultitap:
    php
    rep #$30
    phx
    phy
    phb

    sep #$20
    lda #$7F
    pha
    plb

    stz !multitapPadA
    stz !multitapPadA+1
    stz !multitapPadB
    stz !multitapPadB+1
    stz !multitapPadC
    stz !multitapPadC+1
    stz !multitapPadD
    stz !multitapPadD+1

    lda.l $004213
    sta !savedWrio
    ora #$80
    sta.l $004201

    lda #$01
    sta.l $004016
    lda #$00
    sta.l $004016

    rep #$10
    ldx #$0010
.readPairAB:
    lda.l $004017
    lsr
    rep #$20
    rol !multitapPadA
    sep #$20
    lsr
    rep #$20
    rol !multitapPadB
    sep #$20
    dex
    bne .readPairAB

    lda !savedWrio
    and #$7F
    sta.l $004201

    ldx #$0010
.readPairCD:
    lda.l $004017
    lsr
    rep #$20
    rol !multitapPadC
    sep #$20
    lsr
    rep #$20
    rol !multitapPadD
    sep #$20
    dex
    bne .readPairCD

    lda !savedWrio
    sta.l $004201

    rep #$30
    lda !multitapPadB
    ldx #!p3Current
    jsr ProcessInputState

    lda !multitapPadC
    ldx #!p4Current
    jsr ProcessInputState

    plb
    ply
    plx
    plp
    rtl

; Mirrors the current/pressed/repeat behavior at $80:9C10 for one controller.
; Input: A = raw controller word, X = state structure address in bank $7F.
ProcessInputState:
    bit #$000F
    beq .connected
    lda #$0000
.connected:
    sta $0000,x
    eor $0006,x
    and $0000,x
    sta $0002,x
    sta $0004,x

    lda $0000,x
    beq .storePrevious
    cmp $0006,x
    bne .resetInitialDelay
    dec $0008,x
    bne .storePrevious

    lda $0000,x
    sta $0004,x
    lda $B1
    sta $0008,x
    bra .storePrevious

.resetInitialDelay:
    lda $AF
    sta $0008,x

.storePrevious:
    lda $0000,x
    sta $0006,x
    rts

assert pc() <= $A08300
