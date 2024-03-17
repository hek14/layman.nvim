local get_layout = require("layman.save_layout").get_layout
local set_layout = require("layman.restore_layout").restore
local debounce = require("layman.utils.debounce").debounce
local f = string.format
local log = require("layman.utils.log").log

-- TODO: how to handle buffer that don't have: close them at the begining of save_layout to ensure correct winnr, then restore them at the end. 

local layout_manager = {
  layouts = require("layman.utils.lru"):new(),
  saved_layout = {},
  autocmd_enabled = true,
}

local equal
equal = function(tree1, tree2)
  local check_keys = {"split", "method", "isleaf", "winnr", "file"}
  for _, k in ipairs(check_keys) do
    if(tree1[k]~=tree2[k]) then
      log(f("k: %s not equal", k))
      return false
    end
  end

  if(not tree1.childs and not tree2.childs) then
    return true

  else
    if(tree1.childs and tree2.childs) then
      if(#tree1.childs ~= #tree2.childs) then
        log(f("childs len not equal %d %d", #tree1.childs, #tree2.childs))
        return false
      end
      for i = 1,#tree1.childs do
        if(not equal(tree1.childs[i], tree2.childs[i])) then
          return false
        end
      end
      return true

    else
      log(f("structure not equal"))
      return false
    end
  end

end

function layout_manager.setup(opts)
  local default_opts = {
    keymap = {
      last = {"<leader>wl"},
      save = {"<leader>ws"},
      restore = {"<leader>wr"},
    }
  }

  opts = vim.tbl_deep_extend("force", opts or {}, default_opts)
  for _, v in pairs(opts.keymap) do
    if(not type(v) == "table") then
      opts.keymap.k = { v }
    end
  end
  vim.print(opts)

  -- commands
  vim.api.nvim_create_user_command('SaveLayout',function()
    local cur = get_layout()
    layout_manager.saved_layout = cur
    layout_manager.layouts:push(cur)
  end, { nargs = '*', bang = true,  desc = 'Run session manager command' })

  vim.api.nvim_create_user_command('RestoreLayout',function()
    local index = layout_manager.layouts:find(layout_manager.saved_layout)
    if(index == -1) then
      print("error lru:found!")
      return
    end
    layout_manager.layouts:visit(index)
    local last = layout_manager.layouts:front()
    set_layout(last)

  end, { nargs = '*', bang = true,  desc = 'Run session manager command' })

  vim.api.nvim_create_user_command('LastLayout', function()
    local count = vim.v.count
    count = count == 0 and 1 or count
    layout_manager.layouts:visit(count + 1) -- NOTE: move the last layout to head
    local last = layout_manager.layouts:front()
    set_layout(last)
  end, { nargs = '*', bang = true,  desc = 'Run session manager command' })

  local cur_layout = get_layout()
  layout_manager.layouts:push(cur_layout)

  -- autocmd
  local group = vim.api.nvim_create_augroup("layman", {clear = true})
  local counter = 0 -- for debug
  vim.api.nvim_create_autocmd({"WinNew", "WinClosed"}, {
    -- NOTE: why to debounce WinClosed, <C-w><C-o> will trigger multiple WinClosed...
    desc = "auto save current layout",
    group = group,
    callback = debounce(function(params)
      if(not layout_manager.autocmd_enabled) then
        return
      end

      local cur = get_layout()
      if(equal(cur.tree, layout_manager.layouts:front().tree)) then -- NOTE: only when split layout changed
        return
      end

      counter = counter + 1
      log(f("param: %s, cur.data: %s", vim.inspect(params), vim.inspect(cur.data)))
      layout_manager.layouts:push(cur)
    end)
  })

  -- keymap
  for _, key in ipairs(opts.keymap.last) do
    vim.keymap.set("n", key, "<cmd>LastLayout<cr>", { desc = "Go back to the last layout" })
  end
  for _, key in ipairs(opts.keymap.restore) do
    vim.keymap.set("n", key, "<cmd>RestoreLayout<cr>", { desc = "Restore the saved layout" })
  end
  for _, key in ipairs(opts.keymap.save) do
    vim.keymap.set("n", key, "<cmd>SaveLayout<cr>", { desc = "Save the current layout" })
  end

end

return layout_manager
