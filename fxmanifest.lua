fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'county-idnpc'
author 'County RP'
description 'Police ID desk NPC: players answer a short form and receive their id_card.'
version '1.0.0'

dependencies {
    'qb-core',
    'qb-menu',
    'qb-target',
    'oxmysql',
}

shared_script 'config.lua'
client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}
