local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local armed = false
local pendingPlayer = nil
local nativeBefore = nil
local scalarBefore = nil
local inputBefore = nil
local virtualBefore = {}
local virtualAfter = {}
local virtualScalarAfter = {}
local dispatcherEntries = { [3] = 0, [4] = 0 }
local completionCounts = { [3] = 0, [4] = 0 }
local boardChanged = { [3] = false, [4] = false }
local preHookEntries = 0
local postHookEntries = 0

local planeBases = { 0x0D7C, 0x0F7C, 0x117C, 0x137C }
local scalarAddresses = {
    0x03F0, 0x0402, 0x0426, 0x042A, 0x042E,
    0x0442, 0x0446, 0x044A, 0x044E, 0x0452,
    0x0456, 0x045A, 0x045E, 0x046E, 0x0472,
    0x04C0, 0x04EA, 0x04F6, 0x04FA,
}
local inputAddresses = { 0x00B5, 0x00B9, 0x00BD, 0x00C7, 0x00CD }
local p3InputAddresses = { 0x1FE10, 0x1FE12, 0x1FE14, 0x1FE16, 0x1FE18 }
local p4InputAddresses = { 0x1FE20, 0x1FE22, 0x1FE24, 0x1FE26, 0x1FE28 }
local planeBacking = { [3] = 0x10800, [4] = 0x11000 }
local scalarBacking = { [3] = 0x10C00, [4] = 0x11400 }
local inputBacking = { [3] = p3InputAddresses, [4] = p4InputAddresses }

for offset = 0, 9 do
    emu.write(0x12000 + offset, 0, emu.memType.snesWorkRam)
end

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

local function captureNativeP2()
    local bytes = {}
    for _, planeBase in ipairs(planeBases) do
        for offset = 0, 0xFF do
            table.insert(bytes, emu.read(
                planeBase + 0x0100 + offset,
                emu.memType.snesWorkRam
            ))
        end
    end
    return bytes
end

local function verifyBytes(expected, actual)
    if expected == nil or actual == nil or #expected ~= #actual then
        return false
    end
    for index = 1, #expected do
        if expected[index] ~= actual[index] then
            return false
        end
    end
    return true
end

local function captureBacking(startAddress)
    local bytes = {}
    for offset = 0, 0x3FF do
        bytes[offset + 1] = emu.read(
            startAddress + offset,
            emu.memType.snesWorkRam
        )
    end
    return bytes
end

local function captureWords(addresses)
    local bytes = {}
    for _, address in ipairs(addresses) do
        table.insert(bytes, emu.read(address, emu.memType.snesWorkRam))
        table.insert(bytes, emu.read(address + 1, emu.memType.snesWorkRam))
    end
    return bytes
end

local function captureBackingBytes(startAddress, length)
    local bytes = {}
    for offset = 0, length - 1 do
        bytes[offset + 1] = emu.read(
            startAddress + offset,
            emu.memType.snesWorkRam
        )
    end
    return bytes
end

local function writeWord(address, value)
    emu.write(address, value & 0xFF, emu.memType.snesWorkRam)
    emu.write(address + 1, (value >> 8) & 0xFF, emu.memType.snesWorkRam)
end

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

emu.addMemoryCallback(function()
    if not armed then
        return
    end

    local state = emu.getState()
    local sp = state["cpu.sp"] or state["cpu.s"] or 0
    local returnAddress =
        emu.read((sp + 1) & 0xFFFF, emu.memType.snesMemoryDebug) |
        (emu.read((sp + 2) & 0xFFFF, emu.memType.snesMemoryDebug) << 8)
    if returnAddress ~= 0x9E5E then
        return
    end

    local activePlayer = emu.read(0x12001, emu.memType.snesWorkRam)
    if activePlayer ~= 3 and activePlayer ~= 4 then
        return
    elseif activePlayer ~= pendingPlayer then
        emu.stop(15)
        return
    end

    dispatcherEntries[activePlayer] = dispatcherEntries[activePlayer] + 1
    if not verifyBytes(
        captureNativeP2(),
        captureBacking(planeBacking[activePlayer])
    ) then
        emu.stop(2)
    elseif not verifyBytes(
        captureWords(scalarAddresses),
        captureBackingBytes(
            scalarBacking[activePlayer],
            #scalarAddresses * 2
        )
    ) then
        emu.stop(8)
    elseif not verifyBytes(
        captureWords(inputAddresses),
        captureWords(inputBacking[activePlayer])
    ) then
        emu.stop(9)
    end
    virtualBefore[activePlayer] = captureNativeP2()
end, emu.callbackType.exec, 0x82A9C8)

