local xCallbacks = require("@esx_lib/imports/client/callback/init")
local tests = require("shared/tests")

print(tests)

local resourceName = GetCurrentResourceName()

local function log(message, ...)
    print(("[^3%s^0] " .. message):format(resourceName, ...))
end

xCallbacks.register(tests.callbacks.client, function(message, value)
    local numberValue = tonumber(value) or 0

    log(
        "client callback invoked: message=%s value=%s",
        tostring(message),
        tostring(numberValue)
    )

    return true, tostring(message), numberValue + 1, GetGameTimer()
end)

local function runClientToServerAwait(message, value)
    local ok, success, mirrored, incremented, serverSource = pcall(
        xCallbacks.await,
        tests.callbacks.server,
        message,
        value
    )

    if not ok then
        log("client -> server await failed: %s", tostring(success))
        return
    end

    log(
        "client -> server await ok: success=%s mirrored=%s incremented=%s serverSource=%s",
        tostring(success),
        tostring(mirrored),
        tostring(incremented),
        tostring(serverSource)
    )
end

local function runClientToServerCallback(message, value)
    local ok, err = pcall(function()
        xCallbacks(tests.callbacks.server, function(success, mirrored, incremented, serverSource)
            log(
                "client -> server callback ok: success=%s mirrored=%s incremented=%s serverSource=%s",
                tostring(success),
                tostring(mirrored),
                tostring(incremented),
                tostring(serverSource)
            )
        end, message, value)
    end)

    if not ok then
        log("client -> server callback failed: %s", tostring(err))
        return
    end

    log("client -> server callback dispatched")
end

RegisterNetEvent(tests.events.serverResult, function(mode, ok, ...)
    if not ok then
        local err = ...
        log("server -> client %s failed: %s", tostring(mode), tostring(err))
        return
    end

    local success, mirrored, incremented, clientGameTimer = ...

    log(
        "server -> client %s ok: success=%s mirrored=%s incremented=%s clientGameTimer=%s",
        tostring(mode),
        tostring(success),
        tostring(mirrored),
        tostring(incremented),
        tostring(clientGameTimer)
    )
end)

RegisterCommand(tests.command, function()
    local token = ("token:%s:%s"):format(GetPlayerServerId(PlayerId()), GetGameTimer())

    log("starting callback tests with token=%s", token)

    runClientToServerAwait(token .. ":await", 10)
    runClientToServerCallback(token .. ":callback", 20)

    TriggerServerEvent(tests.events.runServerAwait, token .. ":server-await", 30)
    TriggerServerEvent(tests.events.runServerCallback, token .. ":server-callback", 40)
end, false)

AddEventHandler("onClientResourceStart", function(startedResource)
    if startedResource ~= resourceName then
        return
    end

    log("callback tests loaded. run /%s to execute", tests.command)
end)
