-- lib/json.lua
-- JSON encoding utilities for Codex Pandoc writer

local M = {}

-- Check if a table is an array (sequential integer keys starting at 1)
local function is_array(t)
    if type(t) ~= "table" then
        return false
    end
    local count = 0
    for k, _ in pairs(t) do
        count = count + 1
        if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
            return false
        end
    end
    -- Check for sequential keys
    for i = 1, count do
        if t[i] == nil then
            return false
        end
    end
    return true
end

-- Escape a string for JSON
local function escape_string(s)
    local escaped = s:gsub('[\\"\b\f\n\r\t]', function(c)
        local replacements = {
            ['\\'] = '\\\\',
            ['"'] = '\\"',
            ['\b'] = '\\b',
            ['\f'] = '\\f',
            ['\n'] = '\\n',
            ['\r'] = '\\r',
            ['\t'] = '\\t',
        }
        return replacements[c] or c
    end)
    -- Escape control characters
    escaped = escaped:gsub('[\x00-\x1f]', function(c)
        return string.format('\\u%04x', string.byte(c))
    end)
    return escaped
end

-- Get sorted keys from a table
local function sorted_keys(t)
    local keys = {}
    for k in pairs(t) do
        if type(k) == "string" then
            table.insert(keys, k)
        end
    end
    table.sort(keys)
    return keys
end

-- Encode a Lua value to JSON
-- @param value The value to encode
-- @param indent Current indentation level (for pretty printing)
-- @param pretty Whether to pretty print
function M.encode(value, indent, pretty)
    indent = indent or 0
    pretty = pretty or false

    local t = type(value)

    if value == nil then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        if value ~= value then -- NaN
            return "null"
        elseif value == math.huge or value == -math.huge then
            return "null"
        elseif value == math.floor(value) then
            return string.format("%d", value)
        else
            return string.format("%.15g", value)
        end
    elseif t == "string" then
        return '"' .. escape_string(value) .. '"'
    elseif t == "table" then
        if is_array(value) then
            return M.encode_array(value, indent, pretty)
        else
            return M.encode_object(value, indent, pretty)
        end
    else
        error("Cannot encode type: " .. t)
    end
end

-- Encode an array to JSON
function M.encode_array(arr, indent, pretty)
    indent = indent or 0
    pretty = pretty or false

    if #arr == 0 then
        return "[]"
    end

    local parts = {}
    local newline = pretty and "\n" or ""
    local spacing = pretty and string.rep("  ", indent + 1) or ""
    local close_spacing = pretty and string.rep("  ", indent) or ""

    for i, v in ipairs(arr) do
        parts[i] = spacing .. M.encode(v, indent + 1, pretty)
    end

    if pretty then
        return "[\n" .. table.concat(parts, ",\n") .. "\n" .. close_spacing .. "]"
    else
        -- For non-pretty, strip spacing from parts
        local compact_parts = {}
        for i, v in ipairs(arr) do
            compact_parts[i] = M.encode(v, 0, false)
        end
        return "[" .. table.concat(compact_parts, ",") .. "]"
    end
end

-- Encode an object to JSON
function M.encode_object(obj, indent, pretty)
    indent = indent or 0
    pretty = pretty or false

    local keys = sorted_keys(obj)

    if #keys == 0 then
        return "{}"
    end

    local parts = {}
    local newline = pretty and "\n" or ""
    local spacing = pretty and string.rep("  ", indent + 1) or ""
    local close_spacing = pretty and string.rep("  ", indent) or ""

    for _, k in ipairs(keys) do
        local v = obj[k]
        if v ~= nil then -- Skip nil values
            local key_json = '"' .. escape_string(k) .. '"'
            local value_json = M.encode(v, indent + 1, pretty)
            if pretty then
                table.insert(parts, spacing .. key_json .. ": " .. value_json)
            else
                table.insert(parts, key_json .. ":" .. value_json)
            end
        end
    end

    if pretty then
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. close_spacing .. "}"
    else
        return "{" .. table.concat(parts, ",") .. "}"
    end
end

-- Pretty print JSON
function M.pretty(value)
    return M.encode(value, 0, true)
end

-- Compact JSON (no whitespace)
function M.compact(value)
    return M.encode(value, 0, false)
end

return M
