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

local function dumpMemory(name, lastAddress, memoryType)
    local output = assert(io.open(outputFolder .. "/" .. name, "wb"))
    for address = 0, lastAddress do
        output:write(string.char(emu.read(address, memoryType)))
    end
    output:close()
end

emu.addEventCallback(function()
    frame = frame + 1
    syntheticInput = frame >= 1190 and frame <= 1195 and 0x8000 or 0

    if frame == 1400 then
        local state = emu.getState()
        print(string.format(
            "menu mode=$%02X bg1=$%04X/$%04X bg2=$%04X/$%04X bg3=$%04X/$%04X",
            state["ppu.bgMode"] or 0,
            state["ppu.layers[0].tilemapAddress"] or 0,
            state["ppu.layers[0].chrAddress"] or 0,
            state["ppu.layers[1].tilemapAddress"] or 0,
            state["ppu.layers[1].chrAddress"] or 0,
            state["ppu.layers[2].tilemapAddress"] or 0,
            state["ppu.layers[2].chrAddress"] or 0
        ))
        dumpMemory("vram.bin", 0xFFFF, emu.memType.snesVideoRam)
        dumpMemory("cgram.bin", 0x01FF, emu.memType.snesCgRam)
        local screenshot = assert(io.open(outputFolder .. "/menu.png", "wb"))
        screenshot:write(emu.takeScreenshot())
        screenshot:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)