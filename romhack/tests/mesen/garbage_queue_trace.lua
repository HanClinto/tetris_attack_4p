local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local triggerAttack = os.getenv("TA4P_TRIGGER_ATTACK") ~= "0"
local syntheticInput1 = 0
local syntheticInput2 = 0
local tracing = false
local events = {}
local detailedEvents = {}
local inputSites = {}
local inputAccesses = {}
local attackStateAccesses = {}
local constructorEvents = {}
local garbagePlaneWrites = {}

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

local function normalizeWramAddress(address)
    if address <= 0x1FFFF then
        return address
    end
    local bank = (address >> 16) & 0xFF
    local bankAddress = address & 0xFFFF
    if bank == 0x7E or bank == 0x7F then
        return address - 0x7E0000
    elseif bankAddress < 0x2000 and
        (bank <= 0x3F or (bank >= 0x80 and bank <= 0xBF)) then
        return bankAddress
    end
    return nil
end

local function observeWrite(address, value)
    if not tracing then
        return
    end
    local normalized = normalizeWramAddress(address)
    if normalized == nil or
        (normalized >= 0x0D7C and normalized <= 0x156B) then
        return
    end
    events[normalized] = (events[normalized] or 0) + 1
    if (normalized >= 0x04B0 and normalized <= 0x04DF) or
        (normalized >= 0x083E and normalized <= 0x0C7F) then
        local state = emu.getState()
        local pc = (state["cpu.k"] or 0) * 0x10000 +
            (state["cpu.pc"] or 0)
        local key = string.format(
            "%06X:%04X:%02X:%04X:%04X",
            pc,
            normalized,
            value or 0,
            state["cpu.x"] or 0,
            state["cpu.y"] or 0
        )
        detailedEvents[key] = (detailedEvents[key] or 0) + 1
    end
end

emu.addMemoryCallback(
    observeWrite,
    emu.callbackType.write,
    0,
    0x1FFFF,
    emu.cpuType.snes,
    emu.memType.snesWorkRam
)

local function observeInputAccess(operation, address, value)
    if frame < 4695 or frame > 4730 then
        return
    end
    local state = emu.getState()
    local pc = (state["cpu.k"] or 0) * 0x10000 +
        (state["cpu.pc"] or 0)
    local key = string.format(
        "%s:%06X:%04X:%02X:%04d",
        operation,
        pc,
        address,
        value or 0,
        frame
    )
    inputAccesses[key] = (inputAccesses[key] or 0) + 1
end

emu.addMemoryCallback(function(address, value)
    observeInputAccess("read", address, value)
end, emu.callbackType.read, 0x00B3, 0x00CD,
    emu.cpuType.snes, emu.memType.snesWorkRam)
emu.addMemoryCallback(function(address, value)
    observeInputAccess("write", address, value)
end, emu.callbackType.write, 0x00B3, 0x00CD,
    emu.cpuType.snes, emu.memType.snesWorkRam)

local function observeAttackState(operation, address, value)
    if frame < 4700 then
        return
    end
    local state = emu.getState()
    local pc = (state["cpu.k"] or 0) * 0x10000 +
        (state["cpu.pc"] or 0)
    local key = string.format(
        "%04d:%s:%06X:%04X:%02X",
        frame,
        operation,
        pc,
        address,
        value or 0
    )
    attackStateAccesses[key] = (attackStateAccesses[key] or 0) + 1
end

emu.addMemoryCallback(function(address, value)
    observeAttackState("read", address, value)
end, emu.callbackType.read, 0x66E0, 0x66F4,
    emu.cpuType.snes, emu.memType.snesWorkRam)
emu.addMemoryCallback(function(address, value)
    observeAttackState("write", address, value)
end, emu.callbackType.write, 0x66E0, 0x66F4,
    emu.cpuType.snes, emu.memType.snesWorkRam)
for _, addressRange in ipairs({
    { 0x0430, 0x047F },
    { 0xC9C0, 0xC9FF },
    { 0xD1D0, 0xD1E0 },
}) do
    emu.addMemoryCallback(function(address, value)
        observeAttackState("queue-read", address, value)
    end, emu.callbackType.read, addressRange[1], addressRange[2],
        emu.cpuType.snes, emu.memType.snesWorkRam)
    emu.addMemoryCallback(function(address, value)
        observeAttackState("queue-write", address, value)
    end, emu.callbackType.write, addressRange[1], addressRange[2],
        emu.cpuType.snes, emu.memType.snesWorkRam)
end

emu.addMemoryCallback(function()
    if frame < 4700 then
        return
    end
    local state = emu.getState()
    local stackPointer = state["cpu.sp"] or state["cpu.s"] or 0
    local stackBytes = {}
    for offset = 1, 8 do
        table.insert(stackBytes, string.format(
            "%02X",
            emu.read(
                (stackPointer + offset) & 0xFFFF,
                emu.memType.snesMemoryDebug
            )
        ))
    end
    table.insert(constructorEvents, string.format(
        "frame=%d x=$%04X y=$%04X sp=$%04X stack=%s",
        frame,
        state["cpu.x"] or 0,
        state["cpu.y"] or 0,
        stackPointer,
        table.concat(stackBytes, " ")
    ))
end, emu.callbackType.exec, 0x80C69A)

