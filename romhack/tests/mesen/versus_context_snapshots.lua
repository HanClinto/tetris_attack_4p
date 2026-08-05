local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0

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

local function dumpWram(name)
    local output = assert(io.open(outputFolder .. "/" .. name .. ".bin", "wb"))
    for address = 0, 0x1FFFF do
        output:write(string.char(emu.read(address, emu.memType.snesWorkRam)))
    end
    output:close()
end

local function setInput()
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
    elseif frame >= 4510 and frame <= 4512 then
        syntheticInput1 = 0x0100
    elseif frame >= 4520 and frame <= 4522 then
        syntheticInput1 = 0x0080
    elseif frame >= 4550 and frame <= 4552 then
        syntheticInput2 = 0x0200
    elseif frame >= 4560 and frame <= 4562 then
        syntheticInput2 = 0x0080
    end
end

emu.addEventCallback(function()
    frame = frame + 1
    setInput()

    if frame == 4500 then
        dumpWram("baseline")
    elseif frame == 4540 then
        dumpWram("after-p1")
    elseif frame == 4580 then
        dumpWram("after-p2")
        emu.stop(0)
    end
end, emu.eventType.startFrame)
