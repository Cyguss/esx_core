fx_version "cerulean"
game "gta5"

lua54 "yes"

author "EXLIB"
description "Simple tests for esx_lib"
version "1.0.0"

dependency "esx_lib"

shared_scripts {
    "@esx_lib/imports/shared/package/init.lua",
    -- "shared/tests.lua",
}

client_scripts {
    -- "client/client.lua"
}

server_scripts {
    "server/server.lua"
}
