local outputFolder = emu.getScriptDataFolder()
if outputFolder == "" then
    emu.stop(2)
    return
end

local startFrame = 3000
local endFrame = 3600
local frame = 0
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

local function observeWrite(address)
    local normalized = normalizeWramAddress(address)
    if normalized ~= nil then
        writes[normalized] = (writes[normalized] or 0) + 1
    end
end

local function dumpWram(path)
    local output = assert(io.open(path, "wb"))
    for address = 0, 0x1FFFF do
        output:write(string.char(emu.read(address, emu.memType.snesWorkRam)))
    end
    output:close()
end

emu.addEventCallback(function()
    frame = frame + 1

    if frame == startFrame then
        dumpWram(outputFolder .. "/wram-start.bin")
        emu.addMemoryCallback(
            observeWrite,
            emu.callbackType.write,
            0,
            0x1FFFF,
            emu.cpuType.snes,
            emu.memType.snesWorkRam
        )
    elseif frame == endFrame then
        dumpWram(outputFolder .. "/wram-end.bin")

        local profile = assert(io.open(outputFolder .. "/write-profile.bin", "wb"))
        local addresses = {}
        for address in pairs(writes) do
            table.insert(addresses, address)
        end
        table.sort(addresses)

        for _, address in ipairs(addresses) do
                local count = math.min(writes[address], 0xFFFFFFFF)
                profile:write(string.char(
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
        profile:close()
        emu.stop(0)
    end
end, emu.eventType.startFrame)
