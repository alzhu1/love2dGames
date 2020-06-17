-- Init dimensions of window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- Font size
FONT_SIZE = 20

-- Size of squares (snake head, body, and food)
SQUARE_SIZE = 10

-- Radius of the food (circle)
FOOD_RADIUS = 5

-- Speed
SNAKE_SPEED = 160

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
    love.window.setTitle('Snake')
    love.graphics.setFont(love.graphics.newFont(FONT_SIZE))

    -- Set seed of RNG for randomized square positions
    math.randomseed(os.time())

    -- Set gameState to beginning state
    gameState = "start"

    -- Initialize snake
    -- TODO: create a Snake class?
    snake = {
        head = {
            direction = "right",
            x = math.random() * (WINDOW_WIDTH - SQUARE_SIZE),
            y = math.random() * (WINDOW_HEIGHT - SQUARE_SIZE)
        },
        body = {}
    }

    -- TOREMOVE: Test with a default body
    -- turns queue: items should contain a turnDir, turnX, and turnY
    for i=1, 15 do
        snake.body[i] = {
            direction = "right",
            x = snake.head.x - (i * SQUARE_SIZE),
            y = snake.head.y,
            turns = {first = 1, last = 0}
        }
    end

    -- Keep a mapping from direction to valid key presses
    currDirToKeyMap = {
        up = {"left", "right"},
        down = {"left", "right"},
        right = {"up", "down"},
        left = {"up", "down"}
    }

    -- Other keys not in map default to empty list
    setmetatable(currDirToKeyMap, {__index = function() return {} end })

    -- Keep a cooldown for turning again
    turnCooldown = 0

    -- Keep track of current food location
    food = {
        x = math.random() * (WINDOW_WIDTH - FOOD_RADIUS),
        y = math.random() * (WINDOW_HEIGHT - FOOD_RADIUS)
    }
end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    movePiece(0, dt)
    for i, bodyPart in ipairs(snake.body) do
        movePiece(i, dt)
    end

    -- Check collisions and eat food after moving

    eatFood()
end

--[[
    Callback used when key is pressed

    key - the key code pressed
    scancode - seems to be the same as key for the most part (?)
    isrepeat - true if key is repeating
]]
function love.keypressed(key, scancode, isrepeat)
    -- Get the valid keys when moving in a direction
    local validKeys = currDirToKeyMap[snake.head.direction]
    for _, validKey in ipairs(validKeys) do
        if key == validKey and turnCooldown == 0 then
            -- Switch direction of head, add a "turn" to each body part queue
            snake.head.direction = key
            for i, bodyPart in ipairs(snake.body) do
                local last = bodyPart.turns.last + 1
                bodyPart.turns.last = last
                bodyPart.turns[last] = {
                    turnDir = key,
                    turnX = snake.head.x,
                    turnY = snake.head.y
                }
            end

            -- Set the turn cooldown, only allow turns after clearing a square
            turnCooldown = SQUARE_SIZE
            return
        end
    end
end

