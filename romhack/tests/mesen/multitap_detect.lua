local frames = 0
local p1Reads = 0
local p1Observed = false
local strobeWritten = false
local serialRead = false
local serialBitSet = false

local function observeStrobeWrite()
    strobeWritten = true
end

local function observeSerialRead(_, value)
    serialRead = true
    serialBitSet = serialBitSet or (value & 0x02) ~= 0
end

for _, bank in ipairs({ 0x000000, 0x800000 }) do
    emu.addMemoryCallback(
        observeStrobeWrite,
        emu.callbackType.write,
        bank + 0x4016
    )
    emu.addMemoryCallback(
        observeSerialRead,
        emu.callbackType.read,
        bank + 0x4017
    )
end

emu.addMemoryCallback(function()
    p1Reads = p1Reads + 1
end, emu.callbackType.exec, 0x809C10)

emu.addMemoryCallback(function()
    p1Observed = p1Observed or
        emu.read16(0x00B3, emu.memType.snesWorkRam) ~= 0
end, emu.callbackType.exec, 0x809C1A)

emu.addEventCallback(function()
    frames = frames + 1

    if frames >= 600 then
        if p1Reads == 0 then
            emu.stop(2)
        elseif not strobeWritten then
            emu.stop(8)
        elseif not serialRead then
            emu.stop(9)
        elseif not serialBitSet then
            emu.stop(10)
        elseif p1Observed then
            emu.stop(0)
        else
            emu.stop(11)
        end
    end
end, emu.eventType.startFrame)
