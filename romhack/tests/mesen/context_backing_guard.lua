local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local accesses = 0

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

local function observeRead()
    if frame >= 4400 then
        accesses = accesses + 1
        emu.stop(1)
    end
end

local function observeWrite()
    if frame >= 4400 then
        accesses = accesses + 1
        emu.stop(2)
    end
end

emu.addMemoryCallback(
    observeRead,
    emu.callbackType.read,
    0x10000,
    0x10FFF,
    emu.cpuType.snes,
    emu.memType.snesWorkRam
)
emu.addMemoryCallback(
    observeWrite,
    emu.callbackType.write,
    0x10000,
    0x10FFF,
    emu.cpuType.snes,
    emu.memType.snesWorkRam
)

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

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()
    if frame >= 4780 then
        emu.stop(accesses == 0 and 0 or 1)
    end
end, emu.eventType.startFrame)
