-- This module is greatly inspired by ox_lib
-- https://github.com/overextended/ox_lib
-- And uses logic from https://www.lua.org/source/5.5/loadlib.c.html
-- Shoutout to Mutt for helping with understanding the lua source code.
local nativeRequire = require

---@param path string
---@return string?
local function readFile(path)
    -- Seperates @esx_lib/imports/function/init.lua -> esx_lib, imports/function/init.lua
    local resourceName, filePath = path:match("@([^/]+)/(.*)")

    resourceName = resourceName or GetCurrentResourceName()
    filePath = filePath or path

    local file = LoadResourceFile(resourceName, filePath)

    return file
end

---@param path string
---@param searchTemplate string
---@return string?, string
local function searchPath(path, searchTemplate)
    if type(searchTemplate) ~= "string" then
        error("package path is not a string - findFile error")
    end

    local separator = "%."  -- require(server.modules.function)
    local replacement = "/" -- will replace separtor with this char

    path = path:gsub(separator, replacement)

    local messages = {}

    for fileName in searchTemplate:gsub("?", path):gmatch("[^;]+") do
        local fileContent = readFile(fileName)
        if fileContent then
            return fileName, fileContent
        end

        messages[#messages + 1] = ("File with a name: %s does not exists"):format(fileName)
    end

    return nil, table.concat(messages, "\n")
end

local package = {
    path = "?.lua;?/init.lua;?/main.lua",
    loaded = {},
    ---@type fun(path: string): loader: function|string?, loaderData: string? []
    searchers = {
        -- native require attempt
        ---@param path string
        function(path)
            local success, result, loaderData = pcall(nativeRequire, path)

            if success then
                return result, loaderData
            end

            return nil, result
        end,
        -- searcher_lua
        ---@param path any
        ---@return function | string?
        ---@return string?
        function(path)
            local filePath, output = searchPath(path, package.path)

            if not filePath then
                return output
            end

            local loader, err = load(output, filePath)

            if err then
                return nil, err
            end

            return loader
        end,
        function(path)
            local filePath, output = searchPath(path, "?.json;?/init.json")

            if not filePath then
                return output
            end

            local success, decodedJson = pcall(json.decode, output)

            if not success then
                return nil, decodedJson
            end

            return decodedJson
        end
    }
}

_G.package = package

---@param path string
local function findLoader(path)
    if type(package.searchers) ~= "table" then
        error("package searches is not an array - findLoader error")
    end

    local messages = {}

    for i = 1, #package.searchers do
        local loader, loaderData = package.searchers[i](path)

        if not loader then
            messages[#messages + 1] = loader
        else
            return loader, loaderData
        end
    end

    error(("Couldn't find module with a name: %s. Errors: %s"):format(path, table.concat(messages, "\n")))
end

---@param path string
local function require(path)
    if type(path) ~= "string" then
        error("#1 param in require is wrong type (expected string)")
    end

    local module = package.loaded[path]

    if module == "__loading" then
        error("circular-dependency in module (2 modules tried to load each other)")
    end

    if module ~= nil then
        return module
    end

    package.loaded[path] = "__loading"

    local loader, loaderData = findLoader(path)

    module = type(loader) == "function" and loader() or loader

    if module == nil then
        module = true
    end

    package.loaded[path] = module

    return module, loaderData
end

_G.require = require
