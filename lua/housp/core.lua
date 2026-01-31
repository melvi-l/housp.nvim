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

core.validate_format_argument = function(host, group, repo, branch, path, anchor)
    -- Validate strings
    local function is_valid_string(value)
        return type(value) == "string" and value ~= ""
    end

    return is_valid_string(host)
        and is_valid_string(group)
        and is_valid_string(repo)
        and is_valid_string(branch)
        and is_valid_string(path)
        and (not anchor or is_valid_string(anchor))
end

-- TODO(melvil): add support bitbucket (src/...#lines-) and native gitlab (/-/blob)
core.format_permalink = function(host, group, repo, branch, path, anchor)
    if not core.validate_format_argument(host, group, repo, branch, path, anchor) then
        return nil
    end
    return string.format(
        "https://%s/%s/%s/blob/%s/%s%s",
        host,
        group,
        repo,
        branch,
        path,
        anchor or ""
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