--[[
    Render graphics
]]
function love.draw()
    -- Draw head
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", snake.head.x, snake.head.y, SQUARE_SIZE, SQUARE_SIZE)

    -- Draw body
    for i, bodyPart in ipairs(snake.body) do
        love.graphics.rectangle("fill", bodyPart.x, bodyPart.y, SQUARE_SIZE, SQUARE_SIZE)
    end

    -- Get the turns of the last body part and color them white (illusion of filled snake)
    local lastBodyPart = snake.body[#snake.body]
    local first, last = lastBodyPart.turns.first, lastBodyPart.turns.last
    for i=first, last do
        local currTurn = lastBodyPart.turns[i]
        love.graphics.rectangle("fill", currTurn.turnX, currTurn.turnY, SQUARE_SIZE, SQUARE_SIZE)
    end

    -- Draw food
    love.graphics.setColor(255, 0, 0)
    love.graphics.circle("fill", food.x, food.y, FOOD_RADIUS)
end

--[[
    Move each piece of the snake

    index - index of the body part, 0 if head
    dt - amount of time (in sec) passed per frame
]]
function movePiece(index, dt)
    local piece = ((index == 0) and snake.head) or snake.body[index]
    local moveX, moveY = 0, 0
    local direction = piece.direction
    if direction == "left" then
        moveX = -SNAKE_SPEED * dt
    elseif direction == "right" then
        moveX = SNAKE_SPEED * dt
    end

    if direction == "up" then
        moveY = -SNAKE_SPEED * dt
    elseif direction == "down" then
        moveY = SNAKE_SPEED * dt
    end

    -- Move normally if it's the head or no turns required
    if index == 0 or piece.turns.first > piece.turns.last then
        piece.x = piece.x + moveX
        piece.y = piece.y + moveY

        -- Subtract from turnCooldown if it's still in effect
        turnCooldown = ((turnCooldown > 0) and turnCooldown - (SNAKE_SPEED * dt)) or 0
    else
        -- Here, move the body part up to and past the turn

        -- TODO: refactor
        local first = piece.turns.first
        local turnDir = piece.turns[first].turnDir

        -- Based on turnDir, move this piece's x and y to behind the next neighbor
        local nextPiece = ((index == 1) and snake.head) or snake.body[index - 1]

        -- Vertical then turncase
        if moveX == 0 then
            if direction == "up" and piece.y + moveY < piece.turns[first].turnY then

                if turnDir == "right" then
                    piece.x = nextPiece.x - SQUARE_SIZE
                    piece.y = nextPiece.y
                elseif turnDir == "left" then
                    piece.x = nextPiece.x + SQUARE_SIZE
                    piece.y = nextPiece.y
                end

                -- Remove from queue
                piece.turns[first] = nil
                piece.turns.first = first + 1

                -- Switch dir
                piece.direction = turnDir
            elseif direction == "down" and piece.y + moveY > piece.turns[first].turnY then
                if turnDir == "right" then
                    piece.x = nextPiece.x - SQUARE_SIZE
                    piece.y = nextPiece.y
                elseif turnDir == "left" then
                    piece.x = nextPiece.x + SQUARE_SIZE
                    piece.y = nextPiece.y
                end

                -- Remove from queue
                piece.turns[first] = nil
                piece.turns.first = first + 1

                -- Switch dir
                piece.direction = turnDir
            else
                -- Move as normally
                piece.y = piece.y + moveY
            end
        end

        -- Horizontal then turn case
        if moveY == 0 then
            if direction == "left" and piece.x + moveX < piece.turns[first].turnX then

                if turnDir == "down" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y - SQUARE_SIZE
                elseif turnDir == "up" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y + SQUARE_SIZE
                end

                -- Remove from queue
                piece.turns[first] = nil
                piece.turns.first = first + 1

                -- Switch dir
                piece.direction = turnDir
            elseif direction == "right" and piece.x + moveX > piece.turns[first].turnX then
                if turnDir == "down" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y - SQUARE_SIZE
                elseif turnDir == "up" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y + SQUARE_SIZE
                end

                -- Remove from queue
                piece.turns[first] = nil
                piece.turns.first = first + 1

                -- Switch dir
                piece.direction = turnDir
            else
                -- Move as normally
                piece.x = piece.x + moveX
            end
        end
    end
end

function eatFood()
    -- Check if head collides with center point of food circle
    local foodX, foodY = food.x, food.y
    local headX, headY = snake.head.x, snake.head.y

    local withinX = foodX > headX and foodX < headX + SQUARE_SIZE
    local withinY = foodY > headY and foodY < headY + SQUARE_SIZE
    if withinX and withinY then
        -- Add to body

        -- Randomize food to another location
        food.x = math.random() * (WINDOW_WIDTH - FOOD_RADIUS)
        food.y = math.random() * (WINDOW_HEIGHT - FOOD_RADIUS)
    end
end

