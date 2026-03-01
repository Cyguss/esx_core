local Utils = require "@esx_lib/imports/shared/string/utils"
local Validator = require "@esx_lib/imports/shared/validate"

local prototype = {
    __index = string,
}

---@class xString : stringlib
local xString = setmetatable({}, prototype)

---@param pattern string
---@param unique? boolean
---@return xStringCompiledTemplate compiled
function xString.compileTemplate(pattern, unique)
    Validator.arguments(true, {
        { pattern, "string" },
        { unique, { "boolean", "nil" } },
    })

    return Utils.compileTemplate(pattern, unique)
end

---@param pattern string|xStringCompiledTemplate
---@param length? integer
---@param unique? boolean
---@return string
function xString.random(pattern, length, unique)
    Validator.arguments(true, {
        { pattern, { "string", "table" } },
        { length, { "number", "nil" } },
        { unique, { "boolean", "nil" } },
    })

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
