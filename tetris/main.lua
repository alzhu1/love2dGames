-- Init dimensions of window
WINDOW_WIDTH = 640
WINDOW_HEIGHT = 360

-- Font size
FONT_SIZE = 20

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
end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    if gameState == "play" then

    end
end

--[[
    Render graphics
]]
function love.draw()

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
