local Stack = {}

-- Constructor for creating a new Stack instance
function Stack:new()
    local instance = {items = {}}
    setmetatable(instance, self)
    self.__index = self
    return instance
end

-- Method to push an item onto the stack
function Stack:push(item)
    table.insert(self.items, item)
end

-- Method to pop an item off the stack
function Stack:pop()
    if #self.items == 0 then
        error("Stack is empty")
    end
    return table.remove(self.items)
end

-- Method to peek at the top item of the stack without removing it
function Stack:top()
    if #self.items == 0 then
        return nil -- Or error("Stack is empty"), depending on your preference
    end
    return self.items[#self.items]
end

-- Method to check if the stack is empty
function Stack:empty()
    return #self.items == 0
end

-- Method to get the size of the stack
function Stack:size()
    return #self.items
end

-- Test the Stack implementation
-- local myStack = Stack:new()
-- myStack:push("Lua")
-- myStack:push("is")
-- myStack:push("awesome")
-- print(myStack:pop())   -- Outputs: awesome
-- print(myStack:peek())  -- Outputs: is
-- print(myStack:size())  -- Outputs: 2

return Stack
