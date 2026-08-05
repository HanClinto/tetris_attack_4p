local frame = 0
local startFrame = nil

emu.addEventCallback(function()
    frame = frame + 1
end, emu.eventType.endFrame)

emu.addMemoryCallback(function()
    if startFrame == nil and
        emu.read(0x01BA, emu.memType.snesWorkRam) == 0x02 then
        startFrame = frame
    end
end, emu.callbackType.exec, 0xA08700)

emu.addMemoryCallback(function()
    if startFrame == nil then
        return
    end

    local frameDelta = frame - startFrame
    print(string.format("block-move frame delta=%d", frameDelta))
    if frameDelta <= 1 then
        emu.stop(0)
    else
        emu.stop(1)
    end
end, emu.callbackType.exec, 0xA08014)