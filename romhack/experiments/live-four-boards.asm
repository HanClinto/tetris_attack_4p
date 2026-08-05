incsrc "context-dispatch-probe.asm"

org $808E4D
    jsl LiveFourBoardHook

org $808E7B
    jsl LiveFourBoardHook

org $A08400
LiveFourBoardHook:
    jsl $8090F3
    jsl RenderLiveFourBoards
    rtl

org $A08500
RenderLiveFourBoards:
    php
    rep #$30
    pha
    phx
    phy
    phb

    sep #$20
    lda.l $7E01BA
    cmp #$02
    beq .mode2
    lda #$00
    sta.l $7FFE3E
    sta.l $7FFE3F
    sta.l $7FFE46
    brl .done

.mode2:
    lda.l $7FFE3E
    bne .initialized
    inc
    sta.l $7FFE3E
    jsr UploadPanelTiles
    jsr InitializeOffsets

.initialized:
    sep #$20
    lda #$78
    sta.l $7E01BD
    sta.l $002108
    lda #$80
    sta.l $002115

    rep #$30
    sep #$20
    lda.l $7FFE3F
    inc
    cmp #$06
    bcc .storePhase
    lda #$00
.storePhase:
    sta.l $7FFE3F
    beq .rows0
    cmp #$01
    beq .rows1
    cmp #$02
    beq .rows2
    cmp #$03
    beq .rows3
    cmp #$04
    beq .rows4

    rep #$20
    lda #$00C0
    sta.l $7FFE40
    rep #$10
    ldx #$00A0
    bra .rowLoop

.rows4:
    rep #$20
    lda #$00A0
    sta.l $7FFE40
    rep #$10
    ldx #$0080
    bra .rowLoop

.rows3:
    rep #$20
    lda #$0080
    sta.l $7FFE40
    rep #$10
    ldx #$0060
    bra .rowLoop

.rows2:
    rep #$20
    lda #$0060
    sta.l $7FFE40
    rep #$10
    ldx #$0040
    bra .rowLoop

.rows1:
    rep #$20
    lda #$0040
    sta.l $7FFE40
    rep #$10
    ldx #$0020
    bra .rowLoop

.rows0:
    rep #$20
    lda #$0020
    sta.l $7FFE40
    rep #$10
    ldx #$0000
.rowLoop:
    txa
    asl
    clc
    adc #$78C1
    tay

    tya
    sta.l $002116
    jsr DrawP1Row
    tya
    clc
    adc #$0008
    tay
    sta.l $002116
    jsr DrawP2Row
    tya
    clc
    adc #$0008
    tay
    sta.l $002116
    jsr DrawP3Row
    tya
    clc
    adc #$0008
    tay
    sta.l $002116
    jsr DrawP4Row

    txa
    clc
    adc #$0010
    tax
    cmp.l $7FFE40
    bne .rowLoop

    jsr RenderCursors
    jsr RenderLabels
    jsr InitializeBoardFrameBatch

    sep #$20
    lda #$00
    sta.l $00210F
    sta.l $00210F
    sta.l $002110
    sta.l $002110

    lda #$02
    sta.l $7E01E2
    sta.l $00212C

.done:
    rep #$30
    plb
    ply
    plx
    pla
    plp
    rtl

UploadPanelTiles:
    sep #$20
    lda #$80
    sta.l $002115
    rep #$20
    lda #$5E00
    sta.l $002116
    sep #$20
    rep #$10
    ldx #$0000
.loop:
    lda.l PanelTiles,x
    sta.l $002118
    inx
    lda.l PanelTiles,x
    sta.l $002119
    inx
    cpx #$0220
    bne .loop
    rts

InitializeOffsets:
    sep #$20
    lda #$80
    sta.l $002115
    rep #$20
    lda #$6020
    sta.l $002116
    lda #$0000
    sta.l $002118
    lda #$4000
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118
    sta.l $002118
    lda #$4000
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118
    sta.l $002118
    lda #$4000
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118
    sta.l $002118
    lda #$4000
    jsr WriteOffsetGroup
    lda #$0000
    sta.l $002118
    rts

WriteOffsetGroup:
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    rts

PanelWord:
    and #$00FF
    beq .blank
    cmp #$0005
    beq .diamond
    bcs .blank
    clc
    adc #$07E0
    rts

.diamond:
    lda #$0BE5
    rts

.blank:
    lda #$03E0
    rts

SelectedPanelWord:
    and #$00FF
    beq .blank
    cmp #$0005
    beq .diamond
    bcs .blank
    clc
    adc #$07E5
    rts

.diamond:
    lda #$0BEA
    rts

.blank:
    lda #$03E0
    rts

