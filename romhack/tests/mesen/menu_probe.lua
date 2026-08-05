local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput = 0
local syntheticInput2 = 0

for _, bank in ipairs({ 0x000000, 0x800000 }) do
    emu.addMemoryCallback(function()
        return syntheticInput & 0xFF
    end, emu.callbackType.read, bank + 0x4218)

    emu.addMemoryCallback(function()
        return (syntheticInput >> 8) & 0xFF
    end, emu.callbackType.read, bank + 0x4219)

    emu.addMemoryCallback(function()
        return syntheticInput2 & 0xFF
    end, emu.callbackType.read, bank + 0x421A)

    emu.addMemoryCallback(function()
        return (syntheticInput2 >> 8) & 0xFF
    end, emu.callbackType.read, bank + 0x421B)
end

local function screenshot(name)
    local output = assert(io.open(outputFolder .. "/" .. name .. ".png", "wb"))
    output:write(emu.takeScreenshot())
    output:close()
end

emu.addEventCallback(function()
    frame = frame + 1
    if frame >= 1190 and frame <= 1195 then
        syntheticInput = 0x8000       -- B: leave title
    elseif frame >= 1450 and frame <= 1455 then
        syntheticInput = 0x0400       -- Down: select 2PLAYER GAME
    elseif frame >= 1500 and frame <= 1505 then
        syntheticInput = 0x0080       -- A: confirm
    elseif frame >= 2050 and frame <= 2055 then
        syntheticInput = 0x0400       -- Down: select VS.
    elseif frame >= 2100 and frame <= 2105 then
        syntheticInput = 0x0080       -- A: confirm
    elseif frame >= 3250 and frame <= 3255 then
        syntheticInput = 0x0080       -- A: confirm P1 level
    elseif frame >= 4050 and frame <= 4055 then
        syntheticInput = 0x0080       -- A: confirm P1 character
    else
        syntheticInput = 0
    end

    syntheticInput2 =
        ((frame >= 3250 and frame <= 3255) or
        (frame >= 4050 and frame <= 4055)) and 0x0080 or 0

    if frame == 1180 or frame == 1400 or frame == 1480 or
        frame == 1600 or frame == 1800 or frame == 2000 or
        frame == 2080 or frame == 2200 or frame == 2400 or
        frame == 2600 or frame == 2800 or frame == 3000 or frame == 3200 or
        frame == 3400 or frame == 3600 or frame == 3800 or frame == 4000 or
        frame == 4100 or frame == 4300 or frame == 4500 or frame == 4700 then
        screenshot(string.format("frame-%04d", frame))
    end

    if frame >= 4700 then
        emu.stop(0)
    end
end, emu.eventType.startFrame)
