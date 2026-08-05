local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local armed = false
local pending = {}
local dispatcherEntries = { [3] = 0, [4] = 0 }
local completionCounts = { [3] = 0, [4] = 0 }
local nativeEntries = { [1] = 0, [2] = 0 }
local virtualBefore = {}
local virtualAfter = {}
local virtualScalarAfter = {}
local expectedVirtualInput = {}

local planeBases = { 0x0D7C, 0x0F7C, 0x117C, 0x137C }
local configs = {
    [3] = {
        slot = 1,
        returnAddress = 0x9DA8,
        toggle = 0x12004,
        preHook = 0xA08B00,
        postHook = 0xA08B80,
        completion = 0xA08BF0,
        planeBacking = 0x10800,
        nativePlaneBacking = 0x10000,
        scalarBacking = 0x10C00,
        nativeScalarBacking = 0x10D80,
        inputBacking = 0x10D50,
        virtualInput = { 0x1FE10, 0x1FE1A, 0x1FE1C, 0x1FE16, 0x1FE18 },
        scalarAddresses = {
            0x03EE, 0x0400, 0x0424, 0x0428, 0x042C,
            0x0440, 0x0444, 0x0448, 0x044C, 0x0450,
            0x0454, 0x0458, 0x045C, 0x046C, 0x0470,
            0x04BE, 0x04E8, 0x04F4, 0x04F8,
            0x03A4, 0x03A8, 0x03AC, 0x03B0,
        },
        inputAddresses = { 0x00B3, 0x00B7, 0x00BB, 0x00BF, 0x00C5 },
    },
    [4] = {
        slot = 2,
        returnAddress = 0x9E5E,
        toggle = 0x1200A,
        preHook = 0xA08C00,
        postHook = 0xA08C80,
        completion = 0xA08CF0,
        planeBacking = 0x11000,
        nativePlaneBacking = 0x10400,
        scalarBacking = 0x11400,
        nativeScalarBacking = 0x10D00,
        inputBacking = 0x10D40,
        virtualInput = { 0x1FE20, 0x1FE2A, 0x1FE2C, 0x1FE26, 0x1FE28 },
        scalarAddresses = {
            0x03F0, 0x0402, 0x0426, 0x042A, 0x042E,
            0x0442, 0x0446, 0x044A, 0x044E, 0x0452,
            0x0456, 0x045A, 0x045E, 0x046E, 0x0472,
            0x04C0, 0x04EA, 0x04F6, 0x04FA,
            0x03A6, 0x03AA, 0x03AE, 0x03B2,
        },
        inputAddresses = { 0x00B5, 0x00B9, 0x00BD, 0x00C7, 0x00CD },
    },
}

for offset = 0, 10 do
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

local function captureNativeSlot(slot)
    local bytes = {}
    local playerOffset = (slot - 1) * 0x100
    for _, planeBase in ipairs(planeBases) do
        for offset = 0, 0xFF do
            table.insert(bytes, emu.read(
                planeBase + playerOffset + offset,
                emu.memType.snesWorkRam
            ))
        end
    end
    return bytes
end

local function readWord(address)
    return emu.read16(address, emu.memType.snesWorkRam)
end

local function captureBytes(startAddress, length)
    local bytes = {}
    for offset = 0, length - 1 do
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

local function prepareVirtual(player)
    if not armed or emu.read(0x12000, emu.memType.snesWorkRam) ~= 0xA5 then
        return
    end
    local config = configs[player]
    for index, address in ipairs(config.virtualInput) do
        writeWord(address, index <= 3 and 0x0080 or (index == 5 and 0x0010 or 0))
    end
    local nextToggle = emu.read(config.toggle, emu.memType.snesWorkRam) ~ 1
    if nextToggle == 0 then
        pending[player] = nil
        return
    end
    pending[player] = {
        native = captureNativeSlot(config.slot),
        scalar = captureWords(config.scalarAddresses),
        input = captureWords(config.inputAddresses),
    }
    expectedVirtualInput[player] = captureWords(config.virtualInput)
