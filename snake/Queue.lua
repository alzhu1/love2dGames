--[[
    Queue implementation taken from Programming in Lua 1st edition
]]

Queue = {}
Queue.__index = Queue -- Failed lookups go to Queue

--[[
    Constructor; creates a new queue object
]]
function Queue:new()
    local queue = { first = 1, last = 0 }

    -- Set object metatable to base Queue class, uses this for function lookup
    setmetatable(queue, Queue)
    return queue
end

--[[
    Add item to queue

    item - to put in queue
]]
function Queue:enqueue(item)
    -- Increment "last" index and insert value at index
    local last = self.last + 1
    self.last = last
    self[last] = item
end

--[[
    Remove item from queue

    return first item if found, nil if not
]]
function Queue:dequeue()
    -- Check if queue is empty
    if self:isEmpty() then
        return nil
    end

    -- Get reference to item to dequeue and remove/return
    local first = self.first
    local item = self[first]
    self[first] = nil
    self.first = first + 1
    return item
end

--[[
    Returns first item if found, nil if not
]]
function Queue:peek()
    -- Check if queue is empty
    if self:isEmpty() then
        return nil
    end

    -- Return the first element
    return self[self.first]
end

--[[
    Returns true if queue is empty
]]
function Queue:isEmpty()
    return self.first > self.last
end

--[[
    Returns queue size
]]
function Queue:size()
    return self.last - self.first + 1
end

