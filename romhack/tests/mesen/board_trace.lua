local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local trace = assert(io.open(outputFolder .. "/board-trace.txt", "w"))
local seenWrites = {}

local function cpuAddress(state)
    return (state["cpu.k"] or 0) * 0x10000 + (state["cpu.pc"] or 0)
end

local modeSetupCandidates = {
    0x86E0B8,
    0x87828D,
    0x89E444,
    0x8A8541,
}

for _, address in ipairs(modeSetupCandidates) do
    emu.addMemoryCallback(function(executedAddress)
        local state = emu.getState()
        trace:write(string.format(
            "modeSetup frame=%d cpu=$%06X candidate=$%06X\n",
            state.frameCount or 0,
            cpuAddress(state),
            executedAddress
        ))
    end, emu.callbackType.exec, address)
end

local function observeShadowWrite(address, value)
    local state = emu.getState()
    local eventKey = string.format("%06X:%06X:%02X", cpuAddress(state), address, value)
    if seenWrites[eventKey] then
        return
    end
    seenWrites[eventKey] = true
    trace:write(string.format(
        "shadow frame=%d cpu=$%06X address=$%06X value=$%02X\n",
        state.frameCount or 0,
        cpuAddress(state),
        address,
        value
    ))
end

emu.addMemoryCallback(
    observeShadowWrite,
    emu.callbackType.write,
    0x0001B7,
    0x0001E1,
    emu.cpuType.snes,
    emu.memType.snesWorkRam
)

local function snapshot(frame)
    local state = emu.getState()
    trace:write(string.format(
        "snapshot frame=%d cpu=$%06X mode=$%02X " ..
        "bg1map=$%04X bg2map=$%04X bg3map=$%04X " ..
        "bg1chr=$%04X bg2chr=$%04X bg3chr=$%04X " ..
        "bg1scroll=%d,%d bg2scroll=%d,%d bg3scroll=%d,%d\n",
        frame,
        cpuAddress(state),
        state["ppu.bgMode"] or 0,
        state["ppu.layers[0].tilemapAddress"] or 0,
        state["ppu.layers[1].tilemapAddress"] or 0,
        state["ppu.layers[2].tilemapAddress"] or 0,
        state["ppu.layers[0].chrAddress"] or 0,
        state["ppu.layers[1].chrAddress"] or 0,
        state["ppu.layers[2].chrAddress"] or 0,
        state["ppu.layers[0].hscroll"] or 0,
        state["ppu.layers[0].vscroll"] or 0,
        state["ppu.layers[1].hscroll"] or 0,
        state["ppu.layers[1].vscroll"] or 0,
        state["ppu.layers[2].hscroll"] or 0,
        state["ppu.layers[2].vscroll"] or 0
    ))

    trace:write("shadowBytes")
    for address = 0x01B7, 0x01E1 do
        trace:write(string.format(
            " %04X=%02X",
            address,
            emu.read(address, emu.memType.snesMemoryDebug)
        ))
    end
    trace:write("\n")

    local screenshot = assert(io.open(
        outputFolder .. string.format("/frame-%04d.png", frame),
        "wb"
    ))
    screenshot:write(emu.takeScreenshot())
    screenshot:close()
end

local frame = 0
emu.addEventCallback(function()
    frame = frame + 1
    if frame == 2200 or frame == 2280 then
        snapshot(frame)
    end

    if frame >= 2400 then
        trace:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)
