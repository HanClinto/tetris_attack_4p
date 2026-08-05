local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local events = {}
local tracing = false
local initStartFrame = 4000
local initEndFrame = 4400
local activeStartFrame = 4700
local activeEndFrame = 4780

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

local function normalizeAddress(address)
    if address <= 0x1FFFF then
        return address
    end
    return address & 0xFFFF
end

local function observe(operation, address)
    if not tracing then
        return
    end

    local state = emu.getState()
    local pc = (state["cpu.k"] or 0) * 0x10000 + (state["cpu.pc"] or 0)
    local dbr = state["cpu.dbr"] or 0
    local x = state["cpu.x"] or 0
    local y = state["cpu.y"] or 0
    local sp = state["cpu.sp"] or state["cpu.s"] or 0
    local stackBytes = {}
    for offset = 1, 8 do
        stackBytes[offset] = emu.read(
            (sp + offset) & 0xFFFF,
            emu.memType.snesMemoryDebug
        )
    end
    local normalized = normalizeAddress(address)
    local stack = table.concat(stackBytes, ",")
    local key = string.format(
        "%s:%06X:%02X:%04X:%04X:%04X:%s",
        operation,
        pc,
        dbr,
        x,
        y,
        sp,
        stack
    )
    local event = events[key]
    if event == nil then
        event = {
            operation = operation,
            pc = pc,
            dbr = dbr,
            x = x,
            y = y,
            sp = sp,
            stack = stackBytes,
            count = 0,
            minimum = normalized,
            maximum = normalized,
        }
        events[key] = event
    end
    event.count = event.count + 1
    event.minimum = math.min(event.minimum, normalized)
    event.maximum = math.max(event.maximum, normalized)
end

local function writeEvents(path)
    local output = assert(io.open(outputFolder .. "/" .. path, "w"))
    local keys = {}
    for key in pairs(events) do
        table.insert(keys, key)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local event = events[key]
        output:write(string.format(
            "%s pc=$%06X dbr=$%02X x=$%04X y=$%04X sp=$%04X " ..
            "stack=%s count=%d range=$%04X-$%04X\n",
            event.operation,
            event.pc,
            event.dbr,
            event.x,
            event.y,
            event.sp,
            table.concat(event.stack, ","),
            event.count,
            event.minimum,
            event.maximum
        ))
    end
    output:close()
end

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == initStartFrame then
        tracing = true
        emu.addMemoryCallback(
            function(address) observe("read", address) end,
            emu.callbackType.read,
            0x0D7C,
            0x1169,
            emu.cpuType.snes,
            emu.memType.snesWorkRam
        )
        emu.addMemoryCallback(
            function(address) observe("write", address) end,
            emu.callbackType.write,
            0x0D7C,
            0x1169,
            emu.cpuType.snes,
            emu.memType.snesWorkRam
        )
    elseif frame == initEndFrame then
        tracing = false
        writeEvents("grid-events-init.txt")
    elseif frame == activeStartFrame then
        events = {}
        tracing = true
    elseif frame == activeEndFrame then
        tracing = false
        writeEvents("grid-events-active.txt")
        emu.stop(0)
    end
end, emu.eventType.startFrame)
