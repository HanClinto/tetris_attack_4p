local expected = {
    0x8000, -- B
    0x4000, -- Y
    0x2000, -- Select
    0x1000, -- Start
}

local padInputs = {
    { b = true },
    { y = true },
    { select = true },
    { start = true },
}

local pollCount = 0

emu.addMemoryCallback(function(_, value)
    if value == 0 then
        for subport = 0, 3 do
            -- Mesen 2.1.1 requires a fourth compatibility argument for
            -- setInput to retain the documented subport argument.
            emu.setInput(padInputs[subport + 1], 0, 1, subport)
        end
    end
end, emu.callbackType.write, 0x004016)

emu.addMemoryCallback(function()
    pollCount = pollCount + 1
end, emu.callbackType.exec, 0xA08200)

local frames = 0
emu.addEventCallback(function()
    frames = frames + 1
    if frames >= 120 then
        if pollCount == 0 then
            emu.stop(2)
            return
        end

        for index = 1, 4 do
            local actual = emu.read16(
                0x1FE00 + (index - 1) * 2,
                emu.memType.snesWorkRam
            )
            if actual ~= expected[index] then
                emu.stop(10 + index)
                return
            end
        end

        emu.stop(0)
    end
end, emu.eventType.startFrame)
