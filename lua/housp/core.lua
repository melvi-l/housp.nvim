local core = {}

core.extract_from_origin = function(origin)
    local host, path

    -- git@host:group/project.git
    host, path = origin:match("^git@([^:]+):(.+)$")

    -- ssh://git@host:port/group/project.git
    if not host then
        host, path = origin:match("^ssh://git@([^:/]+):%d+/(.+)$")
    end

    -- ssh://git@host/group/project.git
    if not host then
        host, path = origin:match("^ssh://git@([^/]+)/(.+)$")
    end

    -- https?://host/group/project.git
    if not host then
        host, path = origin:match("^https?://([^/]+)/(.+)$")
    end

    -- git://host/group/project.git
    if not host then
        host, path = origin:match("^git://([^/]+)/(.+)$")
    end

    if not host or not path then return nil end

    path = path:gsub("%.git$", "")

    local group, project = path:match("^(.*)/([^/]+)$")
    if not group or not project then return nil end

    return host, group, project
end

core.validate_format_argument = function(info)
    -- Validate strings
    local function is_valid_string(value)
        return type(value) == "string" and value ~= ""
    end

    return is_valid_string(info.host)
        and is_valid_string(info.group)
        and is_valid_string(info.repo)
        and is_valid_string(info.branch)
        and is_valid_string(info.path)
        and (not info.anchor or is_valid_string(info.anchor))
end


local function get_anchor(host, line_info)
    if host ~= "github.com" or line_info.mode == "line" then
        return "#L" .. line_info.start_line
    end

    if line_info.mode == "multilines" then
        return string.format("#L%d-L%d",
            line_info.start_line,
            line_info.end_line
        )
    end

    if line_info.mode == "selection" then
        return string.format("#L%dC%d-L%dC%d",
            line_info.start_line,
            line_info.start_col,
            line_info.end_line,
            line_info.end_col + 1 -- idk why
        )
    end

    return ""
end


-- TODO(melvil): add support bitbucket (src/...#lines-) and native gitlab (/-/blob)
core.format_permalink = function(info)
    if not core.validate_format_argument(info) then
        return nil
    end
    return string.format(
        "https://%s/%s/%s/blob/%s/%s%s",
        info.host,
        info.group,
        info.repo,
        info.branch,
        info.path,
        get_anchor(info.host, info.line)
    )
end

core.parse_permalink = function(url)
    if not url then return nil end

    local _, after_blob = url:find("/blob/")

    if not after_blob then return nil end

    local rest = url:sub(after_blob + 1)

    local ref, path = rest:match("^([^/]+)/(.+)$")
    if not ref or not path then return nil end

    local line
    path, line = path:match("^(.-)#L(%d+)$")

    return ref, path, tonumber(line)
end

return core
