local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0
local reads = {}
local writes = {}
local startFrame = 4700
local endFrame = 4780

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

local function normalizeWramAddress(address)
    if address <= 0x1FFFF then
        return address
    end

    local bank = (address >> 16) & 0xFF
    local bankAddress = address & 0xFFFF
    if bank == 0x7E or bank == 0x7F then
        return address - 0x7E0000
    elseif bankAddress < 0x2000 and
        (bank <= 0x3F or (bank >= 0x80 and bank <= 0xBF)) then
        return bankAddress
    end
    return nil
end

local function countAccess(target, address)
    local normalized = normalizeWramAddress(address)
    if normalized ~= nil then
        target[normalized] = (target[normalized] or 0) + 1
    end
end

local function dumpWram(path)
    local output = assert(io.open(path, "wb"))
    for address = 0, 0x1FFFF do
        output:write(string.char(emu.read(address, emu.memType.snesWorkRam)))
    end
    output:close()
end

local function writeProfile(path, profile)
    local output = assert(io.open(path, "wb"))
    local addresses = {}
    for address in pairs(profile) do
        table.insert(addresses, address)
    end
    table.sort(addresses)

    for _, address in ipairs(addresses) do
        local count = math.min(profile[address], 0xFFFFFFFF)
        output:write(string.char(
            address & 0xFF,
            (address >> 8) & 0xFF,
            (address >> 16) & 0xFF,
            (address >> 24) & 0xFF,
            count & 0xFF,
            (count >> 8) & 0xFF,
            (count >> 16) & 0xFF,
            (count >> 24) & 0xFF
        ))
    end
    output:close()
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
    elseif frame >= 3250 and frame <= 3255 then
        syntheticInput1 = 0x0080
        syntheticInput2 = 0x0080
    elseif frame >= 4050 and frame <= 4055 then
        syntheticInput1 = 0x0080
        syntheticInput2 = 0x0080
    elseif frame >= 4710 and frame <= 4712 then
        syntheticInput1 = 0x0100
    elseif frame >= 4720 and frame <= 4722 then
        syntheticInput1 = 0x0080
    elseif frame >= 4740 and frame <= 4742 then
        syntheticInput2 = 0x0200
    elseif frame >= 4750 and frame <= 4752 then
        syntheticInput2 = 0x0080
    end
end

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == startFrame then
        dumpWram(outputFolder .. "/wram-start.bin")
        emu.addMemoryCallback(
            function(address) countAccess(reads, address) end,
            emu.callbackType.read,
            0,
            0x1FFFF,
            emu.cpuType.snes,
            emu.memType.snesWorkRam
        )
        emu.addMemoryCallback(
            function(address) countAccess(writes, address) end,
            emu.callbackType.write,
            0,
            0x1FFFF,
            emu.cpuType.snes,
            emu.memType.snesWorkRam
        )
    elseif frame == endFrame then
        dumpWram(outputFolder .. "/wram-end.bin")
        writeProfile(outputFolder .. "/read-profile.bin", reads)
        writeProfile(outputFolder .. "/write-profile.bin", writes)

        local screenshot = assert(io.open(outputFolder .. "/frame-4780.png", "wb"))
        screenshot:write(emu.takeScreenshot())
        screenshot:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)
