--[[
    Base Tetromino class, intended to work with LOVE
]]

Tetromino = {}
Tetromino.__index = Tetromino -- Failed lookups go here

--[[
    Tetromino constructor

    pieceType - type of piece (e.g. I, J, O)
    initPos - initPosition of init block (see below, initPos at 1)

    Might seem weird at times, but this is designed so when rotating,
    block 3's position is fixed

    Initial positions of blocks:

    I - 1234


    J - 432
          1

    L - 234
        1

    O - 12
        34

    S -  34
        12

    T - 234
         1

    Z - 43
         21
]]
function Tetromino:new(pieceType, initPos)
    -- Init object with params
    local initX, initY = initPos.x, initPos.y
    local tetromino = {
        { x = initX, y = initY },
        pieceType = pieceType,
        currRotation = 0
    }

    -- Create the remaining pieces
    for i=2, 4 do
        local newX, newY = 0, 0

        -- newX and newY depends on the piece type
        if pieceType == "I" then
            newX = initX + (i - 1) * SQUARE_SIZE
            newY = initY
        elseif pieceType == "J" then
            newX = initX - (i - 2) * SQUARE_SIZE
            newY = initY - SQUARE_SIZE
        elseif pieceType == "L" then
            newX = initX + (i - 2) * SQUARE_SIZE
            newY = initY - SQUARE_SIZE
        elseif pieceType == "O" then
            newX = initX + ((i + 1) % 2) * SQUARE_SIZE
            newY = initY + math.floor((i - 1) / 2) * SQUARE_SIZE
        elseif pieceType == "S" then
            newX = initX + math.floor(i / 2) * SQUARE_SIZE
            newY = initY - math.floor((i - 1) / 2) * SQUARE_SIZE
        elseif pieceType == "T" then
            newX = initX + (i - 3) * SQUARE_SIZE
            newY = initY - SQUARE_SIZE
        elseif pieceType == "Z" then
            newX = initX - math.floor(i / 2) * SQUARE_SIZE
            newY = initY - math.floor((i - 1) / 2) * SQUARE_SIZE
        end

        -- Insert piece at position i
        tetromino[i] = { x = newX, y = newY }
    end

    -- Set object metatable to base Tetromino class, uses this for function lookup
    setmetatable(tetromino, Tetromino)
    return tetromino
end

--[[
    Draws tetromino to screen (assuming LOVE is being used)

    color - color of piece
    debugMode - true if debug mode is on
]]
function Tetromino:draw(color, debugMode)
    -- Use this in case individual blocks are deleted
    for i=1, 4 do
        if self[i] then
            local x, y = self[i].x, self[i].y

            -- TODO: this should draw an outline for each block, but maybe look into shader?
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", x, y, SQUARE_SIZE, SQUARE_SIZE)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", x, y, SQUARE_SIZE, SQUARE_SIZE)

            if debugMode then
                love.graphics.printf(tostring(i), x, y, SQUARE_SIZE, "center")
            end
        end
    end
end

--[[
    Move the tetromino down

    Returns true if move was successful
]]
function Tetromino:move()
    -- Check if there's a collision moving down
    for _, block in ipairs(self) do
        local newX, newY = block.x, block.y + SQUARE_SIZE
        local rowCol = convertXYToRowCol({ x = newX, y = newY })
        local row, col = rowCol.row, rowCol.col

        -- If collision would occur, return false
        if (row == -1 and col == -1) or blocks[row][col].filled then
            return false
        end
    end

    -- Move down by a SQUARE_SIZE and return true
    for _, block in ipairs(self) do
        block.y = block.y + SQUARE_SIZE
    end
    return true
end

--[[
    Move the tetromino sideways

    dir - -1 if moving left, 1 if moving right
    Returns true if move was successful
]]
function Tetromino:sideMove(dir)
    -- Check if there's a collision moving sideways
    for _, block in ipairs(self) do
        local newX, newY = block.x + dir * SQUARE_SIZE, block.y
        local rowCol = convertXYToRowCol({ x = newX, y = newY })
        local row, col = rowCol.row, rowCol.col

        -- If collision would occur, return false
        if (row == -1 and col == -1) or blocks[row][col].filled then
            return false
        end
    end

    -- Move sideways by a SQUARE_SIZE and return true
    for _, block in ipairs(self) do
        block.x = block.x + dir * SQUARE_SIZE
    end
    return true
end

--[[
    Rotate the tetromino

    clockwise - rotate clockwise if true

    This system is based on the NES Tetris rotation system. That is:
        * Pieces rotate around block #3
        * No wall kick (if rotation puts tetromino in impossible space, no rotation)
]]
function Tetromino:rotate(clockwise)
    local pieceType = self.pieceType

    -- O pieces don't rotate
    if pieceType == "O" then return end

    -- Get reference to the pivoting block and rotation
    local pivotBlock = self[3]
    local currRotation = self.currRotation

    -- Lay the changes here so we can check collisions before assigning
    local preTetramino = {}

    -- Reverse direction for LJT piece if param is false
    local LJT = pieceType == "L" or pieceType == "J" or pieceType == "T"
    local LJTreverse = LJT and not clockwise

    -- Reverse direction for SZ piece if in initial state
    local SZ = pieceType == "S" or pieceType == "Z"
    local SZreverse = SZ and currRotation == 0

    -- Reverse direction for I piece if in rotated state
    local Ireverse = pieceType == "I" and currRotation == 1
    local reverseDirection = LJTreverse or SZreverse or Ireverse

    -- Loop through each block
    for i, currBlock in ipairs(self) do
        -- Calculate dimension changes (axes switch)
        local changeInX = currBlock.y - pivotBlock.y
        local changeInY = currBlock.x - pivotBlock.x

        -- Reverse the values if needed
        if reverseDirection then
            changeInX = -changeInX
            changeInY = -changeInY
        end

        -- Check if rotated block position collides
        local newX, newY = pivotBlock.x - changeInX, pivotBlock.y + changeInY
        local rowCol = convertXYToRowCol({ x = newX, y = newY }) -- TODO: bad style? (function in other file)
        local row, col = rowCol.row, rowCol.col
        if (row == -1 and col == -1) or blocks[row][col].filled then return end

        -- Set x and y positions, and rotation amount
        preTetramino[i] = { x = newX, y = newY }
    end

    -- No collisions means update the tetramino positions and rotation state
    for i=1, 4 do
        self[i].x = preTetramino[i].x
        self[i].y = preTetramino[i].y
    end
    self.currRotation = (currRotation + 1) % 2
end

--[[
    Debug print function
]]
function Tetromino:print() 
    print("Piece type:", self.pieceType)
    for i, block in ipairs(self) do
        print("Index:", i)
        print("x-pos:", block.x)
        print("y-pos:", block.y)
        print()
    end
end
