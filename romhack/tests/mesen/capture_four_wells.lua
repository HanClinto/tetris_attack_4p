local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local mode2Frames = 0

emu.addMemoryCallback(function()
    if emu.read(0x01BA, emu.memType.snesWorkRam) ~= 0x02 then
        return
    end

    mode2Frames = mode2Frames + 1
    if mode2Frames < 120 then
        return
    end

    local screenshot = assert(io.open(
        outputFolder .. "/four-well-layout.png",
        "wb"
    ))
    screenshot:write(emu.takeScreenshot())
    screenshot:close()
    emu.stop(0)
end, emu.callbackType.exec, 0xA08408)