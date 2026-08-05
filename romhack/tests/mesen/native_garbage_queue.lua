local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local sawFourClear = false
local sawStagingIncrement = false
local sawQueueTransfer = false
local sawMaterializer = false

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

local function readWord(address)
    return emu.read16(address, emu.memType.snesWorkRam)
end

local function writeWord(address, value)
    emu.write(address, value & 0xFF, emu.memType.snesWorkRam)
    emu.write(address + 1, (value >> 8) & 0xFF,
        emu.memType.snesWorkRam)
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
    elseif frame >= 4720 and frame <= 4722 then
        syntheticInput1 = 0x0080
    end
end

emu.addMemoryCallback(function()
    if readWord(0x66E4) == 4 then
        sawFourClear = true
    end
end, emu.callbackType.exec, 0x82B0EF)

emu.addMemoryCallback(function()
    if readWord(0x0446) == 1 then
        sawStagingIncrement = true
    end
end, emu.callbackType.exec, 0x89AEE4)

emu.addMemoryCallback(function()
    if readWord(0x0442) == 1 and readWord(0x0446) == 0 then
        sawQueueTransfer = true
    end
end, emu.callbackType.exec, 0x82ABE3)

emu.addMemoryCallback(function()
    sawMaterializer = true
end, emu.callbackType.exec, 0x8697EB)

emu.addMemoryCallback(function()
    local validSlab =
        readWord(0x0EAE) == 0x0003 and
        readWord(0x0EB0) == 0x0003 and
        readWord(0x0EB2) == 0x0003 and
        readWord(0x10AE) == 0x0401 and
        readWord(0x10B0) == 0x0402 and
        readWord(0x10B2) == 0x0403
    if sawFourClear and sawStagingIncrement and sawQueueTransfer and
        sawMaterializer and validSlab then
        emu.stop(0)
    else
        print(string.format(
            "four=%s staging=%s transfer=%s materializer=%s slab=%04X,%04X,%04X/%04X,%04X,%04X",
            tostring(sawFourClear),
            tostring(sawStagingIncrement),
            tostring(sawQueueTransfer),
            tostring(sawMaterializer),
            readWord(0x0EAE),
            readWord(0x0EB0),
            readWord(0x0EB2),
            readWord(0x10AE),
            readWord(0x10B0),
            readWord(0x10B2)
        ))
        emu.stop(3)
    end
end, emu.callbackType.exec, 0x869849)

emu.addEventCallback(function()
    frame = frame + 1
    setInput()

    if frame == 4700 then
        for _, seed in ipairs({
            { 0x0FF2, 1 },
            { 0x1002, 1 },
            { 0x1012, 2 },
            { 0x1014, 1 },
            { 0x1022, 1 },
        }) do
            writeWord(seed[1] - 0x0200, 0)
            writeWord(seed[1], seed[2])
            writeWord(seed[1] + 0x0200, 0)
            writeWord(seed[1] + 0x0400, 0)
        end
    elseif frame == 5000 then
        print(string.format(
            "timeout four=%s staging=%s transfer=%s materializer=%s",
            tostring(sawFourClear),
            tostring(sawStagingIncrement),
            tostring(sawQueueTransfer),
            tostring(sawMaterializer)
        ))
        emu.stop(2)
    end
end, emu.eventType.startFrame)
