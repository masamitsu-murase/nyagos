if not nyagos then
    print("This is a script for nyagos not lua.exe")
    os.exit()
end


local is_key = function(ch, key)
    local c = string.lower(string.char(ch))
    if c == key or ch == bit32.band(string.byte(key), 0x1F) then
        return true
    else
        return false
    end
end

local get_git_list = function()
    local git_list = {}
    local fd = io.popen(share.gitpath .. ' for-each-ref  --format="%(refname:short)" refs/heads/ 2> nul', 'r')
    if not fd then
        return {}
    end

    for line in fd:lines() do
        git_list[#git_list+1] = line 
    end
    fd:close()

    fd = io.popen(share.gitpath .. ' log --pretty="format:%h %s" -n 15')
    if not fd then
        return {}
    end

    for line in fd:lines() do
        git_list[#git_list+1] = line 
    end
    fd:close()

    return git_list
end

nyagos.key.C_x = function(this)
    nyagos.write("\nC-x: [s]:svn-revision, [H]:cd-history, [g]:git-revision\n")
    local ch = nyagos.getkey()
    local result
    if is_key(ch, 'h') then
        result = nyagos.eval('cd --history | box')
        if result ~= nil and result ~= "" and nyagos.getwd() ~= result then
            if string.find(result,' ') then
                result = '"'..result..'"'
            end
            nyagos.exec("cd " .. result)
        end
        result = nil
    elseif is_key(ch, 'g') then
        if VcsInfo.check_repository_type() == "git" then
            local git_list = get_git_list()
            result = nyagos.box(git_list) or ""
            result = string.match(result,"^%S+") or ""
        end
    elseif is_key(ch, 's') then
        if VcsInfo.check_repository_type() == "svn" then
            local path = VcsInfo.find_svn_path(this.text)
            result = VcsInfo.box_svn_revisions(path)
        end
    end
    this:call("REPAINT_ON_NEWLINE")
    return result
end
