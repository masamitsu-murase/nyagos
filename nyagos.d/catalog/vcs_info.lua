
VcsInfo = {}

VcsInfo.SVN_OPTION = "--non-interactive --config-option servers:global:http-timeout=5"

VcsInfo.check_repository_type = function(dir)
    dir = dir or nyagos.getwd()
    if not dir:find("^[a-zA-Z]:") then
        return nil
    end

    local dir_list = {}
    for item in dir:gmatch("[^\\/]+") do
        table.insert(dir_list, item)
    end

    local vcs_list = {"svn", "git"}
    while #dir_list > 0 do
        local path = table.concat(dir_list, "\\")
        for k, vcs in pairs(vcs_list) do
            if nyagos.stat(path .. "\\." .. vcs) then
                return vcs
            end
        end
        table.remove(dir_list)
    end
    return nil
end

VcsInfo.check_vcs_branch = function()
    local type = VcsInfo.check_repository_type()
    if type == "svn" then
        return "svn", VcsInfo.check_svn_branch()
    elseif type == "git" then
        return "git", VcsInfo.check_git_branch()
    else
        return nil
    end
end

VcsInfo.unescape_xml = function(xml_text)
    local conversion = {amp="&", lt="<", gt=">", quot="\"", apos="'"}
    return xml_text:gsub("&([a-z]+);", conversion)
end

VcsInfo.unescape_url = function(url)
    return url:gsub("%%([0-9a-fA-F][0-9a-fA-F])", function(s)
        return string.char(tonumber(s, 16))
    end)
end

VcsInfo.check_svn_branch = function(dir)
    local path = dir or "."
    local output = nyagos.eval(share.svnpath .. " info \"" .. path .. "\" --xml 2>&1")
    if output == nil then
        return nil
    end
    -- <wcroot-abspath>C:/work/git_repos/src/github.com/trunk</wcroot-abspath>
    local root = output:match("<wcroot%-abspath>(.-)</wcroot%-abspath>")
    if root == nil then
        return nil
    end

    local url = output:match("<url>(.-)</url>")
    if url == nil then
        return nil
    end

    local url_list = {}
    for i in url:gmatch("[^/\\]+") do
        table.insert(url_list, i)
    end

    local root_list = {}
    for i in root:gmatch("[^/\\]+") do
        table.insert(root_list, i)
    end

    local wd = dir or nyagos.getwd()
    local wd_list = {}
    for i in wd:gmatch("[^/\\]+") do
        table.insert(wd_list, i)
    end

    return VcsInfo.unescape_url(url_list[#url_list - (#wd_list - #root_list)])
end

VcsInfo.svn_completion = function(c, org_list, org_shownlist)
    local word = c.word
    if dollar_env_replace_env then
        word = dollar_env_replace_env(word)
    end
    local prefix_list = {"file://", "http://", "https://"}
    local match = false
    for i, pref in ipairs(prefix_list) do
        if word:sub(1, #pref) == pref then
            match = true
            break
        end
    end
    if not match then
        return org_list, org_shownlist
    end

    if c.word:match("/") == nil then
        return org_list, org_shownlist
    end

    local org_dir_url = c.word:sub(1, c.word:match(".*()/") - 1)
    local dir_url = word:sub(1, word:match(".*()/") - 1)
    local output = nyagos.eval(share.svnpath .. " ls \"" .. dir_url .. "\" --xml " .. VcsInfo.SVN_OPTION .. " 2>&1")
    org_list = {}
    org_shownlist = {}
    for kind, name in output:gmatch("<entry%s+kind=\"([a-z]-)\".-<name>(.-)</name>") do
        if kind == "dir" then
            table.insert(org_list, org_dir_url .. "/" .. name .. "/")
            table.insert(org_shownlist, name .. "/")
        elseif kind == "file" then
            table.insert(org_list, org_dir_url .. "/" .. name)
            table.insert(org_shownlist, name)
        end
    end
    table.sort(org_list)
    table.sort(org_shownlist)
    return org_list, org_shownlist
end

VcsInfo.get_svn_revisions = function(url, limit)
    local output = nyagos.eval(share.svnpath .. " log \"" .. url .. "\" --xml --limit " .. limit .. " " .. VcsInfo.SVN_OPTION .. " 2>&1")
    if not output:find("<logentry") then
        return nil
    end
    local logs = {}
    for rev, content in output:gmatch("<logentry%s+revision=\"([0-9]+)\".->(.-)</logentry>") do
        local author = VcsInfo.unescape_xml(content:match("<author>(.-)</author>"))
        local date = VcsInfo.unescape_xml(content:match("<date>(.-)</date>"))
        local msg = VcsInfo.unescape_xml(content:match("<msg>(.-)</msg>"))
        local log = {revision=rev, author=author, date=date, msg=msg}
        table.insert(logs, log)
    end
    return logs
end

VcsInfo.box_svn_revisions = function(path)
    local result = nil
    local logs = path and VcsInfo.get_svn_revisions(path, 100)
    if logs and #logs > 0 then
        local box_arg = {}
        for i, log in ipairs(logs) do
            table.insert(box_arg, log["revision"] .. " " .. log["author"]:sub(1, 10) .. ": " .. log["msg"]:gsub("%s+", " ") .. "\n")
        end
        local rev = nyagos.box(box_arg)
        result = rev and rev:match("^%S+")
    end
    return result
end

VcsInfo.find_svn_path = function(text)
    if dollar_env_replace_env then
        text = dollar_env_replace_env(text)
    end

    local parts = {}
    for i in text:gmatch("%S+") do
        table.insert(parts, i)
    end
    local path = nil
    for i = #parts, 1, -1 do
        if parts[i]:find("^https?://") then
            path = parts[i]
            break
        elseif parts[i]:find("^file://") then
            path = parts[i]
            break
        end
    end
    return path
end

VcsInfo.check_git_branch = function()
    local output = nyagos.eval(share.gitpath .. " rev-parse --abbrev-ref HEAD 2>&1")
    if output == nil or output:find("\n") then
        return nil
    end

    return output
end

share.org_vcs_info_completion_hook = nyagos.completion_hook
nyagos.completion_hook = function(c)
    local org_list = c.list
    local org_shownlist = c.shownlist
    if share.org_vcs_info_completion_hook then
        local l, s = share.org_vcs_info_completion_hook(c)
        if l ~= nil then
            org_list = l
            org_shownlist = l
        end
        if s ~= nil then
            org_shownlist = s
        end
    end

    local prefix = "svn "
    if c.text:sub(1, #prefix) == prefix then
        return VcsInfo.svn_completion(c, org_list, org_shownlist)
    end

    return org_list, org_shownlist
end
