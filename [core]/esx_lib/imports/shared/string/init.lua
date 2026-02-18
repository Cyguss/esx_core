local Utils = require("imports/shared/string/utils.lua")

local prototype = {
    __index = string,
}

---@class xString : stringlib
local xString = setmetatable({}, prototype)

---@param pattern string
---@param unique? boolean
---@return xStringCompiledTemplate compiled
function xString.compileTemplate(pattern, unique)
    return Utils.compileTemplate(pattern, unique)
end

---@param pattern string|xStringCompiledTemplate
---@param length? integer
---@param unique? boolean
---@return string
function xString.random(pattern, length, unique)
    ---@type xStringCompiledTemplate
    local compiled

    if type(pattern) == "string" then
        compiled = xString.compileTemplate(pattern, unique)
    else
        compiled = pattern
        if unique then
            compiled.unique = unique
        end
    end

    return Utils.generateFromTemplate(compiled, length)
end

function xString.clearGeneratedStrings()
    Utils.clearGeneratedStrings()
end

return xString
