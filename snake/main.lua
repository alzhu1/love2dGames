-- Import Queue "class"
require 'Queue'

-- Init dimensions of window
WINDOW_WIDTH = 640
WINDOW_HEIGHT = 360

-- Font size
FONT_SIZE = 20

-- Size of squares (snake head, body, and food)
SQUARE_SIZE = 10

-- Radius of the food, and width of internal AABB
FOOD_RADIUS = SQUARE_SIZE / 2
FOOD_BOX_SIZE = 2 * FOOD_RADIUS / math.sqrt(2)

-- Speed
SNAKE_SPEED = 160

-- Set a spawn margin so things don't spawn at the very edges
SPAWN_MARGIN = 20

-- Number of times to attempt randomizing food location (to avoid body collision)
COLLISION_PASSES = 10

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
    gameState = "play"

    -- Initialize snake
    -- TODO: create a Snake class?
    snake = {
        head = {
            direction = "right",
            x = WINDOW_WIDTH / 2,
            y = WINDOW_HEIGHT / 2
        },
        body = {}
    }

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
    food = {}
    randomizeFoodLocation()
end

--[[
    Updates game every frame

    dt - amount of time (in sec) passed per frame
]]
function love.update(dt)
    if gameState == "play" then
        -- Check for direction change, acts as a "key buffer"
        local validKeys = currDirToKeyMap[snake.head.direction]
        for _, validKey in ipairs(validKeys) do
            if love.keyboard.isDown(validKey) and turnCooldown == 0 then
                -- Switch direction of head, add a "turn" to each body part queue
                snake.head.direction = validKey
                for i, bodyPart in ipairs(snake.body) do
                    local newTurn = {
                        turnDir = validKey,
                        turnX = snake.head.x,
                        turnY = snake.head.y
                    }
                    bodyPart.turns:enqueue(newTurn)
                end

                -- Set the turn cooldown, only allow turns after clearing a square
                turnCooldown = SQUARE_SIZE
                break
            end
        end

        -- Move segments
        movePiece(0, dt)
        for i, bodyPart in ipairs(snake.body) do
            movePiece(i, dt)
        end

        -- Wall collision ends game
        if checkWallCollision() then
            gameState = "gameover"
            return
        end

        -- Body collision will "eat" the body segments
        local collidedIndex = checkBodyCollision()
        if collidedIndex > 0 then
            -- "Eat" aka delete all body parts from index onwards
            local lastIndex = #snake.body
            for i=collidedIndex, lastIndex do
                snake.body[i] = nil
            end
        end

        -- Check if food should be eaten
        eatFood()
    end
end

