local Utils = require("imports/shared/math/utils.lua")

local prototype = {
    __index = math,
}

---@class xMath : mathlib
local xMath = setmetatable({}, prototype)

function xMath.clamp(value, min, max)
    if min > max then 
        min, max = max, min
    end

    return math.max(min, math.min(max, value))
end

function xMath.interpolate(start, finish, factor)
    local valueType = type(start)
    return Utils.interpolateByType(start, finish, factor, valueType)
end

function xMath.headingBetween(origin, target)
    local dx, dy = Utils.headingDelta(origin, target)
    return Utils.normalizeHeadingFromDelta(dx, dy)
end

function xMath.round(value, places) 
    if places then 
        local multiplier = 10 ^ places
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    return math.floor(value + 0.5)
end

function xMath.lerp(start, finish, duration)
    local valueType = type(start)
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
