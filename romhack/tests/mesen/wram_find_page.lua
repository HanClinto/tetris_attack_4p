local frames = 0
local traceStartFrame = 120
local traceEndFrame = traceStartFrame + 3600

emu.addEventCallback(function()
    frames = frames + 1
    if frames == traceStartFrame then
        emu.resetAccessCounters()
        return
    end

    if frames < traceEndFrame then
        return
    end

    local reads = emu.getAccessCounters(
        emu.counterType.readCount,
        emu.memType.snesWorkRam
    )
    local writes = emu.getAccessCounters(
        emu.counterType.writeCount,
        emu.memType.snesWorkRam
    )

    for page = 0, 254 do
        local pageStart = 0x10000 + page * 0x100
        local pageUnused = true
        for address = pageStart, pageStart + 0xFF do
            if reads[address] ~= 0 or writes[address] ~= 0 then
                pageUnused = false
                break
            end
        end

        if pageUnused then
            emu.stop(page + 1)
            return
        end
    end

    emu.stop(0)
end, emu.eventType.startFrame)
