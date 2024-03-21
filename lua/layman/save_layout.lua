local log = require("layman.utils.log").log
local f = string.format

local M = {}

local function match(win1, win2)
    if(win1.x == win2.x and win1.width == win2.width) then
        return true
    end
    if (win1.y == win2.y and win1.height == win2.height) then
        return true
    end
    return false
end

local function merge(old_win, new_win)
    local res = nil
    if(old_win.x == new_win.x and old_win.width == new_win.width) then
        res = vim.deepcopy(old_win)
        res.height = old_win.height + new_win.height + 1 -- NOTE: 1 for the window separator
        res.split = "unknown"
        res.method = "split"
        res.meta = {old_win.height, new_win.height}
        res.childs = {vim.deepcopy(old_win), vim.deepcopy(new_win)}
        res.isleaf = false
        res.winnr = f("%s,%s", old_win.winnr, new_win.winnr)
    end
    if (old_win.y == new_win.y and old_win.height == new_win.height) then
        res = vim.deepcopy(old_win)
        res.width = old_win.width + new_win.width + 1
        res.split = "unknown"
        res.method = "vsplit"
        res.meta = {old_win.width, new_win.width}
        res.childs = {vim.deepcopy(old_win), vim.deepcopy(new_win)}
        res.winnr = f("%s,%s", old_win.winnr, new_win.winnr)
        res.isleaf = false
    end
    return res
end


local dfs_print_tree
dfs_print_tree = function(node)
    print(f("win: %s", node.winnr))
    if(not node.isleaf) then
        print(f("split into: %s and %s",node.childs[1].winnr, node.childs[2].winnr))
        for _, c in ipairs(node.childs) do
            dfs_print_tree(c)
        end
    else
        print("leaf")
    end
end

local function build_layout_tree(data)
    local stk = require("layman.utils.stack"):new()
    for _,win in ipairs(data) do
        -- vim.print(f("current: %d %s", i, vim.inspect(stk.items)))
        while(not stk:empty() and match(win, stk:top())) do
            local old_win = stk:top()
            stk:pop()
            local res = merge(old_win, win)
            if res == nil then
                -- print(f("fail %d %d", win.winnr, win2.winnr))
                break
            else
                -- print(f("success merge %d %d to %d", win.winnr, win2.winnr, res.winnr))
                win = res
            end
        end
        stk:push(win)
    end
    assert(stk:size() == 1, "stk size error")
    local root = stk:top()
    stk:pop()
    return root
end

function M.get_layout()
    local current_winId = vim.api.nvim_get_current_win()
    local windows = vim.api.nvim_tabpage_list_wins(0)
    local wins = {}
    for _, winId in ipairs(windows) do
        local pos = vim.api.nvim_win_get_position(winId)
        local winnr = vim.api.nvim_win_get_number(winId)
        local current = false
        if(current_winId == winId) then
            current = true
        end
        local bufnr = vim.api.nvim_win_get_buf(winId)
        local file = vim.api.nvim_buf_get_name(bufnr)
        local cursor = vim.api.nvim_win_get_cursor(winId)
        local config = vim.api.nvim_win_get_config(winId)
        config = vim.tbl_deep_extend("force", config, {winnr = winnr, x = pos[2], y = pos[1], isleaf = true, file = file, cursor = cursor, current = current})
        if(config.focusable and config.relative == "") then
            table.insert(wins, config)
        end
    end

    table.sort(wins, function(a, b) return a.winnr < b.winnr end)
    local tree = build_layout_tree(wins)

    return {
        data = wins,
        tree = tree,
        print = function()
            dfs_print_tree(tree)
        end
    }
end

return M
