local log_path = vim.fn.stdpath("cache") .. "/layout_debug.log"
local log = function (...)
  local start = vim.loop.hrtime()
  local str = "שׁ "
  local lineinfo = ''

  local info = debug.getinfo(2, "Sl")
  lineinfo = info.short_src .. ":" .. info.currentline
  local date = os.date()
  str = str .. date .. ", " .. str .. lineinfo .. '\n'
  local arg = {...}
  vim.schedule(function()
    for i, v in ipairs(arg) do
      if type(v) == "table" then
        str = str .. " |" .. tostring(i) .. ": " .. vim.inspect(v) .. "\n"
      else
        str = str .. " |" .. tostring(i) .. ": " .. tostring(v)
      end
    end
    if #str > 2 then
      if log_path ~= nil and #log_path > 3 then
        local f = io.open(log_path, "a+")
        ---@diagnostic disable-next-line: unused-local, param-type-mismatch
        io.output(f)
        io.write(str .. "=======\n")
        io.close(f)
      else
        print(str .. "\n")
      end
    end
  end)
end 

return {
  log = log
}