--[[
    Render graphics
]]
function love.draw()
    -- Draw food
    love.graphics.setColor(255, 0, 0)
    love.graphics.circle("fill", food.x, food.y, FOOD_RADIUS)

    -- Draw head
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", snake.head.x, snake.head.y, SQUARE_SIZE, SQUARE_SIZE)

    -- Draw body
    for i, bodyPart in ipairs(snake.body) do
        love.graphics.rectangle("fill", bodyPart.x, bodyPart.y, SQUARE_SIZE, SQUARE_SIZE)
    end

    -- Get the turns of the last body part and color them white (illusion of filled snake)
    local lastIndex = #snake.body
    if lastIndex ~= 0 then
        local lastBodyPart = snake.body[lastIndex]
        local first, last = lastBodyPart.turns.first, lastBodyPart.turns.last
        for i=first, last do
            local currTurn = lastBodyPart.turns[i]
            love.graphics.rectangle("fill", currTurn.turnX, currTurn.turnY, SQUARE_SIZE, SQUARE_SIZE)
        end
    end

    -- If gameover, draw text
    if gameState == "gameover" then
        love.graphics.printf("Game over", 0, 50, WINDOW_WIDTH, "center")
    end
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
    if index == 0 or piece.turns:isEmpty() then
        piece.x = piece.x + moveX
        piece.y = piece.y + moveY

        -- Subtract from turnCooldown if it's still in effect
        turnCooldown = ((turnCooldown > 0) and turnCooldown - (SNAKE_SPEED * dt)) or 0
    else
        -- Here, move the body part up to and past the turn

        -- TODO: refactor
        local currTurn = piece.turns:peek()
        local turnDir, turnX, turnY = currTurn.turnDir, currTurn.turnX, currTurn.turnY

        -- Based on turnDir, move this piece's x and y to behind the next neighbor
        local nextPiece = ((index == 1) and snake.head) or snake.body[index - 1]

        -- Vertical then turncase
        if moveX == 0 then
            if direction == "up" and piece.y + moveY < turnY then

                if turnDir == "right" then
                    piece.x = nextPiece.x - SQUARE_SIZE
                    piece.y = nextPiece.y
                elseif turnDir == "left" then
                    piece.x = nextPiece.x + SQUARE_SIZE
                    piece.y = nextPiece.y
                end

                -- Remove from queue
                piece.turns:dequeue()

                -- Switch dir
                piece.direction = turnDir
            elseif direction == "down" and piece.y + moveY > turnY then
                if turnDir == "right" then
                    piece.x = nextPiece.x - SQUARE_SIZE
                    piece.y = nextPiece.y
                elseif turnDir == "left" then
                    piece.x = nextPiece.x + SQUARE_SIZE
                    piece.y = nextPiece.y
                end

                -- Remove from queue
                piece.turns:dequeue()

                -- Switch dir
                piece.direction = turnDir
            else
                -- Move as normally
                piece.y = piece.y + moveY
            end
        end

        -- Horizontal then turn case
        if moveY == 0 then
            if direction == "left" and piece.x + moveX < turnX then

                if turnDir == "down" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y - SQUARE_SIZE
                elseif turnDir == "up" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y + SQUARE_SIZE
                end

                -- Remove from queue
                piece.turns:dequeue()

                -- Switch dir
                piece.direction = turnDir
            elseif direction == "right" and piece.x + moveX > turnX then
                if turnDir == "down" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y - SQUARE_SIZE
                elseif turnDir == "up" then
                    piece.x = nextPiece.x
                    piece.y = nextPiece.y + SQUARE_SIZE
                end

                -- Remove from queue
                piece.turns:dequeue()

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
    -- Do a "faux" collision with invisible AABB inside the food
    local foodX, foodY = food.x - FOOD_BOX_SIZE / 2, food.y - FOOD_BOX_SIZE / 2

    if checkSquareCollision(snake.head, SQUARE_SIZE, {x = foodX, y = foodY}, FOOD_BOX_SIZE) then
        -- Add to body
        local lastIndex = #snake.body
        local lastBodyPart = ((lastIndex == 0) and snake.head) or snake.body[lastIndex]
        local direction, x, y = lastBodyPart.direction, lastBodyPart.x, lastBodyPart.y

        local newBodyPart = { direction = direction, turns = Queue:new() }

        if direction == "up" then
            newBodyPart.x = x
            newBodyPart.y = y + SQUARE_SIZE
        elseif direction == "right" then
            newBodyPart.x = x - SQUARE_SIZE
            newBodyPart.y = y
        elseif direction == "down" then
            newBodyPart.x = x
            newBodyPart.y = y - SQUARE_SIZE
        elseif direction == "left" then
            newBodyPart.x = x + SQUARE_SIZE
            newBodyPart.y = y
        end

        -- TODO: refactor/make more robust
        -- Copy lastBodyPart's turns to newBodyPart
        if lastIndex ~= 0 then
            for i=lastBodyPart.turns.first, lastBodyPart.turns.last do
                newBodyPart.turns:enqueue(lastBodyPart.turns[i])
            end
        end

        -- Depending on direction, change x or y accordingly
        snake.body[lastIndex+1] = newBodyPart

        -- Randomize food to another location
        randomizeFoodLocation()
    end
end

--[[
    Returns true if the snake head has collided with the walls
]]
function checkWallCollision()
    local headX, headY = snake.head.x, snake.head.y

    local xCollide = headX < 0 or headX + SQUARE_SIZE > WINDOW_WIDTH
    local yCollide = headY < 0 or headY + SQUARE_SIZE > WINDOW_HEIGHT
    return xCollide or yCollide
end

--[[
    Returns index of the body part that the head collides with (0 if no collision)
]]
function checkBodyCollision()
    -- Iterate through body, can ignore 1st body part (impossible to eat)
    for i, bodyPart in ipairs(snake.body) do
        if i > 1 then
            -- AABB collision check
            if checkSquareCollision(snake.head, SQUARE_SIZE, bodyPart, SQUARE_SIZE) then
                return i
            end
        end
    end

    -- No collisions returns index 0
    return 0
end

--[[
    Randomize food location to new position
]]
function randomizeFoodLocation()
    local tempX, tempY = 0, 0

    -- Make numerous passes if random position will collided with snake
    for i=1, COLLISION_PASSES do
        local partialMaxLimit = FOOD_RADIUS + (2 * SPAWN_MARGIN)
        tempX = math.random() * (WINDOW_WIDTH - partialMaxLimit) + SPAWN_MARGIN
        tempY = math.random() * (WINDOW_HEIGHT - partialMaxLimit) + SPAWN_MARGIN

        -- Set up temporary food collider
        local collided = false
        local foodCheck = {
            x = tempX - FOOD_BOX_SIZE / 2,
            y = tempY - FOOD_BOX_SIZE / 2
        }

        -- Check head/body collisions
        if checkSquareCollision(snake.head, SQUARE_SIZE, foodCheck, FOOD_BOX_SIZE) then
            collided = true
        else
            for _, bodyPart in ipairs(snake.body) do
                if checkSquareCollision(bodyPart, SQUARE_SIZE, foodCheck, FOOD_BOX_SIZE) then
                    collided = true
                    break
                end
            end
        end

        -- No collision means valid location
        if not collided then break end
    end

    food.x = tempX
    food.y = tempY
end

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
