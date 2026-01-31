local core = require "housp.core"

local function format_location(repo, branch, rel, anchor)
    return string.format("[%s](%s) %s at line %s", repo, branch, rel, anchor)
end

local function open_browser(url)
    if vim.fn.has("wsl") == 1 then
        vim.fn.jobstart({ "cmd.exe", "/c", "start", url }, { detach = true })
    elseif vim.fn.executable("xdg-open") == 1 then
        vim.fn.jobstart({ "xdg-open", url }, { detach = true })
    end
end

local function get_visual_range()
    local mode = vim.fn.mode()
    if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
        return nil
    end

    vim.cmd([[ execute "normal! \<ESC>" ]])
    local start_pos = vim.fn.getcharpos("'<")
    local end_pos = vim.fn.getcharpos("'>")
    vim.cmd([[ execute "normal! gv" ]])

    return {
        start_line = start_pos[2],
        start_col = start_pos[3],
        end_line = end_pos[2],
        end_col = end_pos[3],
        mode = mode
    }
end

local function get_lines_anchor()
    local visual = get_visual_range()

    if visual then
        if visual.mode == "v" then
            return string.format("#L%dC%d-L%dC%d",
                visual.start_line,
                visual.start_col,
                visual.end_line,
                visual.end_col
            )
        else -- V or \22
            return string.format("#L%d-L%d",
                visual.start_line,
                visual.end_line
            )
        end
    else
        return "#L" .. vim.api.nvim_win_get_cursor(0)[1]
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
    local rel = file:sub(#root + 2)

    local anchor = get_lines_anchor()

    local url = core.format_permalink(host, group, repo, branch, rel, anchor)

    return url, repo, branch, rel, anchor
end

local function setup_buffer(ref, path, line)
    vim.fn.system({
        "git", "checkout", ref
    })

    vimecmd("edit " .. vim.fn.fnameescape(path))

    if line then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
    end
end

return {
    copy_permalink = function()
        local url, repo, branch, rel, anchor = make_permalink()
        if not url then
            return vim.notify("Unable to create permalink from current location.", vim.log.levels.ERROR)
        end

        vim.fn.setreg("+", url)
        vim.notify("Copied " .. format_location(repo, branch, rel, anchor), vim.log.levels.INFO)
    end,
    open_permalink = function()
        local url, repo, branch, rel, anchor = make_permalink()
        if not url then
            return vim.notify("Unable to open permalink in browser from current location.", vim.log.levels.ERROR)
        end

        open_browser(url)
        vim.notify("Opened " .. format_location(repo, branch, rel, anchor) .. " in browser", vim.log.levels.INFO)
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
