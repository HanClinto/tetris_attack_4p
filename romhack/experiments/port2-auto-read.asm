incsrc "../patch.asm"

; Control experiment: route P1 through the ordinary data line of controller
; port 2. This verifies the headless input harness independently of JOY4.
org $809C10
    lda $421A
