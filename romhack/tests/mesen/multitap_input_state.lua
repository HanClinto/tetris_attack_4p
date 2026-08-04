local pollCount = 0
local selectedPair = 0
local pairReadIndex = { 0, 0 }

local function rawPads()
    if pollCount <= 10 then
        return { 0, 0, 0, 0 }
    elseif pollCount <= 12 then
        return { 0, 0x8000, 0x4000, 0 }
    else
        return { 0, 0, 0, 0 }
    end
end

local function readState(address)
    return emu.read16(address, emu.memType.snesWorkRam)
end

local function assertState(baseAddress, current, pressed, repeated, previous)
    return readState(baseAddress) == current and
        readState(baseAddress + 2) == pressed and
        readState(baseAddress + 4) == repeated and
        readState(baseAddress + 6) == previous
end

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
    local pads = rawPads()
    local index = pairReadIndex[selectedPair]
    local firstPad = selectedPair == 1 and 1 or 3
    local shift = 15 - index
    local value = ((pads[firstPad] >> shift) & 1) |
        (((pads[firstPad + 1] >> shift) & 1) << 1)
    pairReadIndex[selectedPair] = index + 1
    return value
end, emu.callbackType.read, 0x004017)

emu.addMemoryCallback(function()
    pollCount = pollCount + 1
end, emu.callbackType.exec, 0xA08200)

emu.addMemoryCallback(function()
    if pollCount == 11 then
        if not assertState(0x1FE10, 0x8000, 0x8000, 0x8000, 0x8000) or
            not assertState(0x1FE20, 0x4000, 0x4000, 0x4000, 0x4000) then
            emu.stop(11)
        end
    elseif pollCount == 12 then
        if not assertState(0x1FE10, 0x8000, 0, 0, 0x8000) or
            not assertState(0x1FE20, 0x4000, 0, 0, 0x4000) then
            emu.stop(12)
        end
    elseif pollCount == 13 then
        if not assertState(0x1FE10, 0, 0, 0, 0) or
            not assertState(0x1FE20, 0, 0, 0, 0) then
            emu.stop(13)
        else
            emu.stop(0)
        end
    end
end, emu.callbackType.exec, 0xA08010)
