-- Import the Tetromino class
require 'Tetromino'

-- Init dimensions of window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- Font size
FONT_SIZE = 10

-- Size of squares
SQUARE_SIZE = 10


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

    -- Keep a bunch of pieces here
    allPieces = {}

    -- Temp pieces
    for i, pieceType in ipairs(pieceTypes) do
        allPieces[i] = Tetromino:new(pieceType, {
            x = math.random() * (WINDOW_WIDTH - 4 * SQUARE_SIZE),
            y = math.random() * (WINDOW_HEIGHT - 4 * SQUARE_SIZE)
        })
    end

    timer = 0
end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    if gameState == "play" then
        if timer >= 3 then
            for _, piece in ipairs(allPieces) do
                piece:rotate(false)
            end
            timer = 0
        else
            timer = timer + dt
        end
    end
end

--[[
    Render graphics
]]
function love.draw()
    -- Draw each piece
    for _, piece in ipairs(allPieces) do
        local pieceType = piece.pieceType
        piece:draw(pieceTypeToColor[pieceType])
    end
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
