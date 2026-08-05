local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local events = {}
local accesses = {}
local activePlayerIndex = nil
local traceStartFrame = 4700
local traceEndFrame = 4710

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
    return emu.read(address, emu.memType.snesWorkRam) |
        (emu.read(address + 1, emu.memType.snesWorkRam) << 8)
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

local function observeAccess(operation, address)
    if activePlayerIndex == nil then
        return
    end

    local normalized = normalizeWramAddress(address)
    if normalized == nil then
        return
    end

    local state = emu.getState()
    local pc = (state["cpu.k"] or 0) * 0x10000 + (state["cpu.pc"] or 0)
    local key = string.format(
        "%s:%06X:%05X:%04X",
        operation,
        pc,
        normalized,
        activePlayerIndex
    )
    accesses[key] = (accesses[key] or 0) + 1
end

emu.addMemoryCallback(
    function(address) observeAccess("read", address) end,
    emu.callbackType.read,
    0,
    0x1FFFF,
    emu.cpuType.snes,
    emu.memType.snesWorkRam
)
emu.addMemoryCallback(
    function(address) observeAccess("write", address) end,
    emu.callbackType.write,
    0,
    0x1FFFF,
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
    elseif frame >= 4710 and frame <= 4712 then
        syntheticInput1 = 0x0100
    elseif frame >= 4720 and frame <= 4722 then
        syntheticInput1 = 0x0080
    elseif frame >= 4740 and frame <= 4742 then
        syntheticInput2 = 0x0200
    elseif frame >= 4750 and frame <= 4752 then
        syntheticInput2 = 0x0080
    end
end

emu.addMemoryCallback(function()
    if frame < traceStartFrame then
        return
    end

    local state = emu.getState()
    local sp = state["cpu.sp"] or state["cpu.s"] or 0
    local returnLow = emu.read((sp + 1) & 0xFFFF, emu.memType.snesMemoryDebug)
    local returnHigh = emu.read((sp + 2) & 0xFFFF, emu.memType.snesMemoryDebug)
    local returnAddress = returnLow | (returnHigh << 8)
    local playerIndex = readWord(0x0360)
    activePlayerIndex = playerIndex
    local key = string.format("%04X:%04X", returnAddress, playerIndex)
    events[key] = (events[key] or 0) + 1
end, emu.callbackType.exec, 0x82A9C8)

emu.addMemoryCallback(function()
    activePlayerIndex = nil
end, emu.callbackType.exec, 0x82A9E8)

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == traceEndFrame then
        local output = assert(io.open(outputFolder .. "/dispatcher-events.txt", "w"))
        local keys = {}
        for key in pairs(events) do
            table.insert(keys, key)
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local returnAddress, playerIndex = key:match("^(%x+):(%x+)$")
            output:write(string.format(
                "return=$82:%s player_index=$%s count=%d\n",
                returnAddress,
                playerIndex,
                events[key]
            ))
        end
        output:close()

        output = assert(io.open(outputFolder .. "/dispatcher-accesses.txt", "w"))
        keys = {}
        for key in pairs(accesses) do
            table.insert(keys, key)
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local operation, pc, address, playerIndex = key:match(
                "^(%a+):(%x+):(%x+):(%x+)$"
            )
            output:write(string.format(
                "%s pc=$%s address=$%s player_index=$%s count=%d\n",
                operation,
                pc,
                address,
                playerIndex,
                accesses[key]
            ))
        end
        output:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)