fx_version 'cerulean'

game 'gta5'
lua54 'yes'

author 'fellow25'
description 'FW Society (ESX Society modified with ox_lib)'
version '1.0.3'

shared_script {
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
    '@ox_lib/init.lua',
    'shared/*.lua',
    'locales/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'es_extended',
    'cron',
    'esx_addonaccount'
}