-- Codex Document Format → Pandoc Reader
-- Converts Codex JSON to Pandoc AST for output to any format.
--
-- Usage:
--   pandoc -f cdx-reader.lua output.json -o document.md
--   pandoc -f cdx-reader.lua output.json -o document.tex
--   pandoc -f cdx-reader.lua output.json -o document.html

-- Dynamically find and load library modules
local function load_lib(name)
    local paths = {
        "lib/" .. name .. ".lua",
        "cdx-pandoc/lib/" .. name .. ".lua",
        PANDOC_SCRIPT_FILE and (PANDOC_SCRIPT_FILE:match("(.*/)" ) or "") .. "lib/" .. name .. ".lua",
    }
    for _, path in ipairs(paths) do
        local f = io.open(path, "r")
        if f then
            f:close()
            return dofile(path)
        end
    end
    error("Cannot find library: " .. name)
end

local reader_blocks = load_lib("reader_blocks")
local reader_inlines = load_lib("reader_inlines")

-- Initialize cross-module references
reader_blocks.set_inlines(reader_inlines)

-- Reconstruct Pandoc metadata from Dublin Core
local function reconstruct_metadata(dc)
    if not dc then return pandoc.Meta({}) end

    local meta = {}
    local terms = dc.terms or dc

    if terms.title then
        meta.title = pandoc.MetaInlines({pandoc.Str(terms.title)})
    end

    -- Handle creator as string or array
    if terms.creator then
        if type(terms.creator) == "string" then
            meta.author = pandoc.MetaList({
                pandoc.MetaInlines({pandoc.Str(terms.creator)})
            })
        elseif type(terms.creator) == "table" then
            local authors = {}
            for _, a in ipairs(terms.creator) do
                table.insert(authors, pandoc.MetaInlines({pandoc.Str(a)}))
            end
            meta.author = pandoc.MetaList(authors)
        end
    end

    if terms.date then
        meta.date = pandoc.MetaInlines({pandoc.Str(terms.date)})
    end

    if terms.description then
        meta.abstract = pandoc.MetaBlocks({pandoc.Para({pandoc.Str(terms.description)})})
    end

    if terms.language then
        meta.lang = pandoc.MetaString(terms.language)
    end

    if terms.subject then
        if type(terms.subject) == "string" then
            meta.keywords = pandoc.MetaList({pandoc.MetaString(terms.subject)})
        elseif type(terms.subject) == "table" then
            local keywords = {}
            for _, k in ipairs(terms.subject) do
                table.insert(keywords, pandoc.MetaString(k))
            end
            meta.keywords = pandoc.MetaList(keywords)
        end
    end

    return pandoc.Meta(meta)
end

-- Main reader function
function Reader(input, opts)
    local json_str = tostring(input)
    local parsed = pandoc.json.decode(json_str)

    -- Extract content blocks
    local content = parsed.content or parsed
    local raw_blocks = content.blocks or {}

    -- Convert blocks
    local pandoc_blocks = reader_blocks.convert(raw_blocks)

    -- Reconstruct metadata
    local meta = reconstruct_metadata(parsed.dublin_core)

    return pandoc.Pandoc(pandoc_blocks, meta)
end
