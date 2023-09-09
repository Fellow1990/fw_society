fx_version 'cerulean'

game 'gta5'
lua54 'yes'

author 'fellow25'
description 'FW Society'
version '1.0.0'

shared_script {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'shared/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

files {
	'locales/*.json'
}

dependencies {
    'es_extended',
    'cron',
    'esx_addonaccount'
}

escrow_ignore {
	'locales/*.json',
    'shared/*.lua'
}