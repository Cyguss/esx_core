-- This module is greatly inspired by ox_lib
-- https://github.com/overextended/ox_lib
-- And uses logic from https://www.lua.org/source/5.5/loadlib.c.html
-- Uses the intepretation of https://github.com/Reality-Scripts/rs_lib/
local nativeRequire = require
local nativeLibraries = {
    lmprof = true,
    glm = true,
}

local package = {
    luaPath = "?.lua;?/init.lua;?/main.lua",
    jsonPath = "?.json;?/init.json;?/config.json",
    loaded = {},
}

---@param module string
---@return string, string
local function convertRelativePath(module)
    local i = 3
    while true do
        local src = debug.getinfo(i, "S")?.source

        if not src then
            error("Failed to find a path using relative method")
        end

        if src ~= "@@esx_lib/imports/shared/package/init.lua" then
            local resourceName, path = src:match("@@([^/]+)/(.*)")
            local parts = {}

            path = path:match("^(.*)/[^/]+$")

            for segment in ("%s/%s"):format(path, module):gmatch("[^/]+") do
                if segment == ".." then
                    if #parts > 0 then
                        table.remove(parts)
                    end
                elseif segment ~= "." then
                    parts[#parts + 1] = segment
                end
            end

            return resourceName, table.concat(parts, "/")
        end

        i += 1
    end
end

---@return string
local function getResourceName()
    local i = 0
    while true do
        local src = debug.getinfo(i, "S")?.source

        if not src then
            return GetCurrentResourceName()
        end

        if src ~= "@@esx_lib/imports/shared/package/init.lua" then
            local resourceName = src:match("^@@([^/]+)/.+")
            if resourceName then
                return resourceName
            end
        end

        i += 1
    end
end

---@param module string
---@return string, string
local function resolvePath(module)
    local isRelative = module:find("%./")

    if isRelative then
        return convertRelativePath(module)
    end

    local resourceName, path = module:match("^@([^/%.]+)[/%.](.+)$")

    if not resourceName then
        resourceName = getResourceName()
    end

    if not path then
        path = module
    end

    return resourceName, path
end

---@param resourceName string
---@param path string
---@return function?, string?
local function findLoader(resourceName, path)
    local messages = {}
    local searchPath = ("%s;%s"):format(package.luaPath, package.jsonPath)
    local fileContent
    local correctFileName

    for fileName in searchPath:gsub("?", path):gmatch("[^;]+") do
        fileContent = LoadResourceFile(resourceName, fileName)
        if fileContent then
            correctFileName = fileName
            break
        end
        messages[#messages + 1] = ("File with a name: %s does not exist"):format(fileName)
    end

    if not fileContent then
        return nil, table.concat(messages, "\n")
    end

    if correctFileName:find("%.json$") then
        return function()
            local converted, err = pcall(json.decode, fileContent)

            if not converted or err then
                return nil, ("Failed to load json file: %s. %s"):format(correctFileName, err)
            end

            return converted
        end
    end

    local loader, err = load(fileContent, correctFileName)

    if err then
        return nil, ("Error occured while loading %s. %s"):format(correctFileName, err)
    end

    return loader
end

---@param module string
---@param ignoreCache boolean?
local function require(module, ignoreCache)
    if type(module) ~= "string" then
        error("#1 param in require is wrong type (expected string)")
    end

    if nativeLibraries[module] then
        return nativeRequire(module)
    end

    if package.loaded[module] == "__loading" then
        error(("Circular-dependency during loading: %s"):format(module))
    end

    if not ignoreCache and package.loaded[module] then
        return package.loaded[module]
    end

    package.loaded[module] = "__loading"

    local resourceName, path = resolvePath(module)
    path = path:gsub("%.", "/")

    local loader, err = findLoader(resourceName, path)

    if not loader or err then
        error(err)
    end

    if type(loader) == "function" then
        loader = loader()
    end

    package.loaded[module] = loader or loader == nil

    return package.loaded[module]
end

_G.require = require
