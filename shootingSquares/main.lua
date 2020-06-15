-- Init dimensions of window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- Size of the square to shoot
SQUARE_SIZE = 25

-- Font size
FONT_SIZE = 20

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
    love.window.setTitle('Shooting Squares')
    love.graphics.setFont(love.graphics.newFont(FONT_SIZE))

    -- Set cursor to a crosshair
    local cursor = love.mouse.getSystemCursor("crosshair")
    love.mouse.setCursor(cursor)

    -- Set seed of RNG for randomized square positions
    math.randomseed(os.time())

    -- Init score
    score = 0

    -- Set initial position and speeds
    currX = math.random() * (WINDOW_WIDTH - SQUARE_SIZE)
    currY = math.random() * (WINDOW_HEIGHT - SQUARE_SIZE)
    dx = 60
    dy = 60
end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    -- Calculate distance to move in X and Y directions
    moveX = dt * dx
    moveY = dt * dy

    -- If moving in that direction goes out of bounds, switch directions
    if currX + moveX < 0 or currX + SQUARE_SIZE + moveX > WINDOW_WIDTH then
        dx = -dx
        moveX = -moveX
    end
    if currY + moveY < 0 or currY + SQUARE_SIZE + moveY > WINDOW_HEIGHT then
        dy = -dy
        moveY = -moveY
    end

    -- Update position
    currX = currX + moveX
    currY = currY + moveY

end

--[[
    Callback used when mouse is pressed

    x - x-position of cursor
    y - y-position of cursor
    button - type of button (1 is LMB)
    istouch - touchscreen was used (?)
    presses - amount of presses in short time
]]
function love.mousepressed(x, y, button, istouch, presses)
    -- Update score and position if cursor is in bounds
    if button == 1 and checkWithinSquare(x, y) then
        score = score + 1
        currX = math.random() * (WINDOW_WIDTH - SQUARE_SIZE)
        currY = math.random() * (WINDOW_HEIGHT - SQUARE_SIZE)

        -- Randomize direction 
        local changeX, changeY = math.random() < 0.5, math.random() < 0.5
        if changeX then
            dx = -dx
        end

        if changeY then
            dy = -dy
        end
    end
end

--[[
    Render graphics
]]
function love.draw()
    -- Highlight square with red color is mouse is within bounds
    local x, y = love.mouse.getPosition()
    if checkWithinSquare(x, y) then
        love.graphics.setColor(255, 0, 0)
    end
    love.graphics.rectangle("fill", currX, currY, SQUARE_SIZE, SQUARE_SIZE)

    -- Reset color and print score
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf("Score is " .. score, 0, 50, WINDOW_WIDTH, "center")
end

--[[
    Checks if (x, y) is contained in square

    x - x-position to check
    y - y-position to check
    returns true if point is in square
]]
function checkWithinSquare(x, y)
    withinX = x > currX and x < currX + SQUARE_SIZE
    withinY = y > currY and y < currY + SQUARE_SIZE

    return withinX and withinY
end
