# Motivation
Sometimes there will be multiple splits opened. 

With this plugin, the window layout in neovim will be managed automatically.

Save your time to recover your favorite layout by `SaveLayout/RestoreLayout`.

# Usage
## commands
`SaveLayout`: record the current layout

`RestoreLayout`: restore your saved layout

`LastLayout`: go back to the last layout

## keymaps
Default keymap:

`<leader>ws` -> `SaveLayout`

`<leader>wr` -> `RestoreLayout`

`<leader>wl` -> `LastLayout`

You can customize it by:
```lua
  require("layman").setup({
    keymap = {
      last = "<C-w>l", -- change it to whatever you like
      save = "<C-w>s", -- change it to whatever you like
      restore = "<C-w>r", -- change it to whatever you like
    }
  })
```
