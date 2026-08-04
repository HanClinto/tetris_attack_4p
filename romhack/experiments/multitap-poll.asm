incsrc "../patch.asm"

!multitapPadA = $FE00
!multitapPadB = $FE02
!multitapPadC = $FE04
!multitapPadD = $FE06
!savedWrio = $FE08

; Insert the behavior-neutral poll after the automatic joypad busy wait. The
; normal P1/P2 input routine still runs unchanged at $80:9C10.
org $A0800C
    jsl PollMultitap
    jml $809C10

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

    plb
    ply
    plx
    plp
    rtl

assert pc() <= $A08300
