if not nyagos then
    print("This is a script for nyagos not lua.exe")
    os.exit()
end

function backward_action(this, action)
    local pos = (this.text:sub(1, this.pos - 2)):match('.*()[%s/\\]')
    if pos == nil then
        pos = 0
    end
    if pos < this.pos then
        for i = 1, utf8.len(this.text:sub(pos + 1, this.pos - 1)) do
            this:call(action)
        end
    end
end

nyagos.bindkey("M_BACKSPACE",
    function(this)
        backward_action(this, "BACKWARD_DELETE_CHAR")
    end
)
nyagos.bindkey("M_B",
    function(this)
        backward_action(this, "BACKWARD_CHAR")
    end
)

function forward_action(this, action)
    local pos = this.text:find('[%s/\\]', this.pos + 1)
    if pos == nil then
        pos = #this.text + 1
    end
    if pos > this.pos then
        for i = 1, utf8.len(this.text:sub(this.pos, pos - 1)) do
            this:call(action)
        end
    end
end

nyagos.bindkey("M_D",
    function(this)
        forward_action(this, "DELETE_CHAR")
    end
)
nyagos.bindkey("M_F",
    function(this)
        forward_action(this, "FORWARD_CHAR")
    end
)

function search_history(this, is_prev)
    local clear_state = function()
        share.search_history_state = nil
    end

    if this.pos == 1 then
        if is_prev == true then
            this:call("HISTORY_UP")
        else
            this:call("HISTORY_DOWN")
        end
        this:call("END_OF_LINE")
        clear_state()
        return
    end

    local save_state = function(pos, search_string, text)
        share.search_history_state = {pos=pos, search_string=search_string, text=text}
    end

    local previous_state = function(pos, text)
        local state = share.search_history_state
        if state == nil then
            return nil
        end

        if state.pos ~= pos or state.text ~= text then
            return nil
        end

        return state.search_string
    end

    local search_string = previous_state(this.pos, this.text)
    local current_string = this.text
    if search_string == nil then
        search_string = this.text:sub(1, this.pos - 1)
        current_string = nil
    end

    local word_cache = {}
    local hist_len = nyagos.gethistory()
    local prev_word = nil
    local next_word = nil
    local found = false
    for i = 1, hist_len do
        local history = nyagos.gethistory(hist_len - i)
        if #history > #search_string and history:sub(1, #search_string) == search_string then
            if word_cache[history] ~= true then
                word_cache[history] = true
                if found or current_string == nil then
                    prev_word = history
                    break
                elseif history == current_string then
                    found = true
                else
                    next_word = history
                end
            end
        end
    end

    local new_word = nil
    if is_prev and prev_word then
        new_word = prev_word
    elseif is_prev ~= true and next_word then
        new_word = next_word
    end

    if new_word then
        this:call("END_OF_LINE")
        this:replacefrom(1, new_word)
        save_state(#new_word + 1, search_string, new_word)
    end
end

nyagos.bindkey("M_N",
    function(this)
        search_history(this, false)
    end
)

nyagos.bindkey("M_P",
    function(this)
        search_history(this, true)
    end
)

function completion_from_history(this)
    local clear_state = function()
        share.completion_from_history_state = nil
    end

    local save_state = function(start, pos, search_string, text)
        share.completion_from_history_state = {start=start, pos=pos, search_string=search_string, text=text}
    end

    local previous_state = function(pos, text)
        local state = share.completion_from_history_state
        if state == nil then
            return nil
        end

        if state.pos ~= pos or state.text ~= text then
            return nil
        end

        return state.start, state.search_string
    end

    local split_words = function(line)
        local index = 1
        local words = {}
        local start_index, end_index
        local ends_with_space = false
        while index <= #line do
            start_index, end_index = line:find('%S+', index)
            if start_index == nil then
                ends_with_space = true
                break
            end

            if line:sub(start_index, start_index) == '"' then
                local s, e = line:find('"', start_index + 1)
                if s ~= nil then
                    end_index = e
                else
                    end_index = #line
                end
            elseif line:sub(start_index, start_index) == "'" then
                local s, e = line:find("'", start_index + 1)
                if s ~= nil then
                    end_index = e
                else
                    end_index = #line
                end
            end

            table.insert(words, line:sub(start_index, end_index))
            index = end_index + 1
        end

        return words, ends_with_space
    end

    if this.pos == 1 then
        clear_state()
        return nil
    end

    local words, ends_with_space = split_words(this.text:sub(1, this.pos-1))
    if ends_with_space == true then
        clear_state()
        return nil
    end

    local first_time = false
    local start, search_string = previous_state(this.pos, this.text)
    if start == nil then
        first_time = true
        local words = split_words(this.text:sub(1, this.pos - 1))
        if #words == 0 then
            start = 1
            search_string = this.text:sub(start, this.pos - 1)
        else
            search_string = words[#words]
            start = this.pos - 1 - #search_string + 1
        end
    end

    local current_string = this.text:sub(start, this.pos - 1)

    local found = false
    local word_cache = {}
    local next_target = nil
    local first_match = nil

    local search_line = function(history)
        local words_in_line = split_words(history)

        for j = #words_in_line, 1, -1 do
            local word = words_in_line[j]
            if found == false then
                if word == current_string then
                    found = true
                end
                if word:sub(1, #search_string) == search_string then
                    if first_time then
                        return word
                    end
                    word_cache[word] = true
                    if first_match == nil then
                        first_match = word
                    end
                end
            else
                if word:sub(1, #search_string) == search_string and word_cache[word] ~= true then
                    return word
                end
            end
        end
        return nil
    end

    local current_line = this.text:sub(1, start - 1)
    next_target = search_line(current_line)

    if next_target == nil then
        local hist_len = nyagos.gethistory()
        for i = 1, hist_len do
            local history = nyagos.gethistory(hist_len - i)
            next_target = search_line(history)

            if next_target ~= nil then
                break
            end
        end
    end

    if next_target == nil and first_match ~= nil then
        next_target = first_match
    end

    if next_target then
        this:replacefrom(start, next_target)
        local new_text = this.text:sub(1, start - 1) .. next_target .. this.text:sub(this.pos)
        save_state(start, start + #next_target, search_string, new_text)
    else
        clear_state()
    end
end

-- OEM_2 is "/".
nyagos.bindkey("M_OEM_2", completion_from_history)
nyagos.bindkey("M_L", completion_from_history)

share.org_tcsh_prompt = nyagos.prompt
nyagos.prompt = function(this)
    share.completion_from_history_state = nil
    share.search_history_state = nil
    if share.org_tcsh_prompt then
        return share.org_tcsh_prompt(this)
    end
end
