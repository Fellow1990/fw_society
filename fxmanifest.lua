fx_version 'cerulean'

game 'gta5'
lua54 'yes'

description 'Provides a way for Jobs to have a society system. (boss menu, salaries, funding etc)'
lua54 'yes'
version '1.0'

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
    'esx_addonaccount'
}