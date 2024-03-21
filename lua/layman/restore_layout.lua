local log = require("layman.utils.log").log
local f = string.format

local function winnr_to_winid(winnr)
    local windows = vim.api.nvim_tabpage_list_wins(0)
    for _, winid in ipairs(windows) do
        if vim.api.nvim_win_get_number(winid) == winnr then
            return winid
        end
    end
    return nil
end


local only_keep_first_winnr = function()
    local cur_win = nil
    local wins = vim.api.nvim_list_wins()
    for _, window_id in ipairs(wins) do
        local config = vim.api.nvim_win_get_config(window_id)
        if(not cur_win and config.relative == "") then
          cur_win = window_id
        end

        if(cur_win and window_id ~= cur_win) then
            vim.api.nvim_win_close(window_id, true)
        end
    end
end

local bfs_layout_tree = function(root)
    only_keep_first_winnr()
    if(not root.childs) then
        return
    end

    local q = require("layman.utils.queue"):new()
    root.level = 1
    root.winid = vim.api.nvim_get_current_win()
    -- log(f("root winid: %d",root.winid))
    q:push(root)
    while(not q:empty()) do
        local t = q:front()
        q:pop()
        vim.api.nvim_set_current_win(t.winid)
        -- log(f("t winid: %d", t.winid))
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

        -- log(f("c1 winid: %d, c2 winid: %d", c1.winid, c2.winid))
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
            -- log(f("ok %d -> %d + %d", t.winid, c1.winid, c2.winid))
        end
    end
end

local function set_each_win(data)
    local layout = require("layman.save_layout").get_layout()

    assert(#layout.data == #data, "Current layout not equal to target layout")
    local final_win = nil
    for i = 1, #data do
        local winnr = i
        local winId = winnr_to_winid(winnr)
        assert(winId ~= nil)
        assert (data[i].winnr == winnr, f("%s vs %s", data[i].winnr, winnr))
        if(data[i].current) then
            final_win = winId
        end
        local file = data[i].file
        if(vim.fn.filereadable(file)) then
            local bufnr = vim.fn.bufadd(file) -- TODO:if the buffer does not attach to any file, like NvimTree, need to hand these
            vim.api.nvim_win_set_buf(winId, bufnr)
            vim.api.nvim_buf_set_option(bufnr, "buflisted", true)
        else
            local bufnr = vim.api.nvim_create_buf(true, true)
            vim.api.nvim_win_set_buf(winId, bufnr)
        end

        pcall(function() vim.api.nvim_win_set_cursor(winId, data[i].cursor) end) -- NOTE:the cursor may be outside of the file

    end
    assert(final_win~=nil)
    vim.api.nvim_set_current_win(final_win)
end

local restore_layout = function(layout)
    local layman = require("layman")
    layman.autocmd_enabled = false

    bfs_layout_tree(layout.tree)
    set_each_win(layout.data)

    layman.autocmd_enabled = true
end

return {
    restore = restore_layout
}
