local layout_manager = {
  layouts = require("layman.utils.lru"):new(),
  saved_layout = {},
}

function layout_manager.setup(opt)
  -- TODO: support some customation maybe?
  vim.api.nvim_create_user_command('SaveLayout',function()
    print("Sa")
    layout_manager.saved_layout = require("layman.save_layout").get_layout()
  end, { nargs = '*', bang = true,  desc = 'Run session manager command' })

  vim.api.nvim_create_user_command('RestoreLayout',function()
    print("Re")
    require("layman.restore_layout").restore(layout_manager.saved_layout)
  end, { nargs = '*', bang = true,  desc = 'Run session manager command' })

end

return layout_manager
