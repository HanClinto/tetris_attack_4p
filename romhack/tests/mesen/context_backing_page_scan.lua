local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local reads = {}
local writes = {}

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

local function pageForAddress(address)
    if address <= 0x1FFFF then
        return (address - 0x10000) >> 8
    end
    return (address & 0xFFFF) >> 8
end

emu.addMemoryCallback(function(address)
    if frame >= 4400 then
        reads[pageForAddress(address)] = true
    end
end, emu.callbackType.read, 0x10000, 0x12FFF,
    emu.cpuType.snes, emu.memType.snesWorkRam)

emu.addMemoryCallback(function(address)
    if frame >= 4400 then
        writes[pageForAddress(address)] = true
    end
end, emu.callbackType.write, 0x10000, 0x12FFF,
    emu.cpuType.snes, emu.memType.snesWorkRam)

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
        local output = assert(io.open(outputFolder .. "/pages.txt", "w"))
        for page = 0, 0x2F do
            output:write(string.format(
                "%02X read=%s write=%s\n",
                page,
                tostring(reads[page] == true),
                tostring(writes[page] == true)
            ))
        end
        output:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)
