-- Import the Tetromino class
require 'Tetromino'

-- Init dimensions of window
WINDOW_WIDTH = 640
WINDOW_HEIGHT = 720

-- Font size
FONT_SIZE = 10

-- Size of squares
SQUARE_SIZE = 25

-- Number of rows and columns of game
NUM_ROWS = 20
NUM_COLS = 10

-- Leftmost and Topmost positions of the grid
LEFT_X = WINDOW_WIDTH / 2 - (NUM_COLS / 2 * SQUARE_SIZE)
TOP_Y = WINDOW_HEIGHT / 2 - (NUM_ROWS / 2 * SQUARE_SIZE)

--[[
    Init function to set variables
]]
function love.load()
    -- Init the window size and options
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true,
    })

    -- Set title of game, and font size
    love.window.setTitle('Tetris')
    love.graphics.setFont(love.graphics.newFont(FONT_SIZE))

    -- Set seed of RNG for randomized square positions
    math.randomseed(os.time())

    -- Set gameState to beginning state
    gameState = "play"

    -- Store general pieceTypes in a list
    pieceTypes = { "I", "J", "L", "O", "S", "T", "Z" }

    -- Keep a mapping from pieceType to color (indexed values are RGB)
    pieceTypeToColor = {
        I = { 0, 1, 1 }, -- cyan
        J = { 0, 0, 1 }, -- blue
        L = { 1, 165/255, 0 }, -- orange
        O = { 1, 1, 0 }, -- yellow
        S = { 0, 1, 0 }, -- green
        T = { 1, 0, 1 }, -- purple
        Z = { 1, 0, 0 } -- red
    }

    --[[
        TODO: rethink design

        currently thinking of having an "activePiece" and "nextPiece" be Tetrominoes
        once they land/can't move anymore, swap pieces, and set blocks in a "total" map

        10 x 20 bottom-up map (aka row 1 is the bottom row)
    ]]

    -- Create NUM_ROWS x NUM_COLS block mapping
    blocks = {}
    for row=1, NUM_ROWS do
        blocks[row] = { blockCount = 0 }
        for col=1, NUM_COLS do
            blocks[row][col] = {
                x = LEFT_X + (col - 1) * SQUARE_SIZE,
                y = TOP_Y + (NUM_ROWS - row) * SQUARE_SIZE,
                filled = false,
                rgb = {1, 1, 1}
            }
        end
    end

    pieceTypeToSpawnLocation = {
        I = blocks[NUM_ROWS][NUM_COLS / 2 - 1],
        J = blocks[NUM_ROWS - 1][NUM_COLS / 2 + 2],
        L = blocks[NUM_ROWS - 1][NUM_COLS / 2],
        O = blocks[NUM_ROWS][NUM_COLS / 2],
        S = blocks[NUM_ROWS - 1][NUM_COLS / 2],
        T = blocks[NUM_ROWS - 1][NUM_COLS / 2 + 1],
        Z = blocks[NUM_ROWS - 1][NUM_COLS / 2 + 2]
    }

    -- Track pieces and last piece used
    lastPieceUsed = nil
    nextPieceType = getNewPieceType()
    activePiece = Tetromino:new(nextPieceType, pieceTypeToSpawnLocation[nextPieceType])
    nextPieceType = getNewPieceType()
    nextPiece = Tetromino:new(nextPieceType, {
        x = pieceTypeToSpawnLocation[nextPieceType].x + (NUM_ROWS / 2 - 1) * SQUARE_SIZE,
        y = WINDOW_HEIGHT / 2
    })

    -- Keep track of frames since a move
    frameCount = 0

    -- Use this for DAS tracking
    DASframeCount = 0
    DASfirstMoveMade = false

    -- Score and mapping number of lines cleared to score
    score = 0
    linesClearedToScore = { 40, 100, 300, 1200 }

    -- Level tracker and list used to check frames per move
    level = 0
    levelToFramesPerMove = {
        [0] = 48,
        43, 38, 33, 28, 23, 18, 13, 8, 6, 5, 5, 5, 4, 4, 4, 3, 3, 3,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2
    }
    setmetatable(levelToFramesPerMove, { __index = function() return 1 end })

    -- Line clear variables
    totalLinesCleared = 0
    currLevelNumLinesCleared = 0
    linesClearedToNextLevel = math.min(
        level * 10 + 10,
        math.max(100, level * 10 - 50)
    )

