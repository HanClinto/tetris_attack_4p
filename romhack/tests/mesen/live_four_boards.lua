local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0

local boardSources = {
    0x0FAE,
    0x10AE,
    0x10932,
    0x11132,
}
local cursorSources = {
    { x = 0x03A4, y = 0x03A8 },
    { x = 0x03A6, y = 0x03AA },
    { x = 0x10C26, y = 0x10C28 },
    { x = 0x11426, y = 0x11428 },
}

for _, bank in ipairs({ 0x000000, 0x800000 }) do
    emu.addMemoryCallback(function() return syntheticInput1 & 0xFF end,
        emu.callbackType.read, bank + 0x4218)
    emu.addMemoryCallback(function() return (syntheticInput1 >> 8) & 0xFF end,
        emu.callbackType.read, bank + 0x4219)
    emu.addMemoryCallback(function() return syntheticInput2 & 0xFF end,
        emu.callbackType.read, bank + 0x421A)
    emu.addMemoryCallback(function() return (syntheticInput2 >> 8) & 0xFF end,
        emu.callbackType.read, bank + 0x421B)
end

local function setMenuInput()
    syntheticInput1 = 0
    syntheticInput2 = 0
    if frame >= 1190 and frame <= 1195 then
        syntheticInput1 = 0x8000
    elseif frame >= 1450 and frame <= 1455 then
        syntheticInput1 = 0x0400
    elseif frame >= 1500 and frame <= 1505 then
        syntheticInput1 = 0x0080
    elseif frame >= 2050 and frame <= 2055 then
        syntheticInput1 = 0x0400
    elseif frame >= 2100 and frame <= 2105 then
        syntheticInput1 = 0x0080
    elseif (frame >= 3250 and frame <= 3255) or
        (frame >= 4050 and frame <= 4055) then
        syntheticInput1 = 0x0080
        syntheticInput2 = 0x0080
    end
end

local function panelWord(color)
    color = color & 0xFF
    if color >= 1 and color <= 4 then
        return 0x07E0 + color
    elseif color == 5 then
        return 0x0BE5
    else
        return 0x03E0
    end
end

local function selectedPanelWord(color)
    color = color & 0xFF
    if color >= 1 and color <= 4 then
        return 0x07E5 + color
    elseif color == 5 then
        return 0x0BEA
    else
        return 0x03E0
    end
end

local function verifyBoard(boardIndex)
    local sourceBase = boardSources[boardIndex]
    local startColumn = 1 + (boardIndex - 1) * 8
    local cursor = cursorSources[boardIndex]
    local cursorColumn = emu.read16(cursor.x, emu.memType.snesWorkRam)
    local cursorRow = emu.read16(cursor.y, emu.memType.snesWorkRam)
    local nonempty = 0
    for row = 0, 11 do
        for column = 0, 5 do
            local color = emu.read16(
                sourceBase + row * 0x10 + column * 2,
                emu.memType.snesWorkRam
            )
            local selected = row == cursorRow and
                (column == cursorColumn or column == cursorColumn + 1)
            local expected = selected and
                selectedPanelWord(color) or panelWord(color)
            local wordAddress = 0x7800 + (row + 6) * 32 + startColumn + column
            local actual = emu.read16(
                wordAddress * 2,
                emu.memType.snesVideoRam
            )
            if actual ~= expected then
                print(string.format(
                    "board=%d row=%d column=%d color=$%04X expected=$%04X actual=$%04X",
                    boardIndex,
                    row,
                    column,
                    color,
                    expected,
                    actual
                ))
                return false
            end
            if color >= 1 and color <= 5 then
                nonempty = nonempty + 1
            end
        end
    end
    return nonempty >= 12
end

local function verifyTileUpload()
    local nonzero = 0
    for address = 0xBC20, 0xBCBF do
        if emu.read(address, emu.memType.snesVideoRam) ~= 0 then
            nonzero = nonzero + 1
        end
    end
    return nonzero >= 40
end

local function verifyCursors()
    for boardIndex = 1, 4 do
        local cursor = cursorSources[boardIndex]
        local column = emu.read16(cursor.x, emu.memType.snesWorkRam)
        local row = emu.read16(cursor.y, emu.memType.snesWorkRam)
        if column > 4 or row > 11 then
            return false
        end
        local sourceBase = boardSources[boardIndex] + row * 0x10 + column * 2
        local startColumn = 1 + (boardIndex - 1) * 8 + column
        for cell = 0, 1 do
            local color = emu.read16(
                sourceBase + cell * 2,
                emu.memType.snesWorkRam
            )
            local wordAddress = 0x7800 + (row + 6) * 32 + startColumn + cell
            local actual = emu.read16(
                wordAddress * 2,
                emu.memType.snesVideoRam
            )
            if actual ~= selectedPanelWord(color) then
                return false
            end
        end
    end
    return true
end

local function verifyLabels()
    local columns = { 3, 11, 19, 27 }
    for index, column in ipairs(columns) do
        local actual = emu.read16(
            (0x7800 + 5 * 32 + column) * 2,
            emu.memType.snesVideoRam
        )
        if actual ~= 0x07EA + index then
            return false
        end
    end
    return true
end

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == 4700 then
        emu.write(0x12000, 0xA5, emu.memType.snesWorkRam)
    elseif frame == 4708 then
        emu.write(0x12000, 0x00, emu.memType.snesWorkRam)
    elseif frame == 4720 then
        local state = emu.getState()
        if emu.read(0x01BA, emu.memType.snesWorkRam) ~= 0x02 or
            state["ppu.bgMode"] ~= 0x02 then
            emu.stop(2)
        elseif state["ppu.layers[1].tilemapAddress"] ~= 0x7800 or
            state["ppu.layers[1].chrAddress"] ~= 0x2000 or
            state["ppu.layers[1].hscroll"] ~= 0 or
            state["ppu.layers[1].vscroll"] ~= 0 then
            emu.stop(8)
        elseif not verifyTileUpload() then
            emu.stop(3)
        else
            for boardIndex = 1, 4 do
                if not verifyBoard(boardIndex) then
                    emu.stop(3 + boardIndex)
                    return
                end
            end
            if not verifyCursors() then
                emu.stop(9)
            elseif not verifyLabels() then
                emu.stop(10)
            else
                emu.stop(0)
            end
        end
    end
end, emu.eventType.startFrame)