local core = require "housp.core"

local function format_location(repo, branch, rel, line)
    return string.format("[%s](%s) %s at line %d", repo, branch, rel, line)
end

local function open_browser(url)
    if vim.fn.has("wsl") == 1 then
        vim.fn.jobstart({ "cmd.exe", "/c", "start", url }, { detach = true })
    elseif vim.fn.executable("xdg-open") == 1 then
        vim.fn.jobstart({ "xdg-open", url }, { detach = true })
    end
end

local function make_permalink()
    local file = vim.fn.expand("%:p")
    if file == "" then return nil end

    local dir = vim.fn.fnamemodify(file, ":h")
    local root = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel"
    )[1]
    if not root or root == "" then return nil end

    local origin = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(dir) .. " remote get-url origin"
    )[1]
    if not origin or origin == "" then return nil end
    local host, group, repo = core.extract_from_origin(origin)
    if not host or not group or not repo then return nil end

    local branch = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(dir) .. " branch --show-current"
    )[1]
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local rel = file:sub(#root + 2)

    local url = core.format_permalink(host, group, repo, branch, rel, line)

    return url, repo, branch, rel, line
end

local function setup_buffer(ref, path, line)
    vim.fn.system({
        "git", "checkout", ref
    })

    vim.cmd("edit " .. vim.fn.fnameescape(path))

    if line then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
    end
end

return {
    copy_permalink = function()
        local url, repo, branch, rel, line = make_permalink()
        if not url then
            return vim.notify("Unable to create permalink from current location.", vim.log.levels.ERROR)
        end

        vim.fn.setreg("+", url)
        vim.notify("Copied " .. format_location(repo, branch, rel, line), vim.log.levels.INFO)
    end,
    open_permalink = function()
        local url, repo, branch, rel, line = make_permalink()
        if not url then
            return vim.notify("Unable to open permalink in browser from current location.", vim.log.levels.ERROR)
        end

        open_browser(url)
        vim.notify("Opened " .. format_location(repo, branch, rel, line) .. " in browser", vim.log.levels.INFO)
    end,
    setup_permalink = function(url)
        if not url or url == "" then url = vim.fn.getreg("+") end

        local ref, path, line = core.parse_permalink(url)
        if not ref or not path then
            return vim.notify("Unsupported Git URL", vim.log.levels.ERROR)
        end

        setup_buffer(ref, path, line)
    end
}
