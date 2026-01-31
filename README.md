# Housp
*short version of "houspiller", french for "to reprimand/to scold".*

Allow you to always be one keybind aways to generate a Github/Gitlab permalink for the exact file, branch and line in your buffer.
Perfect to send rage slack message to your college. 

## Features

- `copy_permalink`: Generate an allegedly valid permalink to your git remote based on the repository context.
- `open_permalink`: Open the current file in your browser (wsl compatible). 
- `setup_permalink`: Open a neovim buffer on the corresponding file at the correct revision and line according to a git remote url. 

## Installation

### Native package manager (neovim nightly)
```lua
vim.pack.add({ 
    { src = "https://github.com/melvi-l/housp.nvim" }
})

local housp = require "housp"
vim.keymap.set({ "n", "v" }, "<leader>cp", housp.copy_permalink({}), { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>op", housp.open_permalink({}), { noremap = true, silent = true })
vim.keymap.set("v", "<leader>sp", housp.copy_snippet({ should_dedent = true, has_langage = true, has_permalink = true }))
vim.keymap.set("n", "<leader>of", function() 
    vim.ui.input({ prompt = "Git URL: " }, housp.setup_permalink({}))
end, { noremap = true, silent = true }) -- args default to system clipboard register
```

### Lazy (allegedly)
```lua
{
    "melvi-l/housp.nvim",
    config = function()
        local housp = require("housp")

        vim.keymap.set({ "n", "v" }, "<leader>cp", housp.copy_permalink({}), { noremap = true, silent = true })
        vim.keymap.set({ "n", "v" }, "<leader>op", housp.open_permalink({}), { noremap = true, silent = true })
        vim.keymap.set("n", "<leader>of", function() 
            vim.ui.input({ prompt = "Git URL: " }, housp.setup_permalink({}))
        end, { noremap = true, silent = true }) -- args default to system clipboard register
    end,
}
```

## SIWTD (shit I want to do)
 
- [x] increase `copy_permalink` to allow character level selection `#L8C19-L21C39`.
- [x] discriminate character selection to only github
- [x] `copy_snippet`: copy the selected code to a three backtick markdown snippet, with langage. If in a repository, also give the git remote permalink.
- [ ] improve `copy_snippet` to escape backtick

## Disclaimer

First neovim plugin so maybe trash, to lazy to document it more.