for _, addressRange in ipairs({
    { 0x0E7C, 0x0F7B },
    { 0x107C, 0x117B },
    { 0x127C, 0x137B },
    { 0x147C, 0x157B },
}) do
    emu.addMemoryCallback(function(address, value)
        if frame < 4700 then
            return
        end
        local state = emu.getState()
        local pc = (state["cpu.k"] or 0) * 0x10000 +
            (state["cpu.pc"] or 0)
        local key = string.format(
            "%04d:%06X:%04X:%02X",
            frame,
            pc,
            address,
            value or 0
        )
        garbagePlaneWrites[key] = (garbagePlaneWrites[key] or 0) + 1
    end, emu.callbackType.write, addressRange[1], addressRange[2],
        emu.cpuType.snes, emu.memType.snesWorkRam)
end

local function dumpWram(name)
    local output = assert(io.open(outputFolder .. "/" .. name, "wb"))
    for address = 0, 0x1FFFF do
        output:write(string.char(emu.read(address, emu.memType.snesWorkRam)))
    end
    output:close()
end

local function writeEvents()
    local output = assert(io.open(outputFolder .. "/writes.txt", "w"))
    local keys = {}
    for key in pairs(events) do
        table.insert(keys, key)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        output:write(string.format(
            "address=$%05X count=%d\n",
            key,
            events[key]
        ))
    end
    output:close()

    output = assert(io.open(outputFolder .. "/queue-writes.txt", "w"))
    keys = {}
    for key in pairs(detailedEvents) do
        table.insert(keys, key)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local pc, address, value, x, y = key:match(
            "^(%x+):(%x+):(%x+):(%x+):(%x+)$"
        )
        output:write(string.format(
            "pc=$%s address=$%s value=$%s x=$%s y=$%s count=%d\n",
            pc,
            address,
            value,
            x,
            y,
            detailedEvents[key]
        ))
    end
    output:close()

    output = assert(io.open(outputFolder .. "/garbage-plane-writes.txt", "w"))
    keys = {}
    for key in pairs(garbagePlaneWrites) do
        table.insert(keys, key)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        output:write(key .. string.format(":%d\n", garbagePlaneWrites[key]))
    end
    output:close()

    output = assert(io.open(outputFolder .. "/constructors.txt", "w"))
    for _, event in ipairs(constructorEvents) do
        output:write(event .. "\n")
    end
    output:close()

    output = assert(io.open(outputFolder .. "/attack-state.txt", "w"))
    keys = {}
    for key in pairs(attackStateAccesses) do
        table.insert(keys, key)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        output:write(key .. string.format(":%d\n", attackStateAccesses[key]))
    end
    output:close()

    output = assert(io.open(outputFolder .. "/input-accesses.txt", "w"))
    keys = {}
    for key in pairs(inputAccesses) do
        table.insert(keys, key)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        output:write(key .. string.format(":%d\n", inputAccesses[key]))
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
    elseif triggerAttack and frame >= 4720 and frame <= 4722 then
        syntheticInput1 = 0x0080
    end
end

for _, address in ipairs({
    0x80AE2F,
    0x8295D1,
    0x829616,
    0x829D93,
    0x82A417,
    0x82A41E,
    0x82A74A,
    0x82A751,
    0x82B2EE,
    0x82B34A,
    0x82F45E,
    0x82F516,
    0x838672,
    0x83885F,
    0x83CB91,
    0x83CCDE,
    0x83CCF6,
    0x83CD0A,
    0x83D8BA,
    0x83D91E,
    0x83DAA2,
    0x83DAB6,
    0x83DB8D,
    0x83DE64,
    0x83DEBB,
    0x83E2D5,
    0x83E53A,
    0x83E5F3,
    0x83E727,
    0x83E7AA,
    0x83ED99,
    0x83EFB5,
    0x83F713,
    0x83F94B,
    0x83F965,
    0x838808,
    0x838847,
    0x839E01,
    0x83C12F,
    0x83CF3C,
    0x83CF79,
    0x83D047,
    0x83D242,
    0x83D3BA,
    0x83D4D1,
    0x83D5A2,
    0x83F709,
    0x89E29B,
    0x8BB56F,
}) do
    emu.addMemoryCallback(function(executedAddress)
        inputSites[executedAddress] = (inputSites[executedAddress] or 0) + 1
    end, emu.callbackType.exec, address)
end

local function readWord(address)
    return emu.read16(address, emu.memType.snesWorkRam)
end

local function writeWord(address, value)
    emu.write(address, value & 0xFF, emu.memType.snesWorkRam)
    emu.write(address + 1, (value >> 8) & 0xFF, emu.memType.snesWorkRam)
