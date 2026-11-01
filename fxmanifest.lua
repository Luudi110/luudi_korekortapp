fx_version "cerulean"
game "gta5"
lua54 "yes"

author "luudi"
title "luudi_korekortapp"
description "LB Phone custom app: dansk kørekort (esx_license + p_policejob point)"
version "0.1"

shared_scripts {
    "@ox_lib/init.lua",
    "@es_extended/imports.lua",
    "config.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/main.lua",
}

client_scripts {
    "client/main.lua",
}

files {
    "web/**/*",
}

ui_page "web/index.html"

dependencies {
    "es_extended",
    "ox_lib",
    "oxmysql",
    "lb-phone",
}
