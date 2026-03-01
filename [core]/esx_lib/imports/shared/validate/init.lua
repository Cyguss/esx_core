local Utils = require "@esx_lib/imports/shared/validate/utils"

local xValidate = {}

function xValidate.arguments(errorOnFailure, args)
    if type(errorOnFailure) == "table" and args == nil then
        args = errorOnFailure
        errorOnFailure = false
    end

    if type(args) ~= "table" then
        local err = ("Expected args to be table in arguments, got %s"):format(type(args))

        if errorOnFailure then
            error(err)
        end

        return false, err
    end

    for index = 1, #args do
        local spec = args[index]

        if type(spec) ~= "table" then
            local err = ("Invalid argument spec at index %d (expected table)"):format(index)

            if errorOnFailure then
                error(err)
            end

            return false, err
        end

        local expected = spec.expected
        if expected == nil then
            expected = spec[2]
        end

        if expected == nil then
            local err = ("Missing expected matcher in argument spec at index %d"):format(index)

            if errorOnFailure then
                error(err)
            end

            return false, err
        end

        local value = spec.value
        if value == nil then
            value = spec[1]
        end

        if not Utils.matches(value, expected) then
            local err = ("Invalid argument #%d: got type %s"):format(index, type(value))

            if errorOnFailure then
                error(err)
            end

            return false, err
        end
    end

    return true
end

function xValidate.defaultArguments(args)
    if type(args) ~= "table" then
        error(("Expected args to be table in defaultArguments, got %s"):format(type(args)))
    end

    local count = #args
    local values = {}

    for index = 1, count do
        local spec = args[index]

        if type(spec) ~= "table" then
            error(("Invalid default spec at index %d (expected table)"):format(index))
        end

        local value = spec.value
        if value == nil then
            value = spec[1]
        end

        if value == nil then
            value = spec.default
            if value == nil then
                value = spec[2]
            end
        end

        values[index] = value
    end

    return table.unpack(values, 1, count)
end

return xValidate
