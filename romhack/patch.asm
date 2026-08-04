lorom

; Tetris Attack (USA) (En,Ja), headerless
; SHA-1: 2dc56eab3e70c0910ae47119d8b69f494e6000df

org $80FFD7
    db $0B                         ; 2 MiB ROM

org $809C04
    jml ControllerPollTrampoline

org $A08000
ControllerPollTrampoline:
    php
    sep #$20

.waitForAutoJoy:
    lda $4212
    and #$01
    bne .waitForAutoJoy

    rep #$20
    jml $809C10

    db "TA4P-PROBE"

assert pc() <= $A08040
