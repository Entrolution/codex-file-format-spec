-- lib/metadata.lua
-- Extract and convert Pandoc metadata to Dublin Core format

local M = {}

-- Extract a string value from a MetaValue
local function meta_to_string(value)
    if not value then
        return nil
    end

    local t = value.t or value.tag

    if t == "MetaString" then
        return value.text or value[1]
    elseif t == "MetaInlines" then
        -- Convert inlines to string
        return pandoc.utils.stringify(value)
    elseif t == "MetaBlocks" then
        return pandoc.utils.stringify(value)
    elseif type(value) == "string" then
        return value
    elseif type(value) == "table" and not t then
        -- Try to stringify
        if pandoc and pandoc.utils and pandoc.utils.stringify then
            return pandoc.utils.stringify(value)
        end
        return nil
    end

    return nil
end

-- Extract an array of strings from a MetaList
local function meta_to_array(value)
    if not value then
        return nil
    end

    local t = value.t or value.tag

    if t == "MetaList" then
        local result = {}
        for _, item in ipairs(value) do
            local str = meta_to_string(item)
            if str then
                table.insert(result, str)
            end
        end
        return #result > 0 and result or nil
    elseif t == "MetaInlines" or t == "MetaString" then
        local str = meta_to_string(value)
        return str and {str} or nil
    elseif type(value) == "table" and #value > 0 then
        -- Pandoc 3.x uses plain Lua tables for MetaList
        local result = {}
        for _, item in ipairs(value) do
            local str = meta_to_string(item)
            if str then
                table.insert(result, str)
            end
        end
        return #result > 0 and result or nil
    end

    return nil
end

-- Extract author(s) - can be string or array
local function extract_authors(meta)
    local author = meta.author

    if not author then
        return nil
    end

    local t = author.t or author.tag

    if t == "MetaList" then
        local authors = {}
        for _, a in ipairs(author) do
            local str = meta_to_string(a)
            if str then
                table.insert(authors, str)
            end
        end
        if #authors == 1 then
            return authors[1]
        elseif #authors > 1 then
            return authors
        end
    else
        return meta_to_string(author)
    end

    return nil
end

-- Extract keywords/subject
local function extract_keywords(meta)
    -- Try various metadata fields
    local keywords = meta.keywords or meta.tags or meta.subject

    if not keywords then
        return nil
    end

    return meta_to_array(keywords)
end

-- Format date to ISO 8601
local function format_date(date_str)
    if not date_str then
        return nil
    end

    -- If already ISO format, return as-is
    if date_str:match("^%d%d%d%d%-%d%d%-%d%d") then
        return date_str
    end

    -- Try to parse common date formats
    local year, month, day = date_str:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
    if year then
        return string.format("%s-%s-%s", year, month, day)
    end

    -- Try month/day/year format
    month, day, year = date_str:match("(%d%d?)/(%d%d?)/(%d%d%d%d)")
    if year then
        return string.format("%s-%02d-%02d", year, tonumber(month), tonumber(day))
    end

    -- Return as-is if can't parse
    return date_str
end

-- Extract Dublin Core metadata from Pandoc document metadata
-- @param meta Pandoc document metadata
-- @return Dublin Core metadata table
function M.extract(meta)
    if not meta then
        return nil
    end

    local terms = {}

    -- Title (required)
    local title = meta_to_string(meta.title)
    if title then
        terms.title = title
    end

    -- Creator/Author (required)
    local creator = extract_authors(meta)
    if creator then
        terms.creator = creator
    end

    -- Date
    local date = meta_to_string(meta.date)
    if date then
        terms.date = format_date(date)
    end

    -- Description/Abstract
    local description = meta_to_string(meta.abstract) or meta_to_string(meta.description)
    if description then
        terms.description = description
    end

    -- Subject/Keywords
    local subject = extract_keywords(meta)
    if subject then
        terms.subject = subject
    end

    -- Language
    local lang = meta_to_string(meta.lang) or meta_to_string(meta.language)
    if lang then
        terms.language = lang
    end

    -- Publisher
    local publisher = meta_to_string(meta.publisher)
    if publisher then
        terms.publisher = publisher
    end

    -- Rights
    local rights = meta_to_string(meta.rights) or meta_to_string(meta.license)
    if rights then
        terms.rights = rights
    end

    -- Identifier (ISBN, DOI, etc.)
    local identifier = meta_to_string(meta.identifier) or meta_to_string(meta.isbn) or meta_to_string(meta.doi)
    if identifier then
        terms.identifier = identifier
    end

    -- Source
    local source = meta_to_string(meta.source)
    if source then
        terms.source = source
    end

    -- Type (default to Text for documents)
    local doc_type = meta_to_string(meta["type"]) or meta_to_string(meta.documentType)
    terms.type = doc_type or "Text"

    -- Format (always Codex JSON)
    terms.format = "application/vnd.codex+json"

    -- If we have no title or creator, return nil
    if not terms.title then
        terms.title = "Untitled Document"
    end
    if not terms.creator then
        terms.creator = "Unknown"
    end

    return {
        version = "1.1",
        terms = terms
    }
end

-- Create default Dublin Core metadata
function M.default_metadata()
    return {
        version = "1.1",
        terms = {
            title = "Untitled Document",
            creator = "Unknown",
            type = "Text",
            format = "application/vnd.codex+json"
        }
    }
end

return M
