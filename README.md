# Housp
*short version of "houspiller", french for "to reprimand/to scold".*

Allow you to always be one keybind aways to generate a Github/Gitlab permalink for the exact file, branch and line in your buffer.
Perfect to send rage slack message to your college. 

## Features

- `copy_permalink`: Generate an alledgdly valid permalink to your git remote based on the repository context.
- `open_permalink`: Open the current file in your browser (wsl compatible). 
- `setup_permalink`: Open a neovim buffer on the corresponding file at the correct revision and line according to a git remote url. 

## Installation

### Native package manager (neovim nightly)
```lua
vim.pack.add({ 
    { src = "https://github.com/melvi-l/housp.nvim" }
})

local housp = require "housp"
keymap("n", "<leader>cp", housp.copy_permalink)
keymap("n", "<leader>op", housp.open_permalink)
keymap("n", "<leader>of", function() vim.ui.input({ prompt = "Git URL: " }, housp.setup_permalink) end)
```

### Lazy (alledgdly)
```lua
{
    "melvi-l/housp.nvim",
    config = function()
        local housp = require("housp")

        vim.keymap.set("n", "<leader>cp", housp.copy_permalink)
        vim.keymap.set("n", "<leader>op", housp.open_permalink)
        vim.keymap.set("n", "<leader>of", function()
          vim.ui.input({ prompt = "Git URL: " }, housp.setup_permalink) 
        end)
    end,
}
```

## Disclaimer 

First neovim plugin so maybe trash, to lazy to document it more.
