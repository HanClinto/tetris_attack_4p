local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local seeded = false
local sawRoutedStaging = false
local sawP3Transfer = false
local sawP3Materializer = false
local swapInjected = false

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

local function setMenuInput()
    syntheticInput1 = 0
    syntheticInput2 = 0
    if frame == 4700 then
        writeWord(0x1200C, 0xC35A)
    end
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

local function seedNativeP1Clear()
    writeWord(0x03A4, 3)
    writeWord(0x03A8, 9)
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
end

emu.addMemoryCallback(function()
    if not seeded and frame >= 4700 and
        emu.read(0x12004, emu.memType.snesWorkRam) == 1 then
        seeded = true
        seedNativeP1Clear()
    end
end, emu.callbackType.exec, 0x829D93)

emu.addMemoryCallback(function()
    if seeded and not swapInjected and readWord(0x0360) == 0 then
        writeWord(0x00B7, 0x0080)
        swapInjected = true
    end
end, emu.callbackType.exec, 0x82A9C8)

emu.addMemoryCallback(function()
    if readWord(0x10C0C) == 1 and readWord(0x0446) == 0 then
        sawRoutedStaging = true
    end
end, emu.callbackType.exec, 0x89AEE4)

emu.addMemoryCallback(function()
    if emu.read(0x12001, emu.memType.snesWorkRam) == 3 and
        readWord(0x0440) == 1 and readWord(0x0444) == 0 then
        sawP3Transfer = true
    end
end, emu.callbackType.exec, 0x82ABE3)

emu.addMemoryCallback(function()
    if emu.read(0x12001, emu.memType.snesWorkRam) == 3 then
        sawP3Materializer = true
    end
end, emu.callbackType.exec, 0x8697EB)

emu.addMemoryCallback(function()
    if emu.read(0x12005, emu.memType.snesWorkRam) ~= 3 then
        return
    end
    local slabSaved =
        readWord(0x10832) == 0x0003 and
        readWord(0x10834) == 0x0003 and
        readWord(0x10836) == 0x0003 and
        readWord(0x10932) == 0x0401 and
        readWord(0x10934) == 0x0402 and
        readWord(0x10936) == 0x0403
    if seeded and sawRoutedStaging and sawP3Transfer and
        sawP3Materializer and slabSaved then
        emu.stop(0)
    end
end, emu.callbackType.exec, 0xA08BF0)

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()
    if frame == 5200 then
        print(string.format(
            "timeout seeded=%s routed=%s transfer=%s materializer=%s p2=$%04X p3=$%04X/%04X slab=%04X,%04X,%04X/%04X,%04X,%04X",
            tostring(seeded),
            tostring(sawRoutedStaging),
            tostring(sawP3Transfer),
            tostring(sawP3Materializer),
            readWord(0x0446),
            readWord(0x10C0A),
            readWord(0x10C0C),
            readWord(0x10832),
            readWord(0x10834),
            readWord(0x10836),
            readWord(0x10932),
            readWord(0x10934),
            readWord(0x10936)
        ))
        emu.stop(2)
    end
end, emu.eventType.startFrame)
