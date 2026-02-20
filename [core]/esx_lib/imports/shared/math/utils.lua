local Utils = {}

---@param start number
---@param finish number
---@param factor number
---@return number
function Utils.interpolateNumber(start, finish, factor)
    return start + (finish - start) * factor
end

---@param start number|vector2|vector3|vector4
---@param finish number|vector2|vector3|vector4
---@param factor number
---@param valueType string
---@return number|vector2|vector3|vector4
function Utils.interpolateByType(start, finish, factor, valueType)
    if valueType == "number" then
        ---@cast start number
        ---@cast finish number
        return Utils.interpolateNumber(start, finish, factor)
    elseif valueType == "vector2" then
        ---@cast start vector2
        ---@cast finish vector2
        return vector2(
            Utils.interpolateNumber(start.x, finish.x, factor),
            Utils.interpolateNumber(start.y, finish.y, factor)
        )
    elseif valueType == "vector3" then
        ---@cast start vector3
        ---@cast finish vector3
        return vector3(
            Utils.interpolateNumber(start.x, finish.x, factor),
            Utils.interpolateNumber(start.y, finish.y, factor),
            Utils.interpolateNumber(start.z, finish.z, factor)
        )
    elseif valueType == "vector4" then
        ---@cast start vector4
        ---@cast finish vector4
        return vector4(
            Utils.interpolateNumber(start.x, finish.x, factor),
            Utils.interpolateNumber(start.y, finish.y, factor),
            Utils.interpolateNumber(start.z, finish.z, factor),
            Utils.interpolateNumber(start.w, finish.w, factor)
        )
    end

    error(("Unsupported type in interpolation helper: %s"):format(valueType))
end

---@param startTime integer
---@param now integer
---@param duration number
---@return number
function Utils.lerpStep(startTime, now, duration)
    if duration <= 0 then
        return 1
    end

    local step = (now - startTime) / duration

    if step <= 0 then
        return 0
    end

    if step >= 1 then
        return 1
    end

    return step
end

---@param origin table|vector2|vector3|vector4
---@param target table|vector2|vector3|vector4
---@return number dx
---@return number dy
function Utils.headingDelta(origin, target)
    local dx = origin.x - target.x
    local dy = origin.y - target.y
    return dx, dy
end

---@param dx number
---@param dy number
---@return number
function Utils.normalizeHeadingFromDelta(dx, dy)
    local heading = math.deg(math.atan(dy, dx)) + 90
    return (heading + 360) % 360
end

return Utils
