local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local startFrame = 3500
local endFrame = 3502
local frame = 0
local events = {}

local function cpuState()
    local state = emu.getState()
    return {
        address = (state["cpu.k"] or 0) * 0x10000 + (state["cpu.pc"] or 0),
        dbr = state["cpu.dbr"] or 0,
    }
end

local function normalizeAddress(address)
    if address <= 0x1FFFF then
        return address
    end
    return address & 0xFFFF
end

local function observe(operation, address)
    local normalized = normalizeAddress(address)
    local cpu = cpuState()
    local key = string.format("%s:%06X:%02X", operation, cpu.address, cpu.dbr)
    local event = events[key]
    if event == nil then
        event = {
            operation = operation,
            pc = cpu.address,
            dbr = cpu.dbr,
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

emu.addEventCallback(function()
    frame = frame + 1
    if frame == startFrame then
        emu.addMemoryCallback(
            function(address) observe("read", address) end,
            emu.callbackType.read,
            0x0D7C,
            0x1069,
            emu.cpuType.snes,
            emu.memType.snesWorkRam
        )
        emu.addMemoryCallback(
            function(address) observe("write", address) end,
            emu.callbackType.write,
            0x0D7C,
            0x1069,
            emu.cpuType.snes,
            emu.memType.snesWorkRam
        )
    elseif frame == endFrame then
        local output = assert(io.open(outputFolder .. "/grid-events.txt", "w"))
        local keys = {}
        for key in pairs(events) do
            table.insert(keys, key)
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local event = events[key]
            output:write(string.format(
                "%s pc=$%06X dbr=$%02X count=%d range=$%04X-$%04X\n",
                event.operation,
                event.pc,
                event.dbr,
                event.count,
                event.minimum,
                event.maximum
            ))
        end
        output:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)
