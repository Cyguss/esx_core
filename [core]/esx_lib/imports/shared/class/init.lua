-- This module is greatly inspired by ox_lib
-- https://github.com/overextended/ox_lib
local blockFromInstance = {
    ["new"] = true,
    ["extends"] = true,
}

---@class xClass
---@field init? function
---@field protected super? xClass
---@field protected private table

---@generic T: string
---@param name `T`
---@return `T`
local function createNewClass(name)
    ---@class xClass
    local class = {}
    local hidden = {
        __parent = nil,
        __abstract = nil,
    }

    local classMt = {
        __index = function (_, key)
            return rawget(class, key)
        end,
        __newindex = function(_, key, value)
            if key == "__parent" or key == "__abstract" then
                error(("Tried to modify internal field '%s'"):format(key))
            end

            if key == "super" and rawget(class, key) then
                error("Tried to override super table")
            end

            return rawset(class, key, value)
        end,
        __tostring = function()
            return ("xClass: %s"):format(name)
        end
    }

    setmetatable(class, classMt)

    ---@protected
    ---@generic T
    ---@param self T
    ---@param ... unknown
    ---@return T
    function class:new(...)
        if rawget(hidden, "__abstract") then
            error("Tried to create a new instance of abstract function")
        end

        local instance = {}
        local private = {}
        local parent = rawget(hidden, "__parent")

        instance.private = setmetatable({}, {
            __index = function(_, key)
                local info = debug.getinfo(2, "n")

                if info and (info.namewhat ~= "method" and info.namewhat ~= "") then
                    return
                end

                return rawget(private, key)
            end,
            __newindex = function(_, key, value)
                local info = debug.getinfo(2, "n")

                if info and (info.namewhat ~= "method" and info.namewhat ~= "") then
                    return
                end

                rawset(private, key, value)
            end
        })

        local instanceMt = {
            __newindex = function(_, key, value)
                if key == "super" then
                    error("Tried to override super table")
                end

                return rawset(instance, key, value)
            end,
            __index = function(_, key)
                if blockFromInstance[key] then
                    return
                end

                return class[key]
            end,
            __tostring = function()
                return (("xClass Instance - From: %s"):format(name))
            end
        }

        setmetatable(instance, instanceMt)

        if parent then
            rawset(instance, "super", setmetatable({}, {
                __index = function(_, key)
                    local value = parent[key]

                    if type(value) == "function" then
                        return function(...)
                            return value(instance, ...)
                        end
                    end

                    return value
                end,
            __call = function(_, ...)
                local nextParent = rawget(parent, "__parent")
                if nextParent and nextParent.init then
                    return nextParent.init(instance, ...)
                end
            end
            }))
        end

        if instance.init then
            instance:init(...)
        end

        return instance
    end

    ---@param inherit xClass
    function class:extends(inherit)
        rawset(hidden, "__parent", inherit)

        classMt.__index = function (_, key)
            if key == "__parent" or key == "__abstract" then
                return
            end

            return inherit[key]
        end

        setmetatable(class, classMt)

        return class
    end

    function class:abstract()
        rawset(hidden, "__abstract", true)
        return class
    end

    ---@param target xClass|string
    ---@return boolean
    function class:is(target)
        if not target then
            return false
        end

        if target == class or target == name then
            return true
        end

        local parent = rawget(hidden, "__parent")

        if not parent then
            return false
        end

        local parentIs = rawget(parent, "is")

        if type(parentIs) ~= "function" then
            return false
        end

        return parentIs(parent, target)
    end

    return class
end

return createNewClass
