local mode2Frames = 0

local expectedByFrame = {
    { 0, 0, 0, 0 },
    { 1023, 0, 0, 0 },
    { 1023, 1, 0, 0 },
    { 1023, 1, 1023, 0 },
    { 1023, 1, 1023, 1 },
}

local rawByFrame = {
    { 0, 0, 0, 0 },
    { 0x0800, 0, 0, 0 },
    { 0, 0x0400, 0, 0 },
    { 0, 0, 0x0800, 0 },
    { 0, 0, 0, 0x0400 },
}

local function writeRawPads(values)
    for index = 1, 4 do
        emu.write16(
            0x1FE00 + (index - 1) * 2,
            values[index],
            emu.memType.snesWorkRam
        )
    end
end

local function verifyScrollVariables(expected)
    for index = 1, 4 do
        local actual = emu.read16(
            0x1FE30 + (index - 1) * 2,
            emu.memType.snesWorkRam
        )
        if actual ~= expected[index] then
            return false
        end
    end
    return true
end

local function verifyOffsetGroup(startColumn, expected)
    local expectedWord = 0x4000 | expected
    for column = startColumn, startColumn + 5 do
        local wordAddress = 0x6020 + column
        if emu.read16(wordAddress * 2, emu.memType.snesVideoRam) ~= expectedWord then
            return false
        end
    end
    return true
end

emu.addMemoryCallback(function()
    if emu.read(0x01BA, emu.memType.snesWorkRam) ~= 0x02 then
        return
    end

    mode2Frames = mode2Frames + 1
    if mode2Frames <= #rawByFrame then
        writeRawPads(rawByFrame[mode2Frames])
    end
end, emu.callbackType.exec, 0xA08400)

emu.addMemoryCallback(function()
    if mode2Frames == 0 or mode2Frames > #expectedByFrame then
        return
    end

    local expected = expectedByFrame[mode2Frames]
    if not verifyScrollVariables(expected) then
        emu.stop(10 + mode2Frames)
        return
    end

    local groupStarts = { 1, 9, 17, 25 }
    for index = 1, 4 do
        if not verifyOffsetGroup(groupStarts[index], expected[index]) then
            emu.stop(20 + mode2Frames)
            return
        end
    end

    if mode2Frames == #expectedByFrame then
        emu.stop(0)
    end
end, emu.callbackType.exec, 0xA08408)
