# Housp
*short version of "houspiller", french for "to reprimand/to scold".*

Allow you to always be one keybind aways to generate a Github/Gitlab permalink for the exact file, branch and line in your buffer.
Perfect to send rage slack message to your colleagues. 

## Features

- `copy_permalink`: Generate an allegedly valid permalink to your git remote based on the repository context.
```
https://github.com/thevi-l/housp.nvim/blob/main/README.md#L9
```
- `open_permalink`: Open the current file in your browser (wsl compatible). 
- `setup_permalink`: Open a neovim buffer on the corresponding file at the correct revision and line according to a git remote url. 
- `copy_snippet`: Copy a snippet (with lang) containing the visual selected text and the relevant permalink.    
````
https://github.com/thevi-l/housp.nvim/blob/main/README.md#L13-L13
```md
- `copy_snippet`: Copy a snippet containing 
```
````

## Installation

### Native package manager (neovim nightly)
```lua
vim.pack.add({ 
    { src = "https://github.com/melvi-l/housp.nvim" }
})

local housp = require "housp"
vim.keymap.set({ "n", "v" }, "<leader>cp", housp.copy_permalink({}), { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>op", housp.open_permalink({}), { noremap = true, silent = true })
vim.keymap.set("v", "<leader>sp", housp.copy_snippet({ should_dedent = true, has_langage = true, has_permalink = true }), { noremap = true, silent = true })
vim.keymap.set("n", "<leader>of", function() 
    vim.ui.input({ prompt = "Git URL: " }, housp.setup_permalink({}))
end, { noremap = true, silent = true }) -- args default to system clipboard register
```

### Lazy (allegedly)
```lua
return {
    "melvi-l/housp.nvim",
    config = function()
        local housp = require("housp")

        vim.keymap.set({ "n", "v" }, "<leader>cp", housp.copy_permalink({}), { noremap = true, silent = true })
        vim.keymap.set({ "n", "v" }, "<leader>op", housp.open_permalink({}), { noremap = true, silent = true })
        vim.keymap.set("v", "<leader>sp", housp.copy_snippet({ should_dedent = true, has_langage = true, has_permalink = true }), { noremap = true, silent = true })
        vim.keymap.set("n", "<leader>of", function() 
            vim.ui.input({ prompt = "Git URL: " }, housp.setup_permalink({}))
        end, { noremap = true, silent = true }) -- args default to system clipboard register
    end,
}
```

## TODO
 
- [ ] improve `copy_snippet` to escape backtick *(test if at least triple backtick then use quadruple backtick)*
- [ ] change the permalink according to origin url

## Disclaimer

First neovim plugin so maybe trash, to lazy to document it more.
