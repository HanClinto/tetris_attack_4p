local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput = 0

for _, bank in ipairs({ 0x000000, 0x800000 }) do
    emu.addMemoryCallback(function() return syntheticInput & 0xFF end,
        emu.callbackType.read, bank + 0x4218)
    emu.addMemoryCallback(function() return (syntheticInput >> 8) & 0xFF end,
        emu.callbackType.read, bank + 0x4219)
end

emu.addEventCallback(function()
    frame = frame + 1
    syntheticInput = frame >= 1190 and frame <= 1195 and 0x8000 or 0

    if frame == 1400 then
        local screenshot = assert(io.open(
            outputFolder .. "/four-player-menu.png",
            "wb"
        ))
        screenshot:write(emu.takeScreenshot())
        screenshot:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)