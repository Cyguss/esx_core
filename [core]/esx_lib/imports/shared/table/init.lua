local prototype = {
    __index = table, 
}

---@class xTable : tablelib
local xTable = setmetatable({}, prototype)

---@param tbl table 
---@param copies table   
function xTable.deepClone(tbl, copies)
    copies = copies or {} 

    if copies[tbl] then
        return copies[tbl]
    end

    local copy = {} 

    copies[tbl] = copy 

    for key, value in pairs(tbl) do 
        copy[key] = type(value) == "table" and xTable.deepClone(value, copies) or value 

        if type(value) == "table" and getmetatable(value) then 
            setmetatable(copy[key], getmetatable(value))
        end 
    end

    return copy 
end

---@param tbl table 
---@param search any 
function xTable.contains(tbl, search) 
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
    for i = 1, select("#", ...) do 
        local source = select(i, ...)

        for key, value in pairs(source) do
            main[key] = value 
        end
    end

    return main 
end

---@param tbl table 
function xTable.print(tbl)
    local out = "" 

    for key, value in pairs(tbl) do
        if key == #tbl then 
            out = out..("[%s] = %s"):format(key, value)..""
        else 
            out = out..("[%s] = %s"):format(key, value)..", "
        end
    end

    return print(("{%s}"):format(out))
end

return xTable