-- codex.lua
-- Pandoc custom writer for Codex Document Format
--
-- Usage:
--   pandoc input.md -t codex.lua -o output.json
--
-- Output: JSON containing manifest, content, and dublin_core sections
-- that can be unpacked into a Codex directory structure and packaged.

-- Get the directory containing this script
local script_path = PANDOC_SCRIPT_FILE or ""
local script_dir = script_path:match("(.*/)")
if not script_dir then
    -- Try current directory
    script_dir = "./"
end

-- Load library modules
local function load_lib(name)
    local paths = {
        script_dir .. "lib/" .. name .. ".lua",
        "lib/" .. name .. ".lua",
        name .. ".lua",
    }

    for _, path in ipairs(paths) do
        local f = io.open(path, "r")
        if f then
            f:close()
            local chunk, err = loadfile(path)
            if chunk then
                return chunk()
            else
                io.stderr:write("Error loading " .. path .. ": " .. (err or "unknown") .. "\n")
            end
        end
    end

    error("Cannot find library: " .. name)
end

local json = load_lib("json")
local inlines = load_lib("inlines")
local blocks = load_lib("blocks")
local metadata = load_lib("metadata")

-- Initialize blocks module with inlines reference
blocks.set_inlines(inlines)

-- Spec version
local CODEX_VERSION = "0.1"
local CONTENT_VERSION = "0.1"

-- Generate ISO 8601 timestamp
local function iso_timestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

-- SHA-256 placeholder (actual hash computed by packaging tool)
local function placeholder_hash()
    return "sha256:0000000000000000000000000000000000000000000000000000000000000000"
end

-- Create manifest structure
local function create_manifest()
    local now = iso_timestamp()

    return {
        codex = CODEX_VERSION,
        id = "pending",
        state = "draft",
        created = now,
        modified = now,
        content = {
            path = "content/document.json",
            hash = placeholder_hash()
        },
        metadata = {
            dublinCore = "metadata/dublin-core.json"
        }
    }
end

-- Create content structure from Pandoc blocks
local function create_content(doc_blocks)
    return {
        version = CONTENT_VERSION,
        blocks = blocks.convert(doc_blocks)
    }
end

-- Main writer function
-- Pandoc calls this with the full document
function Writer(doc, opts)
    -- Extract metadata
    local dublin_core = metadata.extract(doc.meta) or metadata.default_metadata()

    -- Convert blocks
    local content = create_content(doc.blocks)

    -- Create manifest
    local manifest = create_manifest()

    -- Combine into output structure
    local output = {
        manifest = manifest,
        content = content,
        dublin_core = dublin_core
    }

    -- Return pretty-printed JSON
    return json.pretty(output)
end

-- Template (not used for custom writers, but required by some Pandoc versions)
function Template()
    return "$body$"
end

-- Pandoc 3.x uses a different calling convention
-- If the global Writer function doesn't work, try the module return
return {
    Writer = Writer,
    Template = Template
}
