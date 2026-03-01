local Utils = require("@esx_lib/imports/server/callback/utils")
local Validator = require("@esx_lib/imports/shared/validate")

local State = {
    event = "_esx_cb_%s",
    validateEvent = "esx_lib:validateCallback",
    timeout = 30000,    
    requestId = 0,
    pending = {},
    handlers = {},
    owners = {},
    flags = {},
    registered = {},
}

---@param playerId number
---@param resourceName any
---@param key string|number
local function sendCallbackResponse(playerId, resourceName, key, ...)
    TriggerClientEvent(State.event:format(resourceName), playerId, key, ...)
end

---@param name string
---@return boolean
local function isValidCallback(name)
    Validator.arguments(true, {
        { name, "string" },
    })

    local flag = State.flags[name]
    if flag ~= nil then
        return flag
    end

    return State.handlers[name] ~= nil
end

---@param resourceName string
local function cleanupResource(resourceName)
    for name, owner in pairs(State.owners) do
        if owner == resourceName then
            State.handlers[name] = nil
            State.owners[name] = nil
            State.flags[name] = nil
        end
    end
end

---@param playerId number
---@param key string|number
---@return boolean
local function resolvePending(playerId, key, ...)
    if not Validator.arguments(false, {
        { playerId, "number" },
        { key, { "string", "number" } },
    }) then
        return false
    end

    local pending = State.pending[key]

    if not pending then
        return false
    end

    if pending.playerId and pending.playerId ~= playerId then
        warn(
            ("ignored callback response for %s from player %s (expected %s)")
                :format(pending.name or "unknown", playerId, pending.playerId)
        )
        return false
    end

    State.pending[key] = nil
    Utils.cancelPendingTimeout(pending)
    pending.execute(...)

    return true
end

---@param name string
---@param playerId number
---@param cb function?
local function requestClientCallback(name, playerId, cb, ...)
    Validator.arguments(true, {
        { name, "string" },
        { playerId, "number" },
        { cb, { "function", "nil" } },
    })

    local key = Utils.nextRequestKey(State, name, playerId)
    local requestPromise = cb and nil or promise.new()
    local pending = Utils.createPending(name, playerId, requestPromise, cb)

    State.pending[key] = pending

    TriggerClientEvent(State.validateEvent, playerId, name, GetCurrentResourceName(), key)
    TriggerClientEvent(State.event:format(name), playerId, GetCurrentResourceName(), key, ...)

    pending.timeoutId = Utils.startPendingTimeout(State.timeout, State.pending, key, pending, requestPromise)

    if not requestPromise then
        return
    end

    local response = Citizen.Await(requestPromise)
    return table.unpack(response, 1, response.n)
end

---@param playerId number
---@param name any
---@param resourceName any
---@param key any
---@return boolean
local function handleValidationEvent(playerId, name, resourceName, key)
    if not Validator.arguments(false, {
        { name, "string" },
        { resourceName, { "string", "nil" } },
        { key, { "string", "number" } },
    }) then
        return false
    end

    if not isValidCallback(name) then
        sendCallbackResponse(playerId, resourceName, key, "invalid_cb")
    end

    return true
end

local prototype = {
    __call = function(_, event, playerId, cb, ...)
        if cb == nil then
            error(("callback event %s requires callback function\nuse callback.await for sync flow"):format(event))
        end

        return requestClientCallback(event, playerId, cb, ...)
    end,
}

local xCallbacks = setmetatable({
    pending = State.pending,
    event = State.event,
    timeout = State.timeout,
}, prototype)

RegisterNetEvent(State.event:format(GetCurrentResourceName()), function(key, ...)
    local playerId = source
    resolvePending(playerId, key, ...)
end)

function xCallbacks.await(event, playerId, ...)
    return requestClientCallback(event, playerId, nil, ...)
end

function xCallbacks.isValidCallback(name)
    return isValidCallback(name)
end

---@param name string
---@param cb function
function xCallbacks.registerServerCallback(name, cb)
    Validator.arguments(true, {
        { name, "string" },
        { cb, "function" },
    })

    if State.handlers[name] then
        warn(("callback %s is already registered, overriding previous handler"):format(name))
    end

    State.handlers[name] = cb
    State.owners[name] = GetInvokingResource() or GetCurrentResourceName()
    State.flags[name] = true

    if State.registered[name] then
        return
    end

    RegisterNetEvent(State.event:format(name), function(resourceName, key, ...)
        if not Validator.arguments(false, {
            { resourceName, { "string", "nil" } },
            { key, { "string", "number" } },
        }) then
            return
        end

        local callback = State.handlers[name]
        if not callback or not isValidCallback(name) then
            sendCallbackResponse(source, resourceName, key, "invalid_cb")
            return
        end

        sendCallbackResponse(source, resourceName, key, Utils.callbackResponse(pcall(callback, source, ...)))
    end)

    State.registered[name] = true
end

---@param name string
---@param isValid boolean?
---@return boolean
function xCallbacks.setValidCallback(name, isValid)
    Validator.arguments(true, {
        { name, "string" },
        { isValid, { "boolean", "nil" } },
    })

    if isValid == nil then
        isValid = true
    end

    State.flags[name] = isValid

    return isValid
end

RegisterNetEvent(State.validateEvent, function(name, resourceName, key)
    handleValidationEvent(source, name, resourceName, key)
end)

AddEventHandler("onResourceStop", function(resourceName)
    cleanupResource(resourceName)
end)

return xCallbacks
