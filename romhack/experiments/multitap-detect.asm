incsrc "../patch.asm"

org $809C10
    jml DetectMultitap

org $A08100
DetectMultitap:
    sep #$20
    lda #$01
    sta $4016
    lda $4017
    pha
    stz $4016
    pla
    and #$02
    beq .notDetected

    rep #$20
    lda #$0800                     ; Report Up through the P1 input path
    bit #$000F
    jml $809C16

.notDetected:
    rep #$20
    lda #$0000
    bit #$000F
    jml $809C16

assert pc() <= $A08140
