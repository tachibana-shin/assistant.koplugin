-- markdown parser wrapper module
-- This module provides a simple interface to use hoedown (C binding of full features markdown)
-- or the pure Lua implementation of markdown.lua (building on KOReader)
local Parser = nil

local logger = require("logger")
local DataStorage = require("datastorage")
local lfs = require("libs/libkoreader-lfs")
local plugin_lib_dir = DataStorage:getDataDir() .. "/plugins/assistant.koplugin/lib"
local ffi = require("ffi")
local LibHoedown = nil

-- check if hoedown is natively available
local ok, _lib = pcall(ffi.loadlib, "hoedown", 3)
if ok then Libhoedown = _lib end 

-- check if hoedown is available in the plugin directory
if not LibHoedown then
    local ok, _lib = pcall(ffi.load, plugin_lib_dir .. "/libhoedown.so.3")
    if ok then LibHoedown = _lib end
end

if LibHoedown then
    package.preload["resty.hoedown.library"] = function()
        return LibHoedown
    end

    package.path = string.format("%s;%s/?.lua", package.path, plugin_lib_dir)
    local ok, hoedownMD = pcall(require, "resty.hoedown")
    if ok then
        Parser = function (text)
            return hoedownMD(text, {
                rendered    = "html",
                nesting     = 1,
                extensions  = {
                    "space_headers", "tables", "fenced_code", "footnotes", "autolink", "strikethrough",
                    "underline", "highlight", "quote", "superscript", "math", "math_explicit",
                },
            })
        end
        logger.info("Using hoedown (C binding) for markdown parsing")
    end
end

if not Parser then
    -- fallback to pure Lua implementation
    Parser = require("apps/filemanager/lib/md")
    logger.info("Using markdown.lua (pure Lua) for markdown parsing")
end

return Parser