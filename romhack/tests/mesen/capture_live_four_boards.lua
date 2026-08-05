local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local captureReady = false
local completedHooks = 0

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
    end
end

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == 4700 then
        emu.write(0x12000, 0xA5, emu.memType.snesWorkRam)
    elseif frame == 4720 then
        captureReady = true
    end
end, emu.eventType.startFrame)

emu.addMemoryCallback(function()
    if not captureReady then
        return
    end

    completedHooks = completedHooks + 1
    if completedHooks < 8 then
        return
    end

    local screenshot = assert(io.open(
        outputFolder .. "/live-four-boards.png",
        "wb"
    ))
    screenshot:write(emu.takeScreenshot())
    screenshot:close()
    emu.stop(0)
end, emu.callbackType.exec, 0xA08408)