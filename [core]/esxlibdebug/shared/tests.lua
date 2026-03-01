local baseName = "esxlibdebug:cb"

return {
    command = "esxcbtest",
    callbacks = {
        server = baseName .. ":server",
        client = baseName .. ":client",
    },
    events = {
        runServerAwait = baseName .. ":runServerAwait",
        runServerCallback = baseName .. ":runServerCallback",
        serverResult = baseName .. ":serverResult",
    },
}
