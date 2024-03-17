local log = require("core.utils").log
local f = string.format
local function match(win1, win2)
    if(win1.x == win2.x and win1.width == win2.width) then
        return true
    end
    if (win1.y == win2.y and win1.height == win2.height) then
        return true
    end
    return false
end

local function swapTables(t1, t2)
    return t2, t1
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

local function build_layout_tree(data, stk)
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
end


local function winnr_to_winid(winnr)
    local windows = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(windows) do
        if vim.api.nvim_win_get_number(winid) == winnr then
            return winid
        end
    end
    return nil
end

local dfs_print_tree
dfs_print_tree = function(win)
    print(f("win: %s", win.winnr))
    if(not win.isleaf) then
        for _, c in ipairs(win.childs) do
            dfs_print_tree(c)
        end
    end
end

local only_keep_first_winnr = function()
    local cur_win = winnr_to_winid(1)
    assert(cur_win)
    local wins = vim.api.nvim_list_wins()
    for _, window_id in ipairs(wins) do
        local config = vim.api.nvim_win_get_config(window_id)
        if(config.relative == "" and window_id ~= cur_win) then
            vim.api.nvim_win_close(window_id, true)
        end
    end
end

local bfs_layout_tree = function(root)

    only_keep_first_winnr()

    if(not root.childs) then
        print("only one window saved, no need to restore")
        return
    end

    local q = require("layman.utils.queue"):new()
    root.level = 1
    root.winid = vim.api.nvim_get_current_win()
    log(f("root winid: %d",root.winid))
    q:push(root)
    while(not q:empty()) do
        local t = q:front()
        q:pop()
        vim.api.nvim_set_current_win(t.winid)
        log(f("t winid: %d", t.winid))
        assert(t.childs and #t.childs > 0, "Error in queue!")
        local new_id = vim.api.nvim_open_win(0, false, {split = t.method == "vsplit" and "right" or "below", win = t.winid})
        local c1 = t.childs[1]
        c1.winid = t.winid
        c1.level = t.level + 1
        if(c1.childs) then
          q:push(c1)
        end

        local c2 = t.childs[2]
        c2.winid = new_id
        c2.level = t.level + 1

        log(f("c1 winid: %d, c2 winid: %d", c1.winid, c2.winid))
        if(c2.childs) then
          q:push(c2)
        end

        local ok, res = pcall(function()
            if t.method == "vsplit" then
                -- vim.api.nvim_win_set_config(c1.winid, {width = t.meta[1]}) -- NOTE: DO NOT USE nvim_win_set_config for split window!!!!!!!!! it's only for floating windows
                vim.api.nvim_win_set_width(c1.winid, t.meta[1]) -- NOTE: and set the original size is better than set the newly created window size
            else
                -- vim.api.nvim_win_set_config(c1.winid, {height = t.meta[1]})
                vim.api.nvim_win_set_height(c1.winid, t.meta[1])
            end
        end)
        if not ok then
            log(f("fail %d -> %d + %d error: %s", t.winid, c1.winid, c2.winid, res))
        else
            log(f("ok %d -> %d + %d", t.winid, c1.winid, c2.winid))
        end
    end
end

local function set_each_win(data)
    local final_win = nil
    for i = 1, #data do
        local winnr = i
        local winId = winnr_to_winid(winnr)
        assert(winId ~= nil)
        assert (data[i].winnr == winnr, f("%s vs %s", data[i].winnr, winnr))
        local file = data[i].file
        if(vim.fn.filereadable(file)) then
            local bufnr = vim.fn.bufadd(file) -- TODO:if the buffer does not attach to any file, like NvimTree, need to hand these
            vim.api.nvim_win_set_buf(winId, bufnr)
            vim.api.nvim_buf_set_option(bufnr, "buflisted", true)
        else
            local bufnr = vim.api.nvim_create_buf(true, true)
            vim.api.nvim_win_set_buf(winId, bufnr)
        end

        if(data[i].current) then
            final_win = winId
        end

        pcall(function() vim.api.nvim_win_set_cursor(winId, data[i].cursor) end)

    end
    assert(final_win, "final_win is nil!")
    vim.api.nvim_set_current_win(final_win)
end

local restore_layout = function(data)
    vim.g.layout_autocmd_enabled = false
    local filter_fn = function(e)
        return e.focusable and e.relative == ""
    end
    data = vim.tbl_filter(filter_fn, data)

    local stk = require("layman.utils.stack"):new()
    assert(stk:size() == 0, "should be a new stk")
    build_layout_tree(data, stk)
    assert(stk:size() == 1, "stk size error")
    local root = stk:top()
    stk:pop()
    -- log(f("root: %s, data: %s", vim.inspect(root), vim.inspect(data)))
    bfs_layout_tree(root)
    set_each_win(data)
    log("\n\n\n")
    vim.g.layout_autocmd_enabled = false
end

return {
    restore = restore_layout
}
