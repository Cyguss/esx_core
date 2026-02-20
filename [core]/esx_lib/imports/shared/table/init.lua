local Validator = require "imports/shared/validate/init.lua"

local prototype = {
    __index = table,
}

---@class xTable : tablelib
local xTable = setmetatable({}, prototype)

---@param tbl table
---@param copies? table
function xTable.deepClone(tbl, copies)
    if copies == nil then
        Validator.arguments(true, {
            { tbl, "table" },
        })
        copies = {}
    end

    if copies[tbl] then
        return copies[tbl]
    end

    local copy = {}
    copies[tbl] = copy

    for key, value in pairs(tbl) do
        local clonedKey = type(key) == "table" and xTable.deepClone(key, copies) or key
        local clonedValue = type(value) == "table" and xTable.deepClone(value, copies) or value
        copy[clonedKey] = clonedValue
    end

    local meta = getmetatable(tbl)
    if meta then
        setmetatable(copy, meta)
    end

    return copy
end

---@param tbl table
---@param search any
function xTable.contains(tbl, search)
    Validator.arguments(true, {
        { tbl, "table" },
    })

    for key, value in pairs(tbl) do
        if value == search then
            return true, key
        end
    end

    return false, nil
end

---@param main table
---@param ... table
---@return table
function xTable.merge(main, ...)
    Validator.arguments(true, {
        { main, "table" },
    })

    for i = 1, select("#", ...) do
        local source = select(i, ...)

        Validator.arguments(true, {
            { source, "table" },
        })

        for key, value in pairs(source) do
            main[key] = value
        end
    end

    return main
end

---@param tbl table
function xTable.print(tbl)
    Validator.arguments(true, {
        { tbl, "table" },
    })

    local out = {}

    for key, value in pairs(tbl) do
        out[#out + 1] = ("[%s] = %s"):format(key, value)
    end

    return print(("{%s}"):format(table.concat(out, ", ")))
end

return xTable
