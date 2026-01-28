-- lib/blocks.lua
-- Convert Pandoc blocks to Codex block structures

local M = {}

-- Inlines module (will be set by init)
local inlines = nil

-- Set the inlines module reference
function M.set_inlines(inlines_module)
    inlines = inlines_module
end

-- Convert a list of Pandoc blocks to Codex blocks
-- @param blocks Pandoc block list
-- @return Array of Codex blocks
function M.convert(blocks)
    local result = {}

    for _, block in ipairs(blocks) do
        local converted = M.convert_block(block)
        if converted then
            if converted.multi then
                -- Some conversions return multiple blocks
                for _, b in ipairs(converted.blocks) do
                    table.insert(result, b)
                end
            else
                table.insert(result, converted)
            end
        end
    end

    return result
end

-- Convert a single Pandoc block to a Codex block
-- @param block Pandoc block element
-- @return Codex block table or nil
function M.convert_block(block)
    local tag = block.t or block.tag

    if tag == "Para" then
        return M.paragraph(block)

    elseif tag == "Plain" then
        -- Plain is like Para but without surrounding paragraph tags
        return M.paragraph(block)

    elseif tag == "Header" then
        return M.heading(block)

    elseif tag == "BulletList" then
        return M.bullet_list(block)

    elseif tag == "OrderedList" then
        return M.ordered_list(block)

    elseif tag == "CodeBlock" then
        return M.code_block(block)

    elseif tag == "BlockQuote" then
        return M.blockquote(block)

    elseif tag == "HorizontalRule" then
        return M.horizontal_rule(block)

    elseif tag == "Table" then
        return M.table_block(block)

    elseif tag == "Div" then
        -- Div is a container - unwrap its contents
        return {
            multi = true,
            blocks = M.convert(block.content)
        }

    elseif tag == "RawBlock" then
        -- Raw block - treat as code block with no language
        return {
            type = "codeBlock",
            children = {
                {type = "text", value = block.text}
            }
        }

    elseif tag == "LineBlock" then
        -- Line block - convert each line to paragraph
        local paragraphs = {}
        for _, line in ipairs(block.content) do
            table.insert(paragraphs, {
                type = "paragraph",
                children = inlines.convert(line)
            })
        end
        return {
            multi = true,
            blocks = paragraphs
        }

    elseif tag == "DefinitionList" then
        -- Definition list - convert to regular list with term+definition
        return M.definition_list(block)

    elseif tag == "Figure" then
        -- Figure - extract image and caption
        return M.figure(block)

    else
        -- Unknown block type - skip with warning
        io.stderr:write("Warning: Unknown block type: " .. (tag or "nil") .. "\n")
        return nil
    end
end

-- Convert Para/Plain to paragraph
function M.paragraph(block)
    local content = block.content or block.c
    if not content then
        return nil
    end

    return {
        type = "paragraph",
        children = inlines.convert(content)
    }
end

-- Convert Header to heading
function M.heading(block)
    local level = block.level
    local attr = block.attr or {}
    local identifier = attr.identifier or (attr[1] or "")
    local content = block.content

    local result = {
        type = "heading",
        level = level,
        children = inlines.convert(content)
    }

    -- Add ID if present
    if identifier and identifier ~= "" then
        result.id = identifier
    end

    return result
end

-- Convert BulletList to list (ordered=false)
function M.bullet_list(block)
    local items = {}

    for _, item in ipairs(block.content) do
        table.insert(items, M.list_item(item))
    end

    return {
        type = "list",
        ordered = false,
        children = items
    }
end

-- Convert OrderedList to list (ordered=true)
function M.ordered_list(block)
    local items = {}
    local start_num = nil

    -- Pandoc OrderedList has listAttributes with start number
    if block.listAttributes then
        local attrs = block.listAttributes
        if type(attrs) == "table" and attrs[1] and attrs[1] > 1 then
            start_num = attrs[1]
        end
    end

    for _, item in ipairs(block.content) do
        table.insert(items, M.list_item(item))
    end

    local result = {
        type = "list",
        ordered = true,
        children = items
    }

    if start_num then
        result.start = start_num
    end

    return result
end

-- Convert a list item (array of blocks)
function M.list_item(blocks)
    local children = M.convert(blocks)

    -- Check for task list item (checkbox)
    local checked = nil
    if #children > 0 and children[1].type == "paragraph" then
        local para = children[1]
        if #para.children > 0 then
            local first_text = para.children[1].value or ""
            -- Check for checkbox patterns
            if first_text:match("^%[x%]%s*") or first_text:match("^%[X%]%s*") then
                checked = true
                para.children[1].value = first_text:gsub("^%[x%]%s*", ""):gsub("^%[X%]%s*", "")
            elseif first_text:match("^%[ %]%s*") or first_text:match("^%[%]%s*") then
                checked = false
                para.children[1].value = first_text:gsub("^%[ %]%s*", ""):gsub("^%[%]%s*", "")
            end
        end
    end

    local result = {
        type = "listItem",
        children = children
    }

    if checked ~= nil then
        result.checked = checked
    end

    return result
end

-- Convert CodeBlock
function M.code_block(block)
    local attr = block.attr or {}
    local classes = attr.classes or (attr[2] or {})
    local language = nil

    -- First class is typically the language
    if type(classes) == "table" and #classes > 0 then
        language = classes[1]
    elseif type(classes) == "string" and classes ~= "" then
        language = classes
    end

    local result = {
        type = "codeBlock",
        children = {
            {type = "text", value = block.text}
        }
    }

    if language and language ~= "" then
        result.language = language
    end

    return result
