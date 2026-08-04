local accesses = 0
local frames = 0
local firstRead = nil
local firstWrite = nil
local scratchStart = 0x1FE00
local traceStartFrame = 120
local traceEndFrame = traceStartFrame + 3600

local function observeRead(address)
    if frames < traceStartFrame then
        return
    end
    accesses = accesses + 1
    firstRead = firstRead or address
    emu.stop(address - scratchStart + 1)
end

local function observeWrite(address)
    if frames < traceStartFrame then
        return
    end
    accesses = accesses + 1
    firstWrite = firstWrite or address
    emu.stop(address - scratchStart + 65)
end

emu.addMemoryCallback(
    observeRead,
    emu.callbackType.read,
    0x1FE00,
    0x1FE2F,
    emu.cpuType.snes,
    emu.memType.snesWorkRam
)

emu.addMemoryCallback(
    observeWrite,
    emu.callbackType.write,
    0x1FE00,
    0x1FE2F,
    emu.cpuType.snes,
    emu.memType.snesWorkRam
)

emu.addEventCallback(function()
    frames = frames + 1
    if frames >= traceEndFrame then
        emu.log(string.format(
            "TA4P_WRAM accesses=%d firstRead=%s firstWrite=%s",
            accesses,
            firstRead and string.format("$%05X", firstRead) or "none",
            firstWrite and string.format("$%05X", firstWrite) or "none"
        ))
        emu.stop(accesses == 0 and 0 or 1)
    end
end, emu.eventType.startFrame)
