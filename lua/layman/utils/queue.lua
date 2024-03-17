-- Define a module for the queue
local Queue = {}

-- Constructor for creating a new Queue instance
function Queue:new()
    local instance = {
        items = {},
        head = 1,
        back = 0
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

-- Method to enqueue an item into the queue
function Queue:push(item)
    self.back = self.back + 1
    self.items[self.back] = item
end

-- Method to dequeue an item from the queue
function Queue:pop()
    if self:empty() then
        error("Queue is empty")
    end
    local value = self.items[self.head]
    self.items[self.head] = nil -- Clear the value at the front
    self.head = self.head + 1
    return value
end

-- Method to peek at the front item of the queue without removing it
function Queue:front()
    if self:empty() then
        return nil -- Or error("Queue is empty"), depending on your preference
    end
    return self.items[self.head]
end

-- Method to check if the queue is empty
function Queue:empty()
    return self.head > self.back
end

-- Method to get the size of the queue
function Queue:size()
    return self.back - self.head + 1
end

-- Test the Queue implementation
-- local myQueue = Queue:new()
-- myQueue:push(1)
-- myQueue:push(2)
-- myQueue:push(3)
-- print(myQueue:pop()) -- Outputs: Lua
-- print(myQueue:front())    -- Outputs: is
-- print(myQueue:pop())    -- Outputs: 2
-- print(myQueue:front())    -- Outputs: 2

return Queue