end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    if gameState == "play" then
        if frameCount == levelToFramesPerMove[level] then
            local isActive = activePiece:move()
            updateActivePiece(isActive)
            frameCount = 0
        else
            frameCount = frameCount + 1
        end

        local checkDAS = love.keyboard.isDown("left") or love.keyboard.isDown("right")
        if checkDAS then
            DASframeCount = DASframeCount + 1

            local DASfirstMoveCheck = DASframeCount == 16 and not DASfirstMoveMade
            local DASelseCheck = DASframeCount == 6 and DASfirstMoveMade
            if DASfirstMoveCheck or DASelseCheck then
                local moveDir = (love.keyboard.isDown("left") and -1) or 1
                DASfirstMoveMade = activePiece:sideMove(moveDir)
                DASframeCount = 0
            end
        else
            DASfirstMoveMade = false
            DASframeCount = 0
        end
    end
end

--[[
    Callback used when key is pressed

    key - the key that was pressed
    scancode - similar to key (something about keyboard independent layouts?)
    isrepeat - true if key repeats
]]
function love.keypressed(key, scancode, isrepeat)
    if key == "left" then
        activePiece:sideMove(-1)
    elseif key == "right" then
        activePiece:sideMove(1)
    elseif key == "down" then
        local isActive = activePiece:move()
        updateActivePiece(isActive)
    elseif key == "z" then
        activePiece:rotate(true)
    elseif key == "x" then
        activePiece:rotate(false)
    end
end

--[[
    Render graphics
]]
function love.draw()
    for _, row in ipairs(blocks) do
        for _, col in ipairs(row) do
            love.graphics.setColor(col.rgb)
            love.graphics.rectangle("fill", col.x, col.y, SQUARE_SIZE, SQUARE_SIZE)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", col.x, col.y, SQUARE_SIZE, SQUARE_SIZE)

            -- Test
            local s = ((col.filled) and "t") or "f"
            love.graphics.printf(s, col.x, col.y, SQUARE_SIZE, "center")
        end

        -- TODO: Make this toggleable under a debug mode?
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(tostring(row.blockCount), row[1].x - SQUARE_SIZE, row[1].y, SQUARE_SIZE, "center")
    end

    -- Draw the currently moveable piece
    activePiece:draw(pieceTypeToColor[activePiece.pieceType])

    -- Draw the next piece
    nextPiece:draw(pieceTypeToColor[nextPiece.pieceType])

    -- Print other info
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Level: " .. tostring(level), LEFT_X, TOP_Y - 3 * SQUARE_SIZE, NUM_COLS * SQUARE_SIZE, "center")
    love.graphics.printf("Total Lines Cleared: " .. tostring(totalLinesCleared), LEFT_X, TOP_Y - 2 * SQUARE_SIZE, NUM_COLS * SQUARE_SIZE, "center")
    love.graphics.printf("Score: " .. tostring(score), LEFT_X, TOP_Y - SQUARE_SIZE, NUM_COLS * SQUARE_SIZE, "center")
end

--[[
    Converts an (x, y) posiiton to (row, col) indices

    position - the (x, y) posiiton
    Returns corresponding (row, col) indices, or -1 for indices if outside of bounds
]]
function convertXYToRowCol(position)
    local x, y = position.x, position.y

    -- Y maps to row, X maps to column
    local row = NUM_ROWS - ((y - TOP_Y) / SQUARE_SIZE)
    local col = ((x - LEFT_X) / SQUARE_SIZE + 1)

    -- Check OOB
    if row < 1 or row > NUM_ROWS or col < 1 or col > NUM_COLS then
        row = -1
        col = -1
    end

    return { row = row, col = col }