end

-- Convert BlockQuote
function M.blockquote(block)
    return {
        type = "blockquote",
        children = M.convert(block.content)
    }
end

-- Convert HorizontalRule
function M.horizontal_rule(block)
    return {
        type = "horizontalRule"
    }
end

-- Convert Table (Pandoc's complex table structure)
function M.table_block(block)
    local rows = {}

    -- Handle Pandoc table structure
    -- Pandoc 2.17+ has different table structure
    local caption = block.caption
    local colspecs = block.colspecs
    local thead = block.head
    local tbody = block.bodies
    local tfoot = block.foot

    -- Process header rows
    if thead and thead.rows then
        for _, row in ipairs(thead.rows) do
            table.insert(rows, M.table_row(row, true))
        end
    elseif thead and type(thead) == "table" then
        -- Older Pandoc format
        for _, row in ipairs(thead) do
            if type(row) == "table" and row.cells then
                table.insert(rows, M.table_row(row, true))
            end
        end
    end

    -- Process body rows
    if tbody then
        for _, body in ipairs(tbody) do
            if body.body then
                for _, row in ipairs(body.body) do
                    table.insert(rows, M.table_row(row, false))
                end
            elseif type(body) == "table" then
                for _, row in ipairs(body) do
                    if type(row) == "table" and row.cells then
                        table.insert(rows, M.table_row(row, false))
                    end
                end
            end
        end
    end

    -- Process footer rows
    if tfoot and tfoot.rows then
        for _, row in ipairs(tfoot.rows) do
            table.insert(rows, M.table_row(row, false))
        end
    end

    return {
        type = "table",
        children = rows
    }
end

-- Convert a table row
function M.table_row(row, is_header)
    local cells = {}

    local row_cells = row.cells or row

    for _, cell in ipairs(row_cells) do
        table.insert(cells, M.table_cell(cell))
    end

    local result = {
        type = "tableRow",
        children = cells
    }

    if is_header then
        result.header = true
    end

    return result
end

-- Convert a table cell
function M.table_cell(cell)
    local content = cell.contents or cell.content or cell

    -- Get cell text content
    local children = {}
    if type(content) == "table" then
        -- Content is blocks - convert and flatten to text nodes
        local blocks = M.convert(content)
        -- For simple cells, extract text from first paragraph
        if #blocks > 0 and blocks[1].type == "paragraph" then
            children = blocks[1].children
        else
            -- Complex cell content - just use first text we find
            for _, b in ipairs(blocks) do
                if b.children then
                    for _, c in ipairs(b.children) do
                        if c.type == "text" then
                            table.insert(children, c)
                        end
                    end
                end
            end
        end
    end

    local result = {
        type = "tableCell",
        children = children
    }

    -- Handle colspan/rowspan if present
    if cell.col_span and cell.col_span > 1 then
        result.colspan = cell.col_span
    end
    if cell.row_span and cell.row_span > 1 then
        result.rowspan = cell.row_span
    end

    -- Handle alignment
    if cell.alignment then
        local align = tostring(cell.alignment):lower()
        if align == "alignleft" or align == "left" then
            result.align = "left"
        elseif align == "aligncenter" or align == "center" then
            result.align = "center"
        elseif align == "alignright" or align == "right" then
            result.align = "right"
        end
    end

    return result
end

-- Convert DefinitionList
function M.definition_list(block)
    local items = {}

    for _, entry in ipairs(block.content) do
        local term = entry[1]
        local definitions = entry[2]

        -- Create a list item with term as bold + definitions
        local children = {}

        -- Term as bold paragraph
        if term then
            local term_nodes = inlines.convert(term)
            -- Make term bold
            for _, node in ipairs(term_nodes) do
                node.marks = node.marks or {}
                table.insert(node.marks, 1, "bold")
            end
            table.insert(children, {
                type = "paragraph",
                children = term_nodes
            })
        end

        -- Definitions as subsequent paragraphs
        for _, def in ipairs(definitions or {}) do
            for _, block in ipairs(M.convert(def)) do
                table.insert(children, block)
            end
        end

        table.insert(items, {
            type = "listItem",
            children = children
        })
    end

    return {
        type = "list",
        ordered = false,
        children = items
    }
end

-- Convert Figure
function M.figure(block)
    -- Extract image from figure content
    if block.content and #block.content > 0 then
        local first = block.content[1]
        if first.t == "Plain" or first.t == "Para" then
            local content = first.content or first.c
            if content and #content > 0 then
                local img = content[1]
                if img.t == "Image" then
                    return M.image(img, block.caption)
                end
            end
        end
    end

    -- Fallback: convert content as regular blocks
    return {
        multi = true,
        blocks = M.convert(block.content or {})
    }
end

-- Convert Image to image block
function M.image(img, caption)
    local src = img.src or img.target or ""
    local alt = ""

    if img.caption then
        alt = pandoc.utils.stringify(img.caption)
    elseif img.attr and img.attr[1] then
        alt = img.attr[1]
    end

    local result = {
        type = "image",
        src = src,
        alt = alt or ""
    }

    if img.title and img.title ~= "" then
        result.title = img.title
    end

    -- Add caption if present
    if caption and caption.long then
        local cap_text = pandoc.utils.stringify(caption.long)
        if cap_text and cap_text ~= "" then
            result.title = cap_text
        end
    end

    return result
end

return M
