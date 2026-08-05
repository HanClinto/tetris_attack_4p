local frame = 0
local syntheticInput1 = 0
local syntheticInput2 = 0

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
    elseif (frame >= 3250 and frame <= 3255) or
        (frame >= 4050 and frame <= 4055) then
        syntheticInput1 = 0x0080
        syntheticInput2 = 0x0080
    end
end

local function readBoard()
    local board = {}
    for row = 0, 11 do
        board[row + 1] = {}
        for column = 0, 5 do
            board[row + 1][column + 1] = emu.read16(
                0x0FAE + row * 0x10 + column * 2,
                emu.memType.snesWorkRam
            ) & 0xFF
        end
    end
    return board
end

local function hasMatch(board, targetRow, targetColumn)
    local color = board[targetRow][targetColumn]
    if color == 0 or color > 5 then
        return false
    end

    local horizontal = 1
    local column = targetColumn - 1
    while column >= 1 and board[targetRow][column] == color do
        horizontal = horizontal + 1
        column = column - 1
    end
    column = targetColumn + 1
    while column <= 6 and board[targetRow][column] == color do
        horizontal = horizontal + 1
        column = column + 1
    end

    local vertical = 1
    local row = targetRow - 1
    while row >= 1 and board[row][targetColumn] == color do
        vertical = vertical + 1
        row = row - 1
    end
    row = targetRow + 1
    while row <= 12 and board[row][targetColumn] == color do
        vertical = vertical + 1
        row = row + 1
    end
    return horizontal >= 3 or vertical >= 3
end

local function matchCount(board)
    local matched = {}
    for row = 1, 12 do
        local column = 1
        while column <= 6 do
            local color = board[row][column]
            local lastColumn = column
            while lastColumn + 1 <= 6 and
                board[row][lastColumn + 1] == color do
                lastColumn = lastColumn + 1
            end
            if color ~= 0 and color <= 5 and lastColumn - column + 1 >= 3 then
                for matchedColumn = column, lastColumn do
                    matched[row .. ":" .. matchedColumn] = true
                end
            end
            column = lastColumn + 1
        end
    end
    for column = 1, 6 do
        local row = 1
        while row <= 12 do
            local color = board[row][column]
            local lastRow = row
            while lastRow + 1 <= 12 and
                board[lastRow + 1][column] == color do
                lastRow = lastRow + 1
            end
            if color ~= 0 and color <= 5 and lastRow - row + 1 >= 3 then
                for matchedRow = row, lastRow do
                    matched[matchedRow .. ":" .. column] = true
                end
            end
            row = lastRow + 1
        end
    end
    local cells = {}
    for cell in pairs(matched) do
        table.insert(cells, cell)
    end
    table.sort(cells)
    return #cells, table.concat(cells, ",")
end

local function findSwaps(board)
    local swaps = {}
    for row = 1, 12 do
        for column = 1, 5 do
            local left = board[row][column]
            local right = board[row][column + 1]
            if left ~= right and left ~= 0 and right ~= 0 then
                board[row][column], board[row][column + 1] = right, left
                if hasMatch(board, row, column) or
                    hasMatch(board, row, column + 1) then
                    local count, cells = matchCount(board)
                    table.insert(swaps, {
                        row = row - 1,
                        column = column - 1,
                        left = left,
                        right = right,
                        matchCount = count,
                        matchedCells = cells,
                    })
                end
                board[row][column], board[row][column + 1] = left, right
            end
        end
    end
    return swaps
end

emu.addEventCallback(function()
    frame = frame + 1
    setMenuInput()

    if frame == 4700 then
        local swaps = findSwaps(readBoard())
        local cursorX = emu.read16(0x03A4, emu.memType.snesWorkRam)
        local cursorY = emu.read16(0x03A8, emu.memType.snesWorkRam)
        print(string.format("cursor=%d,%d swaps=%d", cursorX, cursorY, #swaps))
        for index, swap in ipairs(swaps) do
            print(string.format(
                "swap%d=%d,%d colors=%d,%d matches=%d cells=%s distance=%d",
                index,
                swap.column,
                swap.row,
                swap.left,
                swap.right,
                swap.matchCount,
                swap.matchedCells,
                math.abs(cursorX - swap.column) + math.abs(cursorY - swap.row)
            ))
        end
        emu.stop(#swaps > 0 and 0 or 2)
    end
end, emu.eventType.startFrame)