if not nyagos then
    print("This is a script for nyagos not lua.exe")
    os.exit()
end

share.org_dollar_env_completion_hook = nyagos.completion_hook
nyagos.completion_hook = function(c)
    if c.word:sub(1, 1) ~= "$" then
        if share.org_dollar_env_completion_hook then
            return share.org_dollar_env_completion_hook(c)
        else
            return nil
        end
    end

    local envs = {}
    local env_str = nyagos.raweval("cmd", "/c", "set")
    for line in env_str:gmatch("([^\n]+)\n") do
        k, v = line:match("^([^=]+)=(.+)$")
        if k ~= nil and c.word == "$" .. k:sub(1, #c.word - 1) then
            table.insert(envs, "$" .. k)
        end
    end
    return envs
end

function dollar_env_replace_env(text)
    s, e = text:find("%$[a-zA-Z0-9_]+")
    local new_text = text
    if s then
        local env_name = text:sub(s + 1, e)
        local env_value = nyagos.env[env_name]
        if env_value then
            new_text = text:sub(1, s - 1) .. env_value .. text:sub(e + 1)
        end
    end
    return new_text
end

share.org_env_argsfilter = nyagos.argsfilter
nyagos.argsfilter = function(args)
    if share.org_env_argsfilter then
        local args_ = share.org_env_argsfilter(args)
        if args_ then
            args = args_
        end
    end

    local result = {}
    local i = 0
    while args[i] do
        s, e = args[i]:find("%$[a-zA-Z0-9_]+")
        local new_arg = args[i]
        if s then
            env_name = args[i]:sub(s + 1, e)
            if nyagos.env[env_name] then
                new_arg = args[i]:sub(1, s - 1) .. nyagos.env[env_name] .. args[i]:sub(e + 1)
            end
        end
        result[i] = new_arg
        i = i + 1
    end
    return result
end
