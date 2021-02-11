if not nyagos then
    print("This is a script for nyagos not lua.exe")
    os.exit()
end

share.org_completion_hook_case_sensitive = nyagos.completion_hook
nyagos.completion_hook = function(c)
    local org_list = c.list
    local org_shownlist = c.shownlist
    if share.org_completion_hook_case_sensitive then
        local l, s = share.org_completion_hook_case_sensitive(c)
        if l ~= nil then
            org_list = l
            org_shownlist = l
        end
        if s ~= nil then
            org_shownlist = s
        end
    end

    -- case-sensitive completion.
    local list = {}
    local shownlist = {}
    local word_len = #c.word
    for i = 1, #org_list do
        if org_list[i]:sub(1, word_len) == c.word then
            table.insert(list, org_list[i])
            table.insert(shownlist, org_shownlist[i])
        end
    end
    return list, shownlist
end
