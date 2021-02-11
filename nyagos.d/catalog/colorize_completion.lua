if not nyagos then
    print("This is a script for nyagos not lua.exe")
    os.exit()
end

local color_seq = {cyan="\027[36;1m", red="\027[31;1m", yellow="\027[33;1m", normal="\027[0m"}

local colorize = function(str, index, color)
    local offset_begin = utf8.offset(str, index)
    local offset_end = utf8.offset(str, index + 1)
    local prefix = str:sub(1, offset_begin - 1)
    if not offset_end then
        return prefix
    end

    local colorized_char = str:sub(offset_begin, offset_end - 1)
    local suffix = str:sub(offset_end)
    return prefix .. color_seq[color] .. colorized_char .. color_seq["normal"] .. suffix
end

local find_common_prefix = function(str_list)
    local common_prefix = str_list[1]
    for i = 2, #str_list do
        local str = str_list[i]
        local index = 1
        while index <= utf8.len(str) do
            local offset_begin = utf8.offset(str, index)
            local offset_end = utf8.offset(str, index + 1)
            local char1 = common_prefix:sub(offset_begin, offset_end - 1)
            local char2 = str:sub(offset_begin, offset_end - 1)
            if char1:upper() ~= char2:upper() then
                common_prefix = common_prefix:sub(1, offset_begin - 1)
                break
            end
            index = index + 1
        end
    end
    return common_prefix
end

share.org_emphasize_completion_hook = nyagos.completion_hook
nyagos.completion_hook = function(c)
    local org_list = c.list
    local org_shownlist = c.shownlist
    if share.org_emphasize_completion_hook then
        local l, s = share.org_emphasize_completion_hook(c)
        if l ~= nil then
            org_list = l
            org_shownlist = l
        end
        if s ~= nil then
            org_shownlist = s
        end
    end

    if org_list == nil or #org_list == 0 then
        return nil
    end

    local common_prefix = find_common_prefix(org_shownlist)
    local colorized_index = utf8.len(common_prefix) + 1
    local shownlist = {}
    for i = 1, #org_shownlist do
        local str = colorize(org_shownlist[i], colorized_index, "cyan")
        if i == 1 then
            -- patch
            str = color_seq["normal"] .. str
        end
        table.insert(shownlist, str)
    end

    return org_list, shownlist
end

-- vim:set ft=lua: --
