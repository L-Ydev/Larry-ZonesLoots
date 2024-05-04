fx_version 'cerulean'

game 'gta5'
lua54 'yes'
version '1.0.0'
author 'Larrydev'
description 'Besoin de script perso ? discord : larry2_0'

ui_page 'html/index.html'

shared_scripts { 
	'@es_extended/imports.lua',
	'@es_extended/locale.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config.lua',
	'server.lua'
}

client_scripts {
	'config.lua',
	'cl_nui.lua',
	'client.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib'
}
