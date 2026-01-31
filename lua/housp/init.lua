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

local function get_line_info()
    local mode = vim.fn.mode()

    vim.cmd([[ execute "normal! \<ESC>" ]])
    local start_pos = vim.fn.getcharpos("'<")
    local end_pos = vim.fn.getcharpos("'>")
    vim.cmd([[ execute "normal! gv" ]])

    if mode == "v" then
        return {
            mode = "selection",
            start_line = start_pos[2],
            start_col = start_pos[3],
            end_line = end_pos[2],
            end_col = end_pos[3],
        }
    end

    if mode == "V" or mode == "\22" then
        return {
            mode = "multilines",
            start_line = start_pos[2],
            end_line = end_pos[2],
        }
    end

    return {
        mode = "line",
        start_line = vim.api.nvim_win_get_cursor(0)[1]
    }
end

local function get_info()
    local res = {}
    res.file = vim.fn.expand("%:p")
    if not res.file or res.file == "" then return nil, "unable to get file name" end

    res.ext = vim.fn.expand("%:e") or ""

    res.dir = vim.fn.fnamemodify(res.file, ":h")
    if not res.dir or res.dir == "" then return nil, "unable to get parent folder" end


    res.root = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(res.dir) .. " rev-parse --show-toplevel"
    )[1]
    if not res.root or res.root == "" then return nil, "unable to get git root project" end

    res.origin = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(res.dir) .. " remote get-url origin"
    )[1]
    if not res.origin or res.origin == "" then return nil, "unable to get git origin" end

    res.branch = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(res.dir) .. " branch --show-current"
    )[1]
    if not res.branch or res.branch == "" then return nil, "unable to get git branch" end

    res.host, res.group, res.repo = core.extract_from_origin(res.origin)
    if not res.host or not res.group or not res.repo then
        return nil,
            "unable to extract host, group and repo from origin"
    end

    res.path = res.file:sub(#(res.root) + 2)

    res.line = get_line_info()

    return res, nil
end

local function get_visual_text(line_info, should_dedent)
    local bufnr = 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_info.start_line - 1, line_info.end_line, false)
    if #lines == 0 then
        return nil, nil, "unable to get visual text"
    end

    local indent
    if should_dedent then
        local min_indent = nil
        for _, line in ipairs(lines) do
            if line:match("%S") then
                local indent = line:match("^(%s*)")
                local len = #indent
                if not min_indent or len < min_indent then
                    min_indent = len
                end
            end
        end
        indent = min_indent or 0

        if line_info.mode == "selection" then
            local offset = math.max(0, line_info.start_col - indent)
            lines[1] = string.rep(" ", offset)
                .. string.sub(lines[1], line_info.start_col)

            for i = 2, #lines - 1 do
                lines[i] = lines[i]:sub(indent + 1)
            end

            lines[#lines] = string.sub(lines[#lines], indent + 1, line_info.end_col)

            return lines
        end

        for i = 1, #lines do
            lines[i] = lines[i]:sub(indent + 1)
        end

        return lines
    end

    if line_info.mode == "selection" then
        lines[1] = string.sub(lines[1], line_info.start_col)
        lines[#lines] = string.sub(lines[#lines], 1, line_info.end_col)
    end

    return lines
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
        local info, err = get_info()
        if not info then return vim.notify(err, vim.log.levels.ERROR) end

        local url = core.format_permalink(info)
        if not url then
            return vim.notify("Unable to create permalink from current location information.",
                vim.log.levels.ERROR)
        end

        vim.fn.setreg("+", url)
        vim.notify("Copied " .. format_location(info.repo, info.branch, info.path, info.line.start_line),
            vim.log.levels.INFO)
    end,
    copy_snippet = function(opts)
        opts.should_dedent = opts.should_dedent ~= false
        opts.has_langage = opts.has_langage ~= false
        opts.has_permalink = opts.has_permalink ~= false
        return function()
            local info, err = get_info()
            if not info then return vim.notify(err, vim.log.levels.ERROR) end

            local lines = { "```" .. (opts.has_langage and info.ext or "") }
            local visual_text
            visual_text, err = get_visual_text(info.line, opts.should_dedent)
            if not visual_text then return vim.notify(err, vim.log.levels.ERROR) end

            lines = table.move(visual_text, 1, #visual_text, #lines + 1, lines)

            table.insert(lines, "```")

            if opts.has_permalink then
                local url = core.format_permalink(info)
                if not url then
                    return vim.notify("Unable to create permalink from current location information.",
                        vim.log.levels.ERROR)
                end

                table.insert(lines, url)
            end

            vim.fn.setreg("+", table.concat(lines, "\n"))
            vim.notify("Copied selected snippet to clipboard", vim.log.levels.INFO)
        end
    end,
    open_permalink = function()
        local info, err = get_info()
        if not info then return vim.notify(err, vim.log.levels.ERROR) end

        local url = core.format_permalink(info)
        if not url then
            return vim.notify("Unable to create permalink from current location information.",
                vim.log.levels.ERROR)
        end

        open_browser(url)
        vim.notify(
            "Opened " .. format_location(info.repo, info.branch, info.path, info.line.start_line) .. " in browser",
            vim.log.levels.INFO)
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
