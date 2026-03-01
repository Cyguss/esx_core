local Utils = require "@esx_lib/imports/shared/math"
local Validator = require "@esx_lib/imports/shared/validate"

local prototype = {
    __index = math,
}

---@class xMath : mathlib
local xMath = setmetatable({}, prototype)

function xMath.clamp(value, min, max)
    Validator.arguments(true, {
        { value, "number" },
        { min, "number" },
        { max, "number" },
    })

    if min > max then 
        min, max = max, min
    end

    return math.max(min, math.min(max, value))
end

function xMath.interpolate(start, finish, factor)
    Validator.arguments(true, {
        { start, { "number", "vector2", "vector3", "vector4" } },
        { finish, { "number", "vector2", "vector3", "vector4" } },
        { factor, "number" },
    })

    local valueType = type(start)

    if valueType ~= type(finish) then
        error(("Expected start and finish to have the same type, got %s and %s"):format(valueType, type(finish)))
    end

    return Utils.interpolateByType(start, finish, factor, valueType)
end

function xMath.headingBetween(origin, target)
    Validator.arguments(true, {
        { origin, { "table", "vector2", "vector3", "vector4" } },
        { target, { "table", "vector2", "vector3", "vector4" } },
        { origin and origin.x, "number" },
        { origin and origin.y, "number" },
        { target and target.x, "number" },
        { target and target.y, "number" },
    })

    local dx, dy = Utils.headingDelta(origin, target)
    return Utils.normalizeHeadingFromDelta(dx, dy)
end

function xMath.round(value, places) 
    Validator.arguments(true, {
        { value, "number" },
        { places, { "number", "nil" } },
    })

    if places then 
        local multiplier = 10 ^ places
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    return math.floor(value + 0.5)
end

function xMath.lerp(start, finish, duration)
    Validator.arguments(true, {
        { start, { "number", "vector2", "vector3", "vector4" } },
        { finish, { "number", "vector2", "vector3", "vector4" } },
        { duration, "number" },
    })

    local valueType = type(start)

    if valueType ~= type(finish) then
        error(("Expected start and finish to have the same type, got %s and %s"):format(valueType, type(finish)))
    end

    local interpolateByType = Utils.interpolateByType

    local startTime = 0
    local started = false
    local completed = false

    return function(now)
        if completed then 
            return
        end

        local currentTime = now or GetGameTimer()

        if not started then 
            started = true
            startTime = currentTime
            return start, 0
        end

        local step = Utils.lerpStep(startTime, currentTime, duration)

        if step >= 1 then
            completed = true
            return finish, 1
        end

        return interpolateByType(start, finish, step, valueType), step
    end
end

return xMath 
