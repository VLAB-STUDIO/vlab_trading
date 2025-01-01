author 'VLAB STUDIO @AxelWZ'
version '1.0'

fx_version "adamant"
lua54 "on"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game "rdr3"

shared_scripts {
    'config.lua',
}

client_scripts {
	'client.lua',
	'@uiprompt/uiprompt.lua',
}

server_scripts {
	'server.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
}

escrow_ignore {
	'config.lua'
}