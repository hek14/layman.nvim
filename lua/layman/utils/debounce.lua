local timer = nil
local delay = 100
local called = 0
local debounce = function(func)
    return function() -- A wrapper
        if(timer) then
            vim.uv.timer_stop(timer)
            timer = nil
        end

        timer = vim.uv.new_timer()
        timer:start(delay, 0, vim.schedule_wrap(function()
            func()
            if timer then
              timer:stop()
              timer:close()
              timer = nil
            end
        end))
    end
end

local hello = debounce(function()
    called = called + 1
    print(string.format("hello %d", called))
end)

local test = function()
    hello()
    hello()
    hello()
    hello()
    hello()
    hello()
    hello()
    hello()

    vim.defer_fn(function()
        hello()
        hello()
        hello()
        hello()
    end, 5 * delay)
end

-- Test:
-- test()
return {
    debounce = debounce,
    test = test
}