RenderCursors:
    lda.l $7E03A8
    tay
    lda.l $7E03A4
    jsr RenderP1Cursor
    lda.l $7E03AA
    tay
    lda.l $7E03A6
    jsr RenderP2Cursor
    lda.l $7F0C28
    tay
    lda.l $7F0C26
    jsr RenderP3Cursor
    lda.l $7F1428
    tay
    lda.l $7F1426
    jsr RenderP4Cursor
    rts

CursorTilemapAddress:
    sta.l $7FFE42
    tya
    asl
    asl
    asl
    asl
    asl
    clc
    adc.l $7FFE44
    adc.l $7FFE42
    sta.l $002116
    rts

CursorSourceOffset:
    asl
    asl
    asl
    clc
    adc.l $7FFE42
    asl
    tax
    rts

RenderP1Cursor:
    pha
    lda #$78C1
    sta.l $7FFE44
    pla
    jsr CursorTilemapAddress
    tya
    jsr CursorSourceOffset
    lda.l $7E0FAE,x
    jsr SelectedPanelWord
    sta.l $002118
    lda.l $7E0FB0,x
    jsr SelectedPanelWord
    sta.l $002118
    rts

RenderP2Cursor:
    pha
    lda #$78C9
    sta.l $7FFE44
    pla
    jsr CursorTilemapAddress
    tya
    jsr CursorSourceOffset
    lda.l $7E10AE,x
    jsr SelectedPanelWord
    sta.l $002118
    lda.l $7E10B0,x
    jsr SelectedPanelWord
    sta.l $002118
    rts

RenderP3Cursor:
    pha
    lda #$78D1
    sta.l $7FFE44
    pla
    jsr CursorTilemapAddress
    tya
    jsr CursorSourceOffset
    lda.l $7F0932,x
    jsr SelectedPanelWord
    sta.l $002118
    lda.l $7F0934,x
    jsr SelectedPanelWord
    sta.l $002118
    rts

RenderP4Cursor:
    pha
    lda #$78D9
    sta.l $7FFE44
    pla
    jsr CursorTilemapAddress
    tya
    jsr CursorSourceOffset
    lda.l $7F1132,x
    jsr SelectedPanelWord
    sta.l $002118
    lda.l $7F1134,x
    jsr SelectedPanelWord
    sta.l $002118
    rts

RenderLabels:
    lda #$7883
    sta.l $002116
    lda #$07EB
    sta.l $002118
    lda #$788B
    sta.l $002116
    lda #$07EC
    sta.l $002118
    lda #$7893
    sta.l $002116
    lda #$07ED
    sta.l $002118
    lda #$789B
    sta.l $002116
    lda #$07EE
    sta.l $002118
    rts

InitializeBoardFrameBatch:
    sep #$20
    lda.l $7FFE46
    cmp #$14
    bcc .writeBatch
    jmp .done

.writeBatch:
    inc
    sta.l $7FFE46
    dec
    rep #$30
    and #$00FF
    cmp #$000C
    bcc .sides
    cmp #$0010
    bcc .top

    sec
    sbc #$0010
    asl
    asl
    asl
    clc
    adc #$7A40
    bra .horizontal

.top:
    sec
    sbc #$000C
    asl
    asl
    asl
    clc
    adc #$78A0

.horizontal:
    sta.l $002116
    lda #$07F0
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    sta.l $002118
    bra .done

.sides:
    asl
    asl
    asl
    asl
    asl
    clc
    adc #$78C0
    sta.l $7FFE48
    ldx #$0000
.sideLoop:
    lda.l BorderColumns,x
    clc
    adc.l $7FFE48
    sta.l $002116
    lda #$07EF
    sta.l $002118
    inx
    inx
    cpx #$0010
    bne .sideLoop

.done:
    rep #$30
    rts

BorderColumns:
    dw $0000,$0007,$0008,$000F,$0010,$0017,$0018,$001F

DrawP1Row:
    lda.l $7E0FAE,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E0FB0,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E0FB2,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E0FB4,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E0FB6,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E0FB8,x
    jsr PanelWord
    sta.l $002118
    rts

DrawP2Row:
    lda.l $7E10AE,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E10B0,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E10B2,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E10B4,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E10B6,x
    jsr PanelWord
    sta.l $002118
    lda.l $7E10B8,x
    jsr PanelWord
    sta.l $002118
    rts

DrawP3Row:
    lda.l $7F0932,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F0934,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F0936,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F0938,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F093A,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F093C,x
    jsr PanelWord
    sta.l $002118
    rts

DrawP4Row:
    lda.l $7F1132,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F1134,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F1136,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F1138,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F113A,x
    jsr PanelWord
    sta.l $002118
    lda.l $7F113C,x
    jsr PanelWord
    sta.l $002118
    rts

assert pc() <= $A08D00

org $A09400
PanelTiles:
    incbin "../build/panel-tiles.4bpp"

assert pc() == $A09620