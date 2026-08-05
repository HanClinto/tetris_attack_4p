local expectedOffsets = {
    0x0000,
    0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000,
    0x0000, 0x0000,
    0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000,
    0x0000, 0x0000,
    0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000,
    0x0000, 0x0000,
    0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000,
    0x0000,
}

local mode2Frames = 0

local function readVram16(address)
    return emu.read16(address, emu.memType.snesVideoRam)
end

local function verifyWells()
    local boardColumns = { 1, 9, 17, 25 }
    for _, startColumn in ipairs(boardColumns) do
        for row = 6, 17 do
            for column = startColumn, startColumn + 5 do
                local wordAddress = 0x7800 + row * 32 + column
                if readVram16(wordAddress * 2) ~= 0 then
                    return false
                end
            end
        end
    end
    return true
end

local function verifyOffsets()
    for index, expected in ipairs(expectedOffsets) do
        local wordAddress = 0x6020 + index - 1
        local actual = readVram16(wordAddress * 2)
        if actual ~= expected then
            return false, index, actual
        end
    end
    return true, 0, 0
end

emu.addMemoryCallback(function()
    if emu.read(0x01BA, emu.memType.snesWorkRam) ~= 0x02 then
        return
    end

    mode2Frames = mode2Frames + 1
    if mode2Frames < 1 then
        return
    end

    local offsetsMatch, mismatchIndex, actualOffset = verifyOffsets()
    if not verifyWells() then
        emu.stop(2)
    elseif not offsetsMatch then
        if actualOffset == 0x2000 then
            emu.stop(32 + mismatchIndex)
        elseif actualOffset == 0 then
            emu.stop(80 + mismatchIndex)
        else
            emu.stop(128 + mismatchIndex)
        end
    else
        emu.stop(0)
    end
end, emu.callbackType.exec, 0xA08408)
