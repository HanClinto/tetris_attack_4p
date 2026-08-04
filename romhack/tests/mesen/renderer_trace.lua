local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local trace = assert(io.open(outputFolder .. "/ppu-trace.txt", "w"))
local frameVramWrites = 0
local totalVramWrites = 0
local dumpedStateKeys = false
local seenConfigEvents = {}

local function writeStateKeys(state)
    if dumpedStateKeys then
        return
    end
    dumpedStateKeys = true

    local keys = {}
    for key, value in pairs(state) do
        if type(value) ~= "table" then
            table.insert(keys, key .. "=" .. tostring(value))
        end
    end
    table.sort(keys)
    trace:write("STATE_KEYS\n", table.concat(keys, "\n"), "\nEND_STATE_KEYS\n")
end

local function observeConfigWrite(address, value)
    local state = emu.getState()
    writeStateKeys(state)
    local cpuAddress = (state["cpu.k"] or 0) * 0x10000 +
        (state["cpu.pc"] or 0)
    local eventKey = string.format("%06X:%06X:%02X", cpuAddress, address, value)
    if seenConfigEvents[eventKey] then
        return
    end
    seenConfigEvents[eventKey] = true
    trace:write(string.format(
        "frame=%d cpu=$%06X address=$%06X value=$%02X\n",
        state.frameCount or 0,
        cpuAddress,
        address,
        value
    ))
end

local function observeVramWrite()
    frameVramWrites = frameVramWrites + 1
    totalVramWrites = totalVramWrites + 1
end

local configRegisters = {
    0x2105,
    0x2107,
    0x2108,
    0x2109,
    0x210A,
    0x2115,
    0x2116,
    0x2117,
}

for _, bank in ipairs({ 0x000000, 0x800000 }) do
    for _, register in ipairs(configRegisters) do
        emu.addMemoryCallback(
            observeConfigWrite,
            emu.callbackType.write,
            bank + register
        )
    end
    emu.addMemoryCallback(
        observeVramWrite,
        emu.callbackType.write,
        bank + 0x2118,
        bank + 0x2119
    )
end

local frame = 0
emu.addEventCallback(function()
    frame = frame + 1

    if frameVramWrites > 0 then
        trace:write(string.format(
            "frame=%d vramWrites=%d\n",
            frame,
            frameVramWrites
        ))
        frameVramWrites = 0
    end

    if frame == 1200 or frame == 2400 or frame == 3600 or
        frame == 4800 or frame == 6000 then
        local screenshot = assert(io.open(
            outputFolder .. string.format("/frame-%04d.png", frame),
            "wb"
        ))
        screenshot:write(emu.takeScreenshot())
        screenshot:close()
    end

    if frame >= 6000 then
        trace:write(string.format("totalVramWrites=%d\n", totalVramWrites))
        trace:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)