end

emu.addMemoryCallback(function()
    local playerIndex = readWord(0x0360)
    local column = readWord(0x03A4 + playerIndex)
    local row = readWord(0x03A8 + playerIndex)
    local leftOffset = readWord(0x0362) + row * 0x10 + column * 2
    print(string.format(
        "swap-attempt frame=%d player=%d cursor=%d,%d base=$%04X cells=$%04X,$%04X",
        frame,
        playerIndex,
        column,
        row,
        readWord(0x0362),
        0x0F7C + leftOffset,
        0x0F7E + leftOffset
    ))
end, emu.callbackType.exec, 0x82B2EE)

emu.addMemoryCallback(function()
    print(string.format("swap-accepted frame=%d", frame))
end, emu.callbackType.exec, 0x82B34A)

local function performNativeSwap()
    local leftOffset = 0x00C8
    local rightOffset = 0x00CA
    for _, planeBase in ipairs({ 0x0D7C, 0x0F7C }) do
        local left = readWord(planeBase + leftOffset)
        local right = readWord(planeBase + rightOffset)
        if planeBase == 0x0F7C then
            left = left & 0x7CFF
            right = right & 0x7CFF
        end
        writeWord(planeBase + leftOffset, right)
        writeWord(planeBase + rightOffset, left)
    end
    if readWord(0x0F7C + leftOffset) ~= 0 then
        writeWord(
            0x0F7C + leftOffset,
            readWord(0x0F7C + leftOffset) | 0x0100
        )
    end
    if readWord(0x0F7C + rightOffset) ~= 0 then
        writeWord(
            0x0F7C + rightOffset,
            readWord(0x0F7C + rightOffset) | 0x0100
        )
    end
    for _, planeBase in ipairs({ 0x117C, 0x137C }) do
        writeWord(planeBase + leftOffset, 0)
        writeWord(planeBase + rightOffset, 0)
    end
    writeWord(0x04C6, readWord(0x03A4))
    writeWord(0x04CA, readWord(0x03A8))
end

emu.addEventCallback(function()
    frame = frame + 1
    setInput()

    if frame == 4700 then
        if triggerAttack then
            for _, seed in ipairs({
                { 0x0FF2, 1 }, -- row 7, column 3
                { 0x1002, 1 }, -- row 8, column 3
                { 0x1012, 2 }, -- row 9, column 3: swap target
                { 0x1014, 1 }, -- row 9, column 4: source
                { 0x1022, 1 }, -- row 10, column 3
            }) do
                writeWord(seed[1] - 0x0200, 0)
                writeWord(seed[1], seed[2])
                writeWord(seed[1] + 0x0200, 0)
                writeWord(seed[1] + 0x0400, 0)
            end
        end
    elseif frame == 4708 then
        print(string.format(
            "before-swap cursor=%d,%d colors=%d,%d,%d,%d,%d",
            emu.read16(0x03A4, emu.memType.snesWorkRam),
            emu.read16(0x03A8, emu.memType.snesWorkRam),
            emu.read16(0x0FF2, emu.memType.snesWorkRam),
            emu.read16(0x1002, emu.memType.snesWorkRam),
            emu.read16(0x1012, emu.memType.snesWorkRam),
            emu.read16(0x1014, emu.memType.snesWorkRam),
            emu.read16(0x1022, emu.memType.snesWorkRam)
        ))
        dumpWram("before.bin")
        tracing = true
    elseif frame >= 4730 and frame <= 4830 and frame % 10 == 0 then
        print(string.format(
            "swap-state frame=%d cells=%04X,%04X,%04X,%04X,%04X cursor-state=%04X,%04X",
            frame,
            readWord(0x0FF2),
            readWord(0x1002),
            readWord(0x1012),
            readWord(0x1014),
            readWord(0x1022),
            readWord(0x04C6),
            readWord(0x04CA)
        ))
    elseif frame == 4724 then
        print(string.format(
            "after-swap cursor=%d,%d current=$%04X pressed=$%04X colors=%d,%d",
            emu.read16(0x03A4, emu.memType.snesWorkRam),
            emu.read16(0x03A8, emu.memType.snesWorkRam),
            emu.read16(0x00B3, emu.memType.snesWorkRam),
            emu.read16(0x00B7, emu.memType.snesWorkRam),
            emu.read16(0x1012, emu.memType.snesWorkRam),
            emu.read16(0x1014, emu.memType.snesWorkRam)
        ))
        for address, count in pairs(inputSites) do
            print(string.format("input-site=$%06X count=%d", address, count))
        end
    elseif frame == 5200 then
        tracing = false
        dumpWram("after.bin")
        writeEvents()
        for address, count in pairs(inputSites) do
            print(string.format("final-site=$%06X count=%d", address, count))
        end
        local screenshot = assert(io.open(outputFolder .. "/after.png", "wb"))
        screenshot:write(emu.takeScreenshot())
        screenshot:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)