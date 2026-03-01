local xTimeout = require("@esx_lib/imports/shared/timeout")

local Utils = {
    event = "_esx_cb_%s",
    validateEvent = "esx_lib:validateCallback",
    timeout = 30000
}

---@param state table
---@param eventName string
---@param playerId number
---@return string
function Utils.nextRequestKey(state, eventName, playerId)
    local key

    repeat
        state.requestId += 1
        key = ("%s:%s:%s:%s"):format(eventName, playerId, state.requestId, math.random(100000, 999999))
    until not state.pending[key]

    return key
end

---@param name string
---@param playerId number
---@param requestPromise promise?
---@param callbackFn function?
---@return table
function Utils.createPending(name, playerId, requestPromise, callbackFn)
    local pending = {
        name = name,
        playerId = playerId,
    }

    pending.execute = function(response, ...)
        if response == "invalid_cb" then
            local err = ("callback %s does not exist"):format(name)

            if requestPromise then
                requestPromise:reject(err)
                return
            end

            error(err)
        end

        local values = table.pack(response, ...)

        if requestPromise then
            requestPromise:resolve(values)
            return
        end

        if callbackFn then
            callbackFn(table.unpack(values, 1, values.n))
        end
    end

    return pending
end

---@param pending table
function Utils.cancelPendingTimeout(pending)
    if pending.timeoutId then
        xTimeout.cancel(pending.timeoutId)
        pending.timeoutId = nil
    end
end

---@param timeoutMs number
---@param pendingMap table
---@param key string|number
---@param pending table
---@param requestPromise promise?
---@return number
function Utils.startPendingTimeout(timeoutMs, pendingMap, key, pending, requestPromise)
    return xTimeout.set(timeoutMs, function()
        if pendingMap[key] ~= pending then
            return
        end

        pendingMap[key] = nil
        pending.timeoutId = nil

        local err = ("callback %s timed out"):format(pending.name or "unknown")

        if requestPromise then
            requestPromise:reject(err)
            return
        end

        warn(err)
    end)
end

function Utils.callbackResponse(success, result, ...)
    if success then
        return result, ...
    end

    local trace = debug and debug.traceback and debug.traceback() or ""

    if trace ~= "" then
        print(("^1SCRIPT ERROR: %s^0\n%s"):format(result, trace))
    else
        print(("^1SCRIPT ERROR: %s^0"):format(result))
    end

    return false, result
end

return Utils
