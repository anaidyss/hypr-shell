local M = {}

local function skip(s, i)
    return s:find("[^ \t\r\n]", i) or #s + 1
end

local parse

local function parse_string(s, i)
    local out, j = {}, i + 1
    while true do
        local c = s:sub(j, j)
        if c == '"' then return table.concat(out), j + 1 end
        if c == "" then error("unterminated string") end
        if c == "\\" then
            local n = s:sub(j + 1, j + 1)
            local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
            if n == "u" then
                out[#out + 1] = utf8.char(tonumber(s:sub(j + 2, j + 5), 16))
                j = j + 6
            else
                out[#out + 1] = map[n] or n
                j = j + 2
            end
        else
            out[#out + 1] = c
            j = j + 1
        end
    end
end

function parse(s, i)
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == "{" then
        local obj = {}
        i = skip(s, i + 1)
        if s:sub(i, i) == "}" then return obj, i + 1 end
        while true do
            local key
            key, i = parse_string(s, skip(s, i))
            i = skip(s, i)
            assert(s:sub(i, i) == ":", "expected ':'")
            obj[key], i = parse(s, i + 1)
            i = skip(s, i)
            local d = s:sub(i, i)
            if d == "}" then return obj, i + 1 end
            assert(d == ",", "expected ',' or '}'")
            i = i + 1
        end
    elseif c == "[" then
        local arr = {}
        i = skip(s, i + 1)
        if s:sub(i, i) == "]" then return arr, i + 1 end
        while true do
            arr[#arr + 1], i = parse(s, i)
            i = skip(s, i)
            local d = s:sub(i, i)
            if d == "]" then return arr, i + 1 end
            assert(d == ",", "expected ',' or ']'")
            i = i + 1
        end
    elseif c == '"' then
        return parse_string(s, i)
    elseif s:sub(i, i + 3) == "true" then return true, i + 4
    elseif s:sub(i, i + 4) == "false" then return false, i + 5
    elseif s:sub(i, i + 3) == "null" then return nil, i + 4
    else
        local num = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", i)
        assert(num and #num > 0, "unexpected character at " .. i)
        return tonumber(num), i + #num
    end
end

function M.decode(s)
    local v = parse(s, 1)
    return v
end

return M
