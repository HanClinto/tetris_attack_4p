local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local p3Before = nil
local p4Before = nil
local sawP3Input = false
local sawP4Input = false

local padInputs = { {}, {}, {}, {} }

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

emu.addMemoryCallback(function(_, value)
    if value == 0 then
        for subport = 0, 3 do
            emu.setInput(padInputs[subport + 1], 0, 1, subport)
        end
    end
end, emu.callbackType.write, 0x004016)

local function readWord(address)
    return emu.read16(address, emu.memType.snesWorkRam)
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

local function verifyCursor(boardBase, scalarBase, startColumn)
    local column = readWord(scalarBase + 0x26)
    local row = readWord(scalarBase + 0x28)
    if column > 4 or row > 11 then
        return false
    end
    for cell = 0, 1 do
        local color = readWord(boardBase + row * 0x10 + (column + cell) * 2)
        local tilemapAddress =
            0x7800 + (row + 6) * 32 + startColumn + column + cell
        local actual = emu.read16(
            tilemapAddress * 2,
            emu.memType.snesVideoRam
        )
        if actual ~= selectedPanelWord(color) then
            return false
        end
    end
    return true
end

emu.addMemoryCallback(function()
    if readWord(0x1FE10) == 0x0100 then
        sawP3Input = true
    end
    if readWord(0x1FE20) == 0x0400 then
        sawP4Input = true
    end
end, emu.callbackType.exec, 0xA08010)

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == 4700 then
        p3Before = { x = readWord(0x10C26), y = readWord(0x10C28) }
        p4Before = { x = readWord(0x11426), y = readWord(0x11428) }
    elseif frame >= 4710 and frame <= 4712 then
        padInputs[2] = { right = true }
        padInputs[3] = { down = true }
    elseif frame == 4713 then
        padInputs[2] = {}
        padInputs[3] = {}
    elseif frame == 4740 then
        emu.write(0x12000, 0, emu.memType.snesWorkRam)
    elseif frame == 4760 then
        local p3X = readWord(0x10C26)
        local p3Y = readWord(0x10C28)
        local p4X = readWord(0x11426)
        local p4Y = readWord(0x11428)
        if not sawP3Input or not sawP4Input then
            emu.stop(2)
        elseif p3X ~= p3Before.x + 1 or p3Y ~= p3Before.y then
            print(string.format(
                "p3 before=%d,%d after=%d,%d input=$%04X",
                p3Before.x,
                p3Before.y,
                p3X,
                p3Y,
                readWord(0x1FE10)
            ))
            emu.stop(3)
        elseif p4X ~= p4Before.x or p4Y ~= p4Before.y + 1 then
            print(string.format(
                "p4 before=%d,%d after=%d,%d input=$%04X",
                p4Before.x,
                p4Before.y,
                p4X,
                p4Y,
                readWord(0x1FE20)
            ))
            emu.stop(4)
        elseif not verifyCursor(0x10932, 0x10C00, 17) then
            emu.stop(5)
        elseif not verifyCursor(0x11132, 0x11400, 25) then
            emu.stop(6)
        else
            emu.stop(0)
        end
    end
end, emu.eventType.startFrame)