local expected = {
    0xA5A0,
    0x5A50,
    0xC3C0,
    0x3C30,
}

local selectedPair = 0
local pairReadIndex = { 0, 0 }
local pollCount = 0

emu.addMemoryCallback(function(_, value)
    selectedPair = (value & 0x80) ~= 0 and 1 or 2
    pairReadIndex[selectedPair] = 0
end, emu.callbackType.write, 0x004201)

emu.addMemoryCallback(function(_, value)
    if value == 1 then
        pairReadIndex[1] = 0
        pairReadIndex[2] = 0
    end
end, emu.callbackType.write, 0x004016)

emu.addMemoryCallback(function()
    local index = pairReadIndex[selectedPair]
    local firstPad = selectedPair == 1 and 1 or 3
    local shift = 15 - index
    local value = ((expected[firstPad] >> shift) & 1) |
        (((expected[firstPad + 1] >> shift) & 1) << 1)
    pairReadIndex[selectedPair] = index + 1
    return value
end, emu.callbackType.read, 0x004017)

emu.addMemoryCallback(function()
    pollCount = pollCount + 1
end, emu.callbackType.exec, 0xA08200)

local frames = 0
emu.addEventCallback(function()
    frames = frames + 1
    if frames >= 120 then
        if pollCount == 0 then
            emu.stop(2)
            return
        end

        for index = 1, 4 do
            local actual = emu.read16(
                0x1FE00 + (index - 1) * 2,
                emu.memType.snesWorkRam
            )
            if actual ~= expected[index] then
                emu.stop(10 + index)
                return
            end
        end

        emu.stop(0)
    end
end, emu.eventType.startFrame)
