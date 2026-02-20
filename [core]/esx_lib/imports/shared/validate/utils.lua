local Utils = {}

local type_tokens = {
    ["nil"] = true,
    boolean = true,
    number = true,
    string = true,
    table = true,
    ["function"] = true,
    thread = true,
    userdata = true,
    vector2 = true,
    vector3 = true,
    vector4 = true,
}

function Utils.matches(value, expected)
    if type(expected) == "table" then
        for i = 1, #expected do
            if Utils.matches(value, expected[i]) then
                return true
            end
        end

        return false
    end

    if type(expected) == "string" and type_tokens[expected] then
        return type(value) == expected
    end

    return value == expected
end

return Utils
