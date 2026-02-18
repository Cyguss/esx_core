local Utils = {}

---@alias xStringTemplateToken string|fun(): string
---@class xStringCompiledTemplate
---@field unique boolean
---@field [integer] xStringTemplateToken

---@type table<string, boolean>
Utils.generated_strings = {}

---@type integer
Utils.default_unique_attempts = 9

---@return string
function Utils.randomUpper()
    return string.char(math.random(65, 90))
end

---@return string
function Utils.randomLower()
    return string.char(math.random(97, 122))
end

---@return string
function Utils.randomDigit()
    return string.char(math.random(48, 57))
end

---@return string
function Utils.randomAlphaNum()
    return math.random(0, 1) == 1 and Utils.randomUpper() or Utils.randomDigit()
end

---@type table<string, fun(): string>
Utils.formatter_by_char = {
    ["A"] = Utils.randomUpper,
    ["a"] = Utils.randomLower,
    ["0"] = Utils.randomDigit,
    ["*"] = Utils.randomAlphaNum,
}

---@param pattern string
---@param unique? boolean 
---@return xStringCompiledTemplate compiled
function Utils.compileTemplate(pattern, unique)
    ---@type xStringCompiledTemplate
    local compiled = {
        unique = unique == true,
    }

    local count = 1
    local n = #pattern

    while count <= n do
        local char = pattern:sub(count, count)

        if char == "^" then
            count += 1
            local escaped = pattern:sub(count, count)
            if escaped == "" then
                break
            end

            compiled[#compiled + 1] = escaped
            count += 1
        else
            local formatter = Utils.formatter_by_char[char]
            compiled[#compiled + 1] = formatter or char
            count += 1
        end
    end

    return compiled
end

---@param compiled xStringCompiledTemplate
---@param length? integer
---@return string
function Utils.renderTemplate(compiled, length)
    local outLen = length or #compiled

    if outLen == 0 then
        return ""
    end

    local out = table.create(outLen, 0)

    for i = 1, outLen do
        local token = compiled[i]

        if token == nil then
            out[i] = " "
        else
            out[i] = (type(token) == "function") and token() or token
        end
    end

    return table.concat(out)
end

---@param compiled xStringCompiledTemplate
---@param length? integer
---@return string
function Utils.generateFromTemplate(compiled, length)
    if compiled.unique ~= true then
        return Utils.renderTemplate(compiled, length)
    end

    for _ = 1, Utils.default_unique_attempts do
        local value = Utils.renderTemplate(compiled, length)

        if not Utils.generated_strings[value] then
            Utils.generated_strings[value] = true
            return value
        end
    end

    error(("Unable to generate unique string after %d attempts"):format(Utils.default_unique_attempts))
end

function Utils.clearGeneratedStrings()
    for key in pairs(Utils.generated_strings) do
        Utils.generated_strings[key] = nil
    end
end

return Utils
