--[[
    Base Tetromino class, intended to work with LOVE
]]

Tetromino = {}
Tetromino.__index = Tetromino -- Failed lookups go here

--[[
    Tetromino constructor

    pieceType - type of piece (e.g. I, J, O)
    initPos - initPosition of top-left most init block (see below, initPos at 1)

    Index of positions goes from left to right, top to bottom in that order
    Initial positions of blocks:

    I - 1234


    J - 1
        234

    L -   1
        234

    O - 12
        34

    S -  12
        34

    T -  1
        234

    Z - 12
         34
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
            newX = initX + (i - 2) * SQUARE_SIZE
            newY = initY + SQUARE_SIZE
        elseif pieceType == "L" then
            newX = initX + (i - 4) * SQUARE_SIZE
            newY = initY + SQUARE_SIZE
        elseif pieceType == "O" then
            newX = initX + ((i + 1) % 2) * SQUARE_SIZE
            newY = initY + math.floor((i - 1) / 2) * SQUARE_SIZE
        elseif pieceType == "S" then
            newX = initX + ((i == 2) and SQUARE_SIZE or (i - 4) * SQUARE_SIZE)
            newY = initY + math.floor((i - 1) / 2) * SQUARE_SIZE
        elseif pieceType == "T" then
            newX = initX + (i - 3) * SQUARE_SIZE
            newY = initY + SQUARE_SIZE
        elseif pieceType == "Z" then
            newX = initX + math.floor(i / 2) * SQUARE_SIZE
            newY = initY + math.floor((i - 1) / 2) * SQUARE_SIZE
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
]]
function Tetromino:draw(color)
    for _, block in ipairs(self) do
        local x, y = block.x, block.y

        -- TODO: this should draw an outline for each block, but maybe look into shader?
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x, y, SQUARE_SIZE, SQUARE_SIZE)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", x, y, SQUARE_SIZE, SQUARE_SIZE)
    end
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
