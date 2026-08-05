local frame = 0
local syntheticInput = 0

for _, bank in ipairs({ 0x000000, 0x800000 }) do
    emu.addMemoryCallback(function() return syntheticInput & 0xFF end,
        emu.callbackType.read, bank + 0x4218)
    emu.addMemoryCallback(function() return (syntheticInput >> 8) & 0xFF end,
        emu.callbackType.read, bank + 0x4219)
end

local function verifyMenuTile()
    local actual = emu.read16(0xD24C, emu.memType.snesVideoRam)
    local nonzero = 0
    for address = 0xBE60, 0xBE7F do
        if emu.read(address, emu.memType.snesVideoRam) ~= 0 then
            nonzero = nonzero + 1
        end
    end
    if actual ~= 0x0BF3 or nonzero < 5 then
        print(string.format(
            "menu word=$%04X uploaded=%d",
            actual,
            nonzero
        ))
        return false
    end
    return true
end

emu.addEventCallback(function()
    frame = frame + 1
    syntheticInput = frame >= 1190 and frame <= 1195 and 0x8000 or 0

    if frame == 1400 then
        local state = emu.getState()
        if state["ppu.bgMode"] ~= 1 or
            state["ppu.layers[0].tilemapAddress"] ~= 0x6800 or
            state["ppu.layers[0].chrAddress"] ~= 0x2000 then
            emu.stop(2)
        elseif not verifyMenuTile() then
            emu.stop(3)
        elseif emu.read(0x12000, emu.memType.snesWorkRam) == 0xA5 then
            emu.stop(4)
        else
            emu.stop(0)
        end
    end
end, emu.eventType.startFrame)