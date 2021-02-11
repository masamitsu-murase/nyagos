if not nyagos then
    print("This is a script for nyagos not lua.exe")
    os.exit()
end

if share.maincmds then
    return
end

share.maincmds = {}

local function get_local()
    local dir=nyagos.pathjoin(nyagos.env.LOCALAPPDATA,"NYAOS_ORG")
    local stat=nyagos.stat(dir)
    if not stat then
        nyagos.exec('mkdir "'..dir..'"')
    end
    return dir
end

local function load_subcommands_cache(fname)
    return nil
end

local function save_subcommands_cache(fname,list)
end

-- git

local function update_cache()
    share.maincmds["git"] = load_subcommands_cache("git-subcommands.txt")
    share.maincmds["hub"] = load_subcommands_cache("hub-subcommands.txt")
    if not share.maincmds["git"] then
        local githelp=io.popen(share.gitpath .. " help -a 2>nul","r")
        local hubhelp=nil
        if githelp then
            local gitcmds={ "update-git-for-windows" }
            local hub=false
            if hubhelp then
              hub=true
              local startflag = false
              local found=false
              for line in hubhelp:lines() do
                if not found then
                  if startflag then
                    -- skip blank line
                    if string.match(line,"%S") then
                      -- found commands
                      for word in string.gmatch(line, "%S+") do
                        gitcmds[ #gitcmds+1 ] = word
                      end
                      found = true
                    end
                  end
                  if string.match(line,"hub custom") then
                    startflag = true
                  end
                end
              end
              hubhelp:close()
            end
            for line in githelp:lines() do
                local word = string.match(line,"^ +(%S+)")
                if nil ~= word then
                  gitcmds[ #gitcmds+1 ] = word
                end
            end
            githelp:close()
            if #gitcmds > 1 then
                local maincmds = share.maincmds
                maincmds["git"] = gitcmds
                save_subcommands_cache("git-subcommands.txt",gitcmds)
                if hub then
                  maincmds["hub"] = gitcmds
                  save_subcommands_cache("hub-subcommands.txt",gitcmds)
                end
                share.maincmds = maincmds
            end
        end
    end

    -- Subversion
    share.maincmds["svn"] = load_subcommands_cache("svn-subcommands.txt")
    if not share.maincmds["svn"] then
        local svnhelp=nyagos.eval(share.svnpath .. " help 2>nul","r")
        if string.len(svnhelp) > 5 then
            local svncmds={}
            for line in string.gmatch(svnhelp,"[^\n]+") do
                local m=string.match(line,"^ +([a-z]+)")
                if m then
                    svncmds[ #svncmds+1 ] = m
                end
            end
            if #svncmds > 1 then
                local maincmds = share.maincmds
                maincmds["svn"] = svncmds
                share.maincmds = maincmds
                save_subcommands_cache("svn-subcommands.txt",svncmds)
            end
        end
    end

    share.maincmds["go"] = {
        "bug", "build", "clean", "doc", "env", "fix",
        "fmt", "generate", "get", "install", "list",
        "mod", "run", "test", "tool", "version", "vet"
    }

    for cmd,subcmdData in pairs(share.maincmds or {}) do
        if not nyagos.complete_for[cmd] then
            nyagos.complete_for[cmd] = function(args)
                local subcmdType = type(subcmdData)
                if "table" == subcmdType then
                    while #args > 2 and args[2]:sub(1,1) == "-" do
                        table.remove(args,2)
                    end
                    if #args == 2 then
                        return subcmdData
                    end
                elseif "function" == subcmdType then
                    return subcmdData(args)
                end
                return nil
            end
        end
    end
end

update_cache()

nyagos.alias.clear_subcommands_cache = function()
    local wildcard = nyagos.pathjoin(get_local(),"*-subcommands.txt")
    local files = nyagos.glob(wildcard)
    if #files >= 2 or not string.find(files[1],"*",1,true) then
        for i=1,#files do
            print("remove "..files[i])
            os.remove(files[i])
        end
    end
    update_cache()
end
