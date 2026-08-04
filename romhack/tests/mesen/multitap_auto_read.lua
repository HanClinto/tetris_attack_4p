local inputPolls = 0
local frames = 0
local p1Reads = 0
local controllerDataObserved = false
local subportPresent = false
local subportUp = false
local isPort2Control = string.find(emu.getRomInfo().name, "port2-auto-read") ~= nil
local subportIndex = isPort2Control and 0 or 1
local controllerDataAddress = isPort2Control and 0x421A or 0x421E

emu.addMemoryCallback(function()
    p1Reads = p1Reads + 1
    controllerDataObserved = controllerDataObserved or
        emu.read16(controllerDataAddress, emu.memType.snesMemoryDebug) ~= 0
end, emu.callbackType.exec, 0x809C10)

emu.addEventCallback(function()
    inputPolls = inputPolls + 1
    -- Mesen 2.1.1 pads setInput to four arguments before reading them in
    -- reverse, so the fourth argument is required to select a subport.
    emu.setInput({ up = true }, 0, 1, subportIndex)
    local subport = emu.getInput(1, subportIndex)
    subportPresent = next(subport) ~= nil
    subportUp = subport.up == true
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    frames = frames + 1

    if frames >= 600 then
        local p1Current = emu.read16(0x00B3, emu.memType.snesWorkRam)
        emu.log(string.format(
            "frames=%d inputPolls=%d p1Reads=%d subportUp=%s p1Current=$%04X",
            frames,
            inputPolls,
            p1Reads,
            tostring(subportUp),
            p1Current
        ))
        if inputPolls == 0 then
            emu.stop(2)
        elseif not subportPresent then
            emu.stop(6)
        elseif not subportUp then
            emu.stop(4)
        elseif p1Reads == 0 then
            emu.stop(5)
        elseif not controllerDataObserved then
            emu.stop(7)
        elseif p1Current == 0 then
            emu.stop(3)
        else
            emu.stop(0)
        end
    end
end, emu.eventType.startFrame)
