-- lib/inlines.lua
-- Convert Pandoc inline elements to Codex text nodes

local M = {}

-- Deep copy a table
local function deep_copy(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deep_copy(v)
    end
    return copy
end

-- Check if two marks are equal
local function marks_equal(m1, m2)
    if type(m1) ~= type(m2) then
        return false
    end
    if type(m1) == "string" then
        return m1 == m2
    end
    if type(m1) == "table" then
        -- Compare link marks
        if m1.type ~= m2.type then
            return false
        end
        if m1.type == "link" then
            return m1.href == m2.href and m1.title == m2.title
        end
    end
    return false
end

-- Check if two mark arrays are equal
local function marks_arrays_equal(arr1, arr2)
    if #arr1 ~= #arr2 then
        return false
    end
    for i = 1, #arr1 do
        if not marks_equal(arr1[i], arr2[i]) then
            return false
        end
    end
    return true
end

-- Sort marks for consistent output (simple string marks before objects)
local function sort_marks(marks)
    table.sort(marks, function(a, b)
        local type_a = type(a)
        local type_b = type(b)
        if type_a ~= type_b then
            return type_a == "string"
        end
        if type_a == "string" then
            return a < b
        end
        -- Both are objects (links)
        return false
    end)
    return marks
end

-- Flatten nested inlines into text nodes with marks
-- @param inlines Pandoc inline list
-- @param marks Current mark stack
-- @return Array of text nodes {type="text", value=string, marks=array}
function M.flatten(inlines, marks)
    marks = marks or {}
    local result = {}

    for _, inline in ipairs(inlines) do
        local nodes = M.convert_inline(inline, marks)
        for _, node in ipairs(nodes) do
            table.insert(result, node)
        end
    end

    return result
end

-- Convert a single inline element to text nodes
-- @param inline Pandoc inline element
-- @param marks Current marks stack
-- @return Array of text nodes
function M.convert_inline(inline, marks)
    marks = marks or {}
    local tag = inline.t or inline.tag

    if tag == "Str" then
        return {M.text_node(inline.text, marks)}

    elseif tag == "Space" then
        return {M.text_node(" ", marks)}

    elseif tag == "SoftBreak" then
        return {M.text_node(" ", marks)}

    elseif tag == "LineBreak" then
        -- LineBreak becomes a space in text; could also be handled as break block
        return {M.text_node("\n", marks)}

    elseif tag == "Strong" then
        local new_marks = deep_copy(marks)
        table.insert(new_marks, "bold")
        return M.flatten(inline.content, new_marks)

    elseif tag == "Emph" then
        local new_marks = deep_copy(marks)
        table.insert(new_marks, "italic")
        return M.flatten(inline.content, new_marks)

    elseif tag == "Strikeout" then
        local new_marks = deep_copy(marks)
        table.insert(new_marks, "strikethrough")
        return M.flatten(inline.content, new_marks)

    elseif tag == "Underline" then
        local new_marks = deep_copy(marks)
        table.insert(new_marks, "underline")
        return M.flatten(inline.content, new_marks)

    elseif tag == "Superscript" then
        local new_marks = deep_copy(marks)
        table.insert(new_marks, "superscript")
        return M.flatten(inline.content, new_marks)

    elseif tag == "Subscript" then
        local new_marks = deep_copy(marks)
        table.insert(new_marks, "subscript")
        return M.flatten(inline.content, new_marks)

    elseif tag == "Code" then
        local new_marks = deep_copy(marks)
        table.insert(new_marks, "code")
        return {M.text_node(inline.text, new_marks)}

    elseif tag == "Link" then
        local new_marks = deep_copy(marks)
        local link_mark = {
            type = "link",
            href = inline.target,
        }
        -- Add title if present (Pandoc uses target as [url, title])
        if inline.title and inline.title ~= "" then
            link_mark.title = inline.title
        end
        table.insert(new_marks, link_mark)
        return M.flatten(inline.content, new_marks)

    elseif tag == "Image" then
        -- Inline images are complex; for now, just use alt text
        return {M.text_node(inline.caption and pandoc.utils.stringify(inline.caption) or "[image]", marks)}

    elseif tag == "Math" then
        return {{
            type = "math_sentinel",
            mathtype = inline.mathtype,
            text = inline.text,
            value = ""
        }}

    elseif tag == "RawInline" then
        -- Raw content - just include as text
        return {M.text_node(inline.text, marks)}

    elseif tag == "Quoted" then
        -- Quoted text - add quotes
        local quote_char = inline.quotetype == "DoubleQuote" and '"' or "'"
        local nodes = {}
        table.insert(nodes, M.text_node(quote_char, marks))
        for _, node in ipairs(M.flatten(inline.content, marks)) do
            table.insert(nodes, node)
        end
        table.insert(nodes, M.text_node(quote_char, marks))
        return nodes

    elseif tag == "Cite" then
        local citations = {}
        for _, c in ipairs(inline.citations) do
            table.insert(citations, {
                id = c.id,
                mode = c.mode,
                prefix = c.prefix and pandoc.utils.stringify(c.prefix) or nil,
                suffix = c.suffix and pandoc.utils.stringify(c.suffix) or nil,
            })
        end
        return {{type = "citation_sentinel", citations = citations, value = ""}}

    elseif tag == "SmallCaps" then
        -- SmallCaps not supported in Codex, render as-is
        return M.flatten(inline.content, marks)

    elseif tag == "Span" then
        -- Span - just process content
        return M.flatten(inline.content, marks)

    elseif tag == "Note" then
        -- Footnote - render content inline for now
        return M.flatten(inline.content, marks)

    else
        -- Unknown inline type - try to stringify if possible
        if inline.content then
            return M.flatten(inline.content, marks)
        else
            return {}
        end
    end
end

-- Create a text node
-- @param value Text content
-- @param marks Array of marks
-- @return Text node table
function M.text_node(value, marks)
    marks = marks or {}
    local sorted = sort_marks(deep_copy(marks))

    local node = {
        type = "text",
        value = value,
    }

    if #sorted > 0 then
        node.marks = sorted
    end

    return node
end

-- Check if a node is a sentinel (non-text node that needs block-level handling)
local function is_sentinel(node)
    return node.type and node.type:match("_sentinel$")
end

-- Merge adjacent text nodes with identical marks
-- Sentinel nodes are passed through untouched
-- @param nodes Array of text nodes (and possibly sentinel nodes)
-- @return Merged array of nodes
function M.merge_adjacent(nodes)
    if #nodes == 0 then
        return {}
    end

    local result = {}
    local current = nil

    for _, node in ipairs(nodes) do
        if is_sentinel(node) then
            -- Flush current text node if any
            if current then
                if current.value ~= "" then
                    table.insert(result, current)
                end
                current = nil
            end
            -- Pass sentinel through as-is
            table.insert(result, node)
        elseif current == nil then
            current = deep_copy(node)
        else
            local current_marks = current.marks or {}
            local node_marks = node.marks or {}

            if marks_arrays_equal(current_marks, node_marks) then
                -- Same marks, merge text
                current.value = current.value .. node.value
            else
                -- Different marks, push current and start new
                if current.value ~= "" then
                    table.insert(result, current)
                end
                current = deep_copy(node)
            end
        end
    end

    -- Don't forget the last node
    if current and current.value ~= "" then
        table.insert(result, current)
    end

    return result
end

-- Convert a list of Pandoc inlines to Codex text nodes
-- This is the main entry point
-- @param inlines Pandoc inline list
-- @return Array of Codex text nodes
function M.convert(inlines)
    local flat = M.flatten(inlines)
    return M.merge_adjacent(flat)
end

return M
