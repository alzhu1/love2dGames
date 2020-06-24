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
                rgb = {row / NUM_ROWS, col / NUM_COLS, row / NUM_ROWS}
            }
        end
    end

    -- Temp piece
    activePiece = Tetromino:new("I", { x = LEFT_X, y = TOP_Y})
    nextPiece = nil -- Randomize

    frameCount = 0
end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    if gameState == "play" then
        if frameCount == 48 then
            activePiece:move()
            frameCount = 0
        else
            frameCount = frameCount + 1
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "z" then
        activePiece:rotate(true)
    elseif key == "x" then
        activePiece:rotate(false)
    end
end

--[[
    Render graphics
]]
function love.draw()
    -- Draw each piece
    -- for _, piece in ipairs(allPieces) do
    --     local pieceType = piece.pieceType
    --     piece:draw(pieceTypeToColor[pieceType])
    -- end

    for _, row in ipairs(blocks) do
        for a, col in ipairs(row) do
            love.graphics.setColor(col.rgb)
            love.graphics.rectangle("fill", col.x, col.y, SQUARE_SIZE, SQUARE_SIZE)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", col.x, col.y, SQUARE_SIZE, SQUARE_SIZE)
        end
    end

    activePiece:draw(pieceTypeToColor[activePiece.pieceType])
end

-- TODO: keep this for tetris collisions?
--[[
    General function used to check AABB collisions (assuming squares)

    obj1 - first object
    size1 - side length of first object
    obj2 - second object
    size2 - side length of second object

    Returns if a collision occurred between both objects
]]
function checkSquareCollision(obj1, size1, obj2, size2)
    local x1, y1 = obj1.x, obj1.y
    local x2, y2 = obj2.x, obj2.y

    local withinX = x1 < x2 + size2 and x1 + size1 > x2
    local withinY = y1 < y2 + size2 and y1 + size1 > y2

    return withinX and withinY
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