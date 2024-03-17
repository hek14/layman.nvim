local Lru = {}
local f = string.format

function Lru:new()
  local instance = {
    l = {},
    r = {},
    head = 0,
    tail = 1,
    idx = 2,
    e = {},
    capacity = 10
  }
  instance.r[instance.head] = instance.tail
  instance.l[instance.tail] = instance.head
  setmetatable(instance, self)
  self.__index = self
  return instance
end


function Lru:delete_node(k)
  self.l[self.r[k]] = self.l[k]
  self.r[self.l[k]] = self.r[k]
end

function Lru:insert_at_right(j, k)
  -- insert k after j: j -> k -> r[j]
  self.r[k] = self.r[j]
  self.l[k] = j
  self.l[self.r[j]] = k
  self.r[j] = k
end

function Lru:insert_head(k)
  self:insert_at_right(self.head, k)
end

function Lru:move_to_head(k)
  self:delete_node(k)
  self:insert_head(k)
end

function Lru:push(v)
  if(self:size() >= self.capacity) then
    -- print("should delete the least used node")
    self:delete_node(self.l[self.tail])
  end

  self.e[self.idx] = v
  self:insert_head(self.idx)
  self.idx = self.idx + 1
end

function Lru:delete_data(v)
  local equal_fn = function(a, b)
    if(type(v) == 'table') then
      return vim.deep_equal(a, b)
    else
      return a == b
    end
  end
  local st = self.r[self.head]
  local k = nil
  while(st ~= self.tail) do
    if(equal_fn(v, self.e[st])) then
      k = st
      break
    else
      st = self.r[st]
    end
  end
  if(k) then
    self:delete_node(k)
  else
    -- vim.print("[LRU] delete_data: no data match")
  end
end

function Lru:iterate()
  local ans = {}
  local st = self.r[self.head]
  while(st ~= self.tail) do
    table.insert(ans, self.e[st])
    st = self.r[st]
  end
  return ans
end

function Lru:size()
  local st = self.r[self.head]
  local cnt = 0
  while(st ~= self.tail) do
    cnt = cnt + 1
    st = self.r[st]
  end
  return cnt
end

function Lru:find(item)
  local st = self.r[self.head]
  local cnt = 0
  while(st ~= self.tail) do
    cnt = cnt + 1
    if(vim.deep_equal(item, self.e[st])) then
      return cnt
    end
    st = self.r[st]
  end
  return -1
end

function Lru:visit(k)
  -- this k is not the internal idx!!! this is the kth node for iteration
  local cnt = 0
  local st = self.r[self.head]
  local found = false
  while(st ~= self.tail) do
    cnt = cnt + 1
    if(cnt == k) then
      self:move_to_head(st) -- NOTE: use internal idx st
      found = true
      break
    else
      st = self.r[st]
    end
  end

  if not found then
    self:move_to_head(self.l[self.tail]) -- NOTE: the input cnt is much larger than the size, then move the tail to the head because the user want to do that
  end
end

function Lru:front()
  return self.e[self.r[self.head]]
end

function Lru:pop()
  self:delete_node(self.r[self.head])
end

-- Test
-- local t = Lru:new()
-- t:push({winnr = 1, childs = {2, 3}})
-- t:push({winnr = 2, childs = {4, 5}})
-- t:push({winnr = 3, childs = {6, 7}})
-- t:push({winnr = 4, childs = {8}})
-- vim.print(t:iterate()) -- 4, 3, 2
--
-- print("--------------")
--
-- local v = {winnr = 1, childs = {2, 3}}
-- t:delete_data(v) -- 4, 3
--
-- t:visit(2) -- 3, 4
--
-- vim.print(t:iterate())

return Lru