emu.addMemoryCallback(function()
    preHookEntries = preHookEntries + 1
    if not armed or
        emu.read(0x12000, emu.memType.snesWorkRam) ~= 0xA5 then
        return
    end

    for _, inputBase in ipairs({ 0x1FE10, 0x1FE20 }) do
        writeWord(inputBase, 0x0080)
        writeWord(inputBase + 2, 0x0080)
        writeWord(inputBase + 4, 0x0080)
        writeWord(inputBase + 6, 0x0000)
        writeWord(inputBase + 8, 0x0010)
    end

    local nextPhase = (emu.read(0x12004, emu.memType.snesWorkRam) + 1) & 0x03
    if nextPhase == 1 then
        pendingPlayer = 3
    elseif nextPhase == 3 then
        pendingPlayer = 4
    else
        pendingPlayer = nil
        return
    end

    nativeBefore = captureNativeP2()
    scalarBefore = captureWords(scalarAddresses)
    inputBefore = captureWords(inputAddresses)
end, emu.callbackType.exec, 0xA08B00)

emu.addMemoryCallback(function()
    postHookEntries = postHookEntries + 1
    local activePlayer = emu.read(0x12001, emu.memType.snesWorkRam)
    if armed and (activePlayer == 3 or activePlayer == 4) then
        virtualAfter[activePlayer] = captureNativeP2()
        virtualScalarAfter[activePlayer] = captureWords(scalarAddresses)
    end
end, emu.callbackType.exec, 0xA08B80)

emu.addMemoryCallback(function()
    if not armed then
        return
    end

    local completedPlayer = emu.read(0x12005, emu.memType.snesWorkRam)
    if completedPlayer == 0 then
        return
    elseif completedPlayer ~= pendingPlayer then
        emu.stop(16)
    elseif dispatcherEntries[completedPlayer] ~=
        completionCounts[completedPlayer] + 1 then
        emu.stop(3)
    elseif not verifyBytes(nativeBefore, captureNativeP2()) then
        emu.stop(4)
    elseif not verifyBytes(nativeBefore, captureBacking(0x10000)) then
        emu.stop(5)
    elseif not verifyBytes(
        virtualAfter[completedPlayer],
        captureBacking(planeBacking[completedPlayer])
    ) then
        emu.stop(6)
    elseif not verifyBytes(scalarBefore, captureWords(scalarAddresses)) then
        emu.stop(10)
    elseif not verifyBytes(
        scalarBefore,
        captureBackingBytes(0x10D00, #scalarAddresses * 2)
    ) then
        emu.stop(11)
    elseif not verifyBytes(
        virtualScalarAfter[completedPlayer],
        captureBackingBytes(
            scalarBacking[completedPlayer],
            #scalarAddresses * 2
        )
    ) then
        emu.stop(12)
    elseif not verifyBytes(inputBefore, captureWords(inputAddresses)) then
        emu.stop(13)
    elseif verifyBytes(
        virtualBefore[completedPlayer],
        virtualAfter[completedPlayer]
    ) then
        emu.stop(14)
    end

    boardChanged[completedPlayer] = true
    completionCounts[completedPlayer] = completionCounts[completedPlayer] + 1
    pendingPlayer = nil
    if completionCounts[3] >= 2 and completionCounts[4] >= 2 and
        boardChanged[3] and boardChanged[4] then
        emu.stop(0)
    end
end, emu.callbackType.exec, 0xA08C00)

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == 4700 then
        for offset = 0, 9 do
            emu.write(0x12000 + offset, 0, emu.memType.snesWorkRam)
        end
        armed = true
        emu.write(0x12000, 0xA5, emu.memType.snesWorkRam)
    elseif frame >= 4780 then
        print(string.format(
            "timeout pre=%d post=%d p3=%d/%d p4=%d/%d phase=%d",
            preHookEntries,
            postHookEntries,
            dispatcherEntries[3],
            completionCounts[3],
            dispatcherEntries[4],
            completionCounts[4],
            emu.read(0x12004, emu.memType.snesWorkRam)
        ))
        emu.stop(7)
    end
end, emu.eventType.startFrame)