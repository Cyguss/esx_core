local Utils = require("@esx_lib/imports/client/callback/utils")
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

---@param resourceName any
---@param key string|number
local function sendCallbackResponse(resourceName, key, ...)
    TriggerServerEvent(State.event:format(resourceName), key, ...)
end

---@param name string
---@param isValid boolean?
---@return boolean
local function setValidCallback(name, isValid)
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

---@param eventSource number|string
---@param key string|number
---@return boolean
local function resolvePending(eventSource, key, ...)
    if eventSource == "" then
        return false
    end

    if not Validator.arguments(false, {
        { key, { "string", "number" } },
    }) then
        return false
    end

    local pending = State.pending[key]

    if not pending then
        return false
    end

    State.pending[key] = nil
    Utils.cancelPendingTimeout(pending)
    pending.execute(...)

    return true
end

---@param name string
---@param cb function?
local function requestServerCallback(name, cb, ...)
    Validator.arguments(true, {
        { name, "string" },
        { cb, { "function", "nil" } },
    })

    local key = Utils.nextRequestKey(State, name)
    local requestPromise = cb and nil or promise.new()
    local pending = Utils.createPending(name, requestPromise, cb)

    State.pending[key] = pending

    TriggerServerEvent(State.validateEvent, name, GetCurrentResourceName(), key)
    TriggerServerEvent(State.event:format(name), GetCurrentResourceName(), key, ...)

    pending.timeoutId = Utils.startPendingTimeout(State.timeout, State.pending, key, pending, requestPromise)

    if not requestPromise then
        return
    end

    local response = Citizen.Await(requestPromise)
    return table.unpack(response, 1, response.n)
end

---@param name string
---@param cb function
local function registerClientCallback(name, cb)
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
        if source == "" then
            return
        end

        if not Validator.arguments(false, {
            { resourceName, { "string", "nil" } },
            { key, { "string", "number" } },
        }) then
            return
        end

        local callback = State.handlers[name]
        if not callback or not isValidCallback(name) then
            sendCallbackResponse(resourceName, key, "invalid_cb")
            return
        end

        sendCallbackResponse(resourceName, key, Utils.callbackResponse(pcall(callback, ...)))
    end)

    State.registered[name] = true
end

---@param eventSource number|string
---@param name any
---@param resourceName any
---@param key any
---@return boolean
local function handleValidationEvent(eventSource, name, resourceName, key)
    if eventSource == "" then
        return false
    end

    if not Validator.arguments(false, {
        { name, "string" },
        { resourceName, { "string", "nil" } },
        { key, { "string", "number" } },
    }) then
        return false
    end

    if not isValidCallback(name) then
        sendCallbackResponse(resourceName, key, "invalid_cb")
    end

    return true
end

local prototype = {
    __call = function(_, event, cb, ...)
        if cb == nil then
            error(("callback event %s requires callback function\nuse callback.await for sync flow"):format(event))
        end

        return requestServerCallback(event, cb, ...)
    end,
}

local xCallbacks = setmetatable({
    pending = State.pending,
    event = State.event,
    timeout = State.timeout,
}, prototype)

RegisterNetEvent(State.event:format(GetCurrentResourceName()), function(key, ...)
    resolvePending(source, key, ...)
end)

function xCallbacks.await(event, ...)
    return requestServerCallback(event, nil, ...)
end

function xCallbacks.register(name, cb)
    registerClientCallback(name, cb)
end

function xCallbacks.setValidCallback(name, isValid)
    return setValidCallback(name, isValid)
end

function xCallbacks.isValidCallback(name)
    return isValidCallback(name)
end

RegisterNetEvent(State.validateEvent, function(name, resourceName, key)
    handleValidationEvent(source, name, resourceName, key)
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    cleanupResource(resourceName)
end)

return xCallbacks
