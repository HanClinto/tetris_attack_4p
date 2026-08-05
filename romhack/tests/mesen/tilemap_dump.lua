local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
emu.addEventCallback(function()
    frame = frame + 1
    if frame ~= 3600 then
        return
    end

    local dump = assert(io.open(outputFolder .. "/vram.bin", "wb"))
    for address = 0x0000, 0xFFFF do
        dump:write(string.char(emu.read(address, emu.memType.snesVideoRam)))
    end
    dump:close()

    dump = assert(io.open(outputFolder .. "/cgram.bin", "wb"))
    for address = 0x0000, 0x01FF do
        dump:write(string.char(emu.read(address, emu.memType.snesCgRam)))
    end
    dump:close()

    local screenshot = assert(io.open(outputFolder .. "/frame-3600.png", "wb"))
    screenshot:write(emu.takeScreenshot())
    screenshot:close()

    emu.stop(0)
end, emu.eventType.startFrame)
