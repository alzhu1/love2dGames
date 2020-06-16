-- Init dimensions of window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- Size of the square to shoot
SQUARE_SIZE = 25

-- Font size
FONT_SIZE = 20

-- Add new square every couple of points
NEW_SQUARE_POINT_THRESHOLD = 10

-- Maximum number of squares
MAX_NUM_SQUARES = 5

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

    -- Create table of squares and set init positions
    squares = {
        {
            currX = math.random() * (WINDOW_WIDTH - SQUARE_SIZE),
            currY = math.random() * (WINDOW_HEIGHT - SQUARE_SIZE),
            dx = 60,
            dy = 60
        }
    }
end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    moveSquares(dt)
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
    if button == 1 then
        for i, square in ipairs(squares) do
            if checkWithinSquare(x, y, square) then
                score = score + 1
                square.currX = math.random() * (WINDOW_WIDTH - SQUARE_SIZE)
                square.currY = math.random() * (WINDOW_HEIGHT - SQUARE_SIZE)

                -- Randomize direction
                local changeX, changeY = math.random() < 0.5, math.random() < 0.5
                if changeX then
                    square.dx = -square.dx
                end

                if changeY then
                    square.dy = -square.dy
                end

                -- Add a new square every couple of points
                if score % NEW_SQUARE_POINT_THRESHOLD == 0 and table.getn(squares) < MAX_NUM_SQUARES then
                    table.insert(squares, {
                        currX = math.random() * (WINDOW_WIDTH - SQUARE_SIZE),
                        currY = math.random() * (WINDOW_HEIGHT - SQUARE_SIZE),
                        dx = 60,
                        dy = 60
                    })
                end
            end
        end
    end
end

--[[
    Render graphics
]]
function love.draw()
    -- Get mouse position
    local x, y = love.mouse.getPosition()

    -- Check each square
    for i, square in ipairs(squares) do
        -- Highlight square with red color is mouse is within bounds
        if checkWithinSquare(x, y, square) then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(255, 255, 255)
        end

        love.graphics.rectangle("fill", square.currX, square.currY, SQUARE_SIZE, SQUARE_SIZE)
    end

    -- Set text color and print
    love.graphics.setColor(0, 120, 255)
    love.graphics.printf("Score is " .. score, 0, 50, WINDOW_WIDTH, "center")
end

--[[
    Checks if (x, y) is contained in square

    x - x-position to check
    y - y-position to check
    returns true if point is in square
]]
function checkWithinSquare(x, y, square)
    withinX = x > square.currX and x < square.currX + SQUARE_SIZE
    withinY = y > square.currY and y < square.currY + SQUARE_SIZE

    return withinX and withinY
end

--[[
    Move every square in play

    dt - amount of time (in sec) passed per frame
]]
function moveSquares(dt)
    for i, square in ipairs(squares) do
        -- Calculate distance to move in X and Y directions
        local currX, currY, dx, dy = square.currX, square.currY, square.dx, square.dy
        moveX = dt * dx
        moveY = dt * dy

        -- If moving in that direction goes out of bounds, switch directions
        if currX + moveX < 0 or currX + SQUARE_SIZE + moveX > WINDOW_WIDTH then
            square.dx = -dx
            moveX = -moveX
        end
        if currY + moveY < 0 or currY + SQUARE_SIZE + moveY > WINDOW_HEIGHT then
            square.dy = -dy
            moveY = -moveY
        end

        -- TODO: maybe add collision between squares as well?

        -- Update position
        square.currX = currX + moveX
        square.currY = currY + moveY
    end
end
