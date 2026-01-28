-- Reader: Codex blocks → Pandoc blocks
-- Converts Codex block types to Pandoc AST block elements.

local M = {}

local reader_inlines = nil

function M.set_inlines(mod)
    reader_inlines = mod
end

-- Convert an array of Codex blocks to Pandoc blocks
function M.convert(blocks)
    local result = {}
    for _, block in ipairs(blocks) do
        local converted = M.convert_block(block)
        if converted then
            if type(converted) == "table" and converted.tag then
                -- Single Pandoc element
                table.insert(result, converted)
            elseif type(converted) == "table" and #converted > 0 then
                -- Array of Pandoc elements
                for _, b in ipairs(converted) do
                    table.insert(result, b)
                end
            end
        end
    end
    return result
end

-- Convert a single Codex block to Pandoc block(s)
function M.convert_block(block)
    local btype = block.type or ""

    if btype == "paragraph" then
        return M.paragraph(block)
    elseif btype == "heading" then
        return M.heading(block)
    elseif btype == "codeBlock" then
        return M.code_block(block)
    elseif btype == "blockquote" then
        return M.blockquote(block)
    elseif btype == "list" then
        return M.list(block)
    elseif btype == "horizontalRule" then
        return pandoc.HorizontalRule()
    elseif btype == "table" then
        return M.table_block(block)
    elseif btype == "math" then
        return M.math_block(block)
    elseif btype == "image" then
        return M.image_block(block)
    elseif btype:match("^semantic:") or btype:match("^forms:") or btype:match("^collaboration:") then
        -- Extension blocks — silently skip
        io.stderr:write("cdx-reader: skipping extension block: " .. btype .. "\n")
        return nil
    elseif btype == "listItem" or btype == "tableRow" or btype == "tableCell" then
        -- Sub-block types handled by their parent converter
        return nil
    else
        if btype ~= "" then
            io.stderr:write("cdx-reader: unknown block type: " .. btype .. "\n")
        end
        return nil
    end
end

-- Paragraph
function M.paragraph(block)
    local inlines = reader_inlines.convert(block.children or {})
    if #inlines == 0 then return nil end
    return pandoc.Para(inlines)
end

-- Heading
function M.heading(block)
    local level = block.level or 1
    local inlines = reader_inlines.convert(block.children or {})
    local attr = pandoc.Attr(block.id or "")
    return pandoc.Header(level, inlines, attr)
end

-- Code block
function M.code_block(block)
    local text = ""
    if block.children then
        for _, child in ipairs(block.children) do
            if child.value then
                text = text .. child.value
            end
        end
    end
    local lang = block.language or ""
    local attr = pandoc.Attr("", lang ~= "" and {lang} or {})
    return pandoc.CodeBlock(text, attr)
end

-- Blockquote
function M.blockquote(block)
    local inner_blocks = M.convert(block.children or {})
    return pandoc.BlockQuote(inner_blocks)
end

-- List (ordered or unordered)
function M.list(block)
    local items = {}
    for _, child in ipairs(block.children or {}) do
        if child.type == "listItem" then
            local item_blocks = M.convert_list_item(child)
            table.insert(items, item_blocks)
        end
    end

    if block.ordered then
        local start = block.start or 1
        return pandoc.OrderedList(items, pandoc.ListAttributes(start))
    else
        return pandoc.BulletList(items)
    end
end

-- Convert a single list item to an array of blocks
function M.convert_list_item(item)
    local blocks = {}
    for _, child in ipairs(item.children or {}) do
        local converted = M.convert_block(child)
        if converted then
            if type(converted) == "table" and converted.tag then
                table.insert(blocks, converted)
            elseif type(converted) == "table" and #converted > 0 then
                for _, b in ipairs(converted) do
                    table.insert(blocks, b)
                end
            end
        end
    end
    -- If no blocks, try to create a plain text from children directly
    if #blocks == 0 then
        local inlines = reader_inlines.convert(item.children or {})
        if #inlines > 0 then
            table.insert(blocks, pandoc.Plain(inlines))
        end
    end
    return blocks
end

-- Table (uses SimpleTable for broad Pandoc version compatibility)
function M.table_block(block)
    local header_cells = {}
    local body_rows = {}
    local num_cols = 0

    for _, child in ipairs(block.children or {}) do
        if child.type == "tableRow" then
            local cells = {}
            for _, cell_block in ipairs(child.children or {}) do
                if cell_block.type == "tableCell" then
                    local cell_inlines = reader_inlines.convert(cell_block.children or {})
                    table.insert(cells, cell_inlines)
                end
            end
            if #cells > num_cols then num_cols = #cells end

            if child.header then
                header_cells = cells
            else
                table.insert(body_rows, cells)
            end
        end
    end

    -- Build alignment and width specs
    local aligns = {}
    local widths = {}
    for _ = 1, num_cols do
        table.insert(aligns, pandoc.AlignDefault)
        table.insert(widths, 0)
    end

    -- Pad rows to num_cols
    local function pad_row(row)
        while #row < num_cols do
            table.insert(row, {})
        end
        return row
    end

    header_cells = pad_row(header_cells)
    for i, row in ipairs(body_rows) do
        body_rows[i] = pad_row(row)
    end

    local simple = pandoc.SimpleTable(
        {},            -- caption
        aligns,
        widths,
        header_cells,
        body_rows
    )

    return pandoc.utils.from_simple_table(simple)
end

-- Math block
function M.math_block(block)
    local math_type = block.display and pandoc.DisplayMath or pandoc.InlineMath
    local math_el = pandoc.Math(math_type, block.value or "")
    return pandoc.Para({math_el})
end

-- Image block
function M.image_block(block)
    local src = block.src or ""
    local alt = block.alt or ""
    local title = block.title or ""

    local alt_inlines = {}
    if alt ~= "" then
        alt_inlines = {pandoc.Str(alt)}
    end

    local img = pandoc.Image(alt_inlines, src, title)
    return pandoc.Figure(pandoc.Plain({img}))
end

return M
