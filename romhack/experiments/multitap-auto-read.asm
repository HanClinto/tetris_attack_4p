incsrc "../patch.asm"

; Route P1 through the second data line of controller port 2. With a Super
; Multitap selected, Mesen exposes its second active subport through JOY4.
org $809C10
    lda $421E
