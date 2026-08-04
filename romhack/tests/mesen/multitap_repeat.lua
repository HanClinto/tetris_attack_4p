local pollCount = 0
local selectedPair = 0
local pairReadIndex = { 0, 0 }
local repeatSeenAt = nil

local function rawPads()
    if pollCount <= 10 or repeatSeenAt ~= nil then
        return { 0, 0, 0, 0 }
    end
    return { 0, 0x8000, 0, 0 }
end

local function readState(address)
    return emu.read16(address, emu.memType.snesWorkRam)
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
    local current = readState(0x1FE10)
    local pressed = readState(0x1FE12)
    local repeated = readState(0x1FE14)

    if pollCount == 11 then
        if current ~= 0x8000 or pressed ~= 0x8000 or repeated ~= 0x8000 then
            emu.stop(11)
        end
    elseif pollCount > 11 and repeatSeenAt == nil then
        if pressed ~= 0 then
            emu.stop(12)
        elseif repeated ~= 0 then
            if repeated ~= 0x8000 or
                readState(0x1FE18) ~= readState(0x00B1) then
                emu.stop(13)
            else
                repeatSeenAt = pollCount
            end
        elseif pollCount >= 200 then
            emu.stop(14)
        end
    elseif pollCount == repeatSeenAt + 1 then
        if current ~= 0 or pressed ~= 0 or repeated ~= 0 then
            emu.stop(15)
        else
            emu.stop(0)
        end
    end
end, emu.callbackType.exec, 0xA08010)
