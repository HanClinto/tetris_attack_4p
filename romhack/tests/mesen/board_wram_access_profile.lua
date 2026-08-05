local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local startFrame = 3500
local endFrame = 3560
local frame = 0
local reads = {}
local writes = {}

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

emu.addEventCallback(function()
    frame = frame + 1
    if frame == startFrame then
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
        writeProfile(outputFolder .. "/read-profile.bin", reads)
        writeProfile(outputFolder .. "/write-profile.bin", writes)
        emu.stop(0)
    end
end, emu.eventType.startFrame)