end

for player, config in pairs(configs) do
    emu.addMemoryCallback(function()
        prepareVirtual(player)
    end, emu.callbackType.exec, config.preHook)

    emu.addMemoryCallback(function()
        if armed and emu.read(0x12001, emu.memType.snesWorkRam) == player then
            virtualAfter[player] = captureNativeSlot(config.slot)
            virtualScalarAfter[player] = captureWords(config.scalarAddresses)
        end
    end, emu.callbackType.exec, config.postHook)

    emu.addMemoryCallback(function()
        if not armed or emu.read(0x12005, emu.memType.snesWorkRam) ~= player then
            return
        end
        local before = pending[player]
        if before == nil then
            emu.stop(20 + player)
        elseif dispatcherEntries[player] ~= completionCounts[player] + 1 then
            emu.stop(3)
        elseif not verifyBytes(before.native, captureNativeSlot(config.slot)) then
            emu.stop(4)
        elseif not verifyBytes(before.native, captureBytes(config.nativePlaneBacking, 0x400)) then
            emu.stop(5)
        elseif not verifyBytes(virtualAfter[player], captureBytes(config.planeBacking, 0x400)) then
            emu.stop(6)
        elseif not verifyBytes(before.scalar, captureWords(config.scalarAddresses)) then
            emu.stop(10)
        elseif not verifyBytes(before.scalar, captureBytes(config.nativeScalarBacking, #config.scalarAddresses * 2)) then
            emu.stop(11)
        elseif not verifyBytes(virtualScalarAfter[player], captureBytes(config.scalarBacking, #config.scalarAddresses * 2)) then
            emu.stop(12)
        elseif not verifyBytes(before.input, captureWords(config.inputAddresses)) then
            emu.stop(13)
        end
        completionCounts[player] = completionCounts[player] + 1
        pending[player] = nil
        if completionCounts[3] >= 2 and completionCounts[4] >= 2 and
            nativeEntries[1] >= 1 and nativeEntries[2] >= 1 then
            emu.stop(0)
        end
    end, emu.callbackType.exec, config.completion)
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
    local activePlayer = emu.read(0x12001, emu.memType.snesWorkRam)
    for player, config in pairs(configs) do
        if returnAddress == config.returnAddress then
            if activePlayer == 0 then
                nativeEntries[config.slot] = nativeEntries[config.slot] + 1
                return
            elseif activePlayer ~= player or pending[player] == nil then
                emu.stop(15)
                return
            end
            dispatcherEntries[player] = dispatcherEntries[player] + 1
            if not verifyBytes(captureNativeSlot(config.slot), captureBytes(config.planeBacking, 0x400)) then
                emu.stop(2)
            elseif not verifyBytes(captureWords(config.scalarAddresses), captureBytes(config.scalarBacking, #config.scalarAddresses * 2)) then
                emu.stop(8)
            elseif not verifyBytes(
                captureWords(config.inputAddresses),
                expectedVirtualInput[player]
            ) then
                emu.stop(9)
            elseif readWord(config.virtualInput[2]) ~= 0 or
                readWord(config.virtualInput[3]) ~= 0 then
                emu.stop(17)
            end
            virtualBefore[player] = captureNativeSlot(config.slot)
            return
        end
    end
end, emu.callbackType.exec, 0x82A9C8)

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()
    if frame == 4700 then
        for offset = 0, 10 do
            emu.write(0x12000 + offset, 0, emu.memType.snesWorkRam)
        end
        armed = true
        emu.write(0x12000, 0xA5, emu.memType.snesWorkRam)
    elseif frame >= 4780 then
        print(string.format(
            "balanced timeout p3=%d/%d p4=%d/%d native=%d/%d",
            dispatcherEntries[3], completionCounts[3],
            dispatcherEntries[4], completionCounts[4],
            nativeEntries[1], nativeEntries[2]
        ))
        emu.stop(7)
    end
end, emu.eventType.startFrame)