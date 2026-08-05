local nativeBefore = nil
local entered = false
local loadCalls = {}

local planeBases = { 0x0D7C, 0x0F7C, 0x117C, 0x137C }

local function captureNative()
    local bytes = {}
    for _, planeBase in ipairs(planeBases) do
        for playerOffset = 0, 0x100, 0x100 do
            for offset = 0, 0xFF do
                table.insert(bytes, emu.read(
                    planeBase + playerOffset + offset,
                    emu.memType.snesWorkRam
                ))
            end
        end
    end
    return bytes
end

local function verifyNative(expected)
    local actual = captureNative()
    if #actual ~= #expected then
        return false, 0
    end
    for index = 1, #actual do
        if actual[index] ~= expected[index] then
            local outputFolder = emu.getScriptDataFolder()
            if outputFolder ~= "" then
                local output = assert(io.open(outputFolder .. "/mismatch.txt", "w"))
                output:write(string.format(
                    "index=%d expected=$%02X actual=$%02X backing=$%02X loads=%s\n",
                    index,
                    expected[index],
                    actual[index],
                    emu.read(0x10000 + ((index - 1) & 0xFF), emu.memType.snesWorkRam),
                    table.concat(loadCalls, ",")
                ))
                output:close()
            end
            return false, ((index - 1) >> 8) + 1, ((index - 1) & 0xFF)
        end
    end
    return true, 0, 0
end

local function verifyBacking(startAddress, expectedByte)
    for address = startAddress, startAddress + 0x3FF do
        if emu.read(address, emu.memType.snesWorkRam) ~= expectedByte then
            return false
        end
    end
    return true
end

local function verifyNativeBacking(playerOffset, backingAddress)
    for planeIndex, planeBase in ipairs(planeBases) do
        local planeBacking = backingAddress + (planeIndex - 1) * 0x100
        for offset = 0, 0xFF do
            local native = emu.read(
                planeBase + playerOffset + offset,
                emu.memType.snesWorkRam
            )
            local backing = emu.read(
                planeBacking + offset,
                emu.memType.snesWorkRam
            )
            if native ~= backing then
                return false
            end
        end
    end
    return true
end

emu.addMemoryCallback(function()
    if not entered and
        emu.read(0x01BA, emu.memType.snesWorkRam) == 0x02 then
        entered = true
        nativeBefore = captureNative()
    end
end, emu.callbackType.exec, 0xA08700)

emu.addMemoryCallback(function()
    local state = emu.getState()
    table.insert(loadCalls, string.format(
        "X%04X:Y%04X",
        state["cpu.x"] or 0,
        state["cpu.y"] or 0
    ))
end, emu.callbackType.exec, 0xA087C1)

emu.addMemoryCallback(function()
    if not entered then
        return
    end

    local nativeMatches, nativeSlice, nativeOffset = verifyNative(nativeBefore)
    if not nativeMatches then
        emu.stop(60 + nativeOffset)
    elseif not verifyNativeBacking(0x0000, 0x10000) then
        emu.stop(3)
    elseif not verifyNativeBacking(0x0100, 0x10400) then
        emu.stop(4)
    elseif not verifyBacking(0x10800, 0x33) then
        emu.stop(5)
    elseif not verifyBacking(0x10C00, 0x44) then
        emu.stop(6)
    else
        emu.stop(0)
    end
end, emu.callbackType.exec, 0xA08014)