end

--[[
    Spawns a new active piece

    isActive - true if the previous active piece couldn't move
]]
function updateActivePiece(isActive)
    -- If move failed, set the blocks matrix and get a new piece
    if not isActive then
        -- Set blocks using position of tetromino blocks
        for _, block in ipairs(activePiece) do
            local rowCol = convertXYToRowCol(block)
            local row, col = rowCol.row, rowCol.col

            blocks[row][col].filled = true
            blocks[row][col].rgb = pieceTypeToColor[activePiece.pieceType]
            blocks[row].blockCount = blocks[row].blockCount + 1
        end

        -- Check if any lines were cleared
        numLinesCleared = clearRows()
        if numLinesCleared > 0 then
            -- Update score and line clear vars
            score = score + linesClearedToScore[numLinesCleared]
            totalLinesCleared = totalLinesCleared + numLinesCleared
            currLevelNumLinesCleared = currLevelNumLinesCleared + numLinesCleared

            -- If enough lines cleared, move to next level
            if currLevelNumLinesCleared >= linesClearedToNextLevel then
                currLevelNumLinesCleared = currLevelNumLinesCleared - linesClearedToNextLevel
                level = level + 1
                linesClearedToNextLevel = linesClearedToNextLevel + 10
            end
        end

        activePiece = Tetromino:new(nextPieceType, pieceTypeToSpawnLocation[nextPieceType])
        nextPieceType = getNewPieceType()
        nextPiece = Tetromino:new(nextPieceType, {
            x = pieceTypeToSpawnLocation[nextPieceType].x + (NUM_ROWS / 2 - 1) * SQUARE_SIZE,
            y = WINDOW_HEIGHT / 2
        })

        -- TODO: check if spawned piece already collides. If so, game over.

    end
end

--[[
    Clears any completed rows

    Return number of completed lines
]]
function clearRows()
    -- Search for the rows that should be deleted
    local rowsToDelete = {}
    for i, row in ipairs(blocks) do
        local blockCount = row.blockCount

        if blockCount == NUM_COLS then
            table.insert(rowsToDelete, i)
        end
    end

    -- Rows to delete contains the indices of the rows that have full rows

    -- TODO: this is sorta inefficient, maybe look into something better
    for currDeleteNum, deleteIndex in ipairs(rowsToDelete) do
        -- Starting at the row to delete, transfer params of row above to it
        for rowIndex=deleteIndex - currDeleteNum + 1, NUM_ROWS-1 do
            local currRow = blocks[rowIndex]
            local nextRow = blocks[rowIndex + 1]

            for i=1, NUM_COLS do
                currRow[i].filled = nextRow[i].filled
                currRow[i].rgb = nextRow[i].rgb
            end

            -- Set block count to row above
            currRow.blockCount = nextRow.blockCount
        end

        -- Clear out top row
        for i=1, NUM_COLS do
            blocks[NUM_ROWS][i].filled = false
            blocks[NUM_ROWS][i].rgb = {1, 1, 1}
        end
    end

    -- Return size of list to determine points
    return #rowsToDelete
end

--[[
    Returns the randomized piece type of the next piece
]]
function getNewPieceType()
    -- NES version picks number from 0 to 7 (1 to 8 equivalent)
    local randIndex = math.floor(math.random() * 8) + 1
    local pieceType = pieceTypes[randIndex]

    -- Matching last piece used or dummy value 7 (8 here) will reroll from 0 to 6 (1 to 7)
    if lastPieceUsed == pieceType or pieceType == nil then
        randIndex = math.floor(math.random() * 7) + 1
        pieceType = pieceTypes[randIndex]
    end

    -- Return the pieceType
    lastPieceUsed = pieceType
    return pieceType
end
