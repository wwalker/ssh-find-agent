# Copyright (C) 2011 by Wayne Walker <wwalker@solid-constructs.com>
#
# Released under one of the versions of the MIT License.
#
# See LICENSE for details

find_all_ssh_agent_sockets() {
	find /tmp -type s -name agent.\* 2> /dev/null | grep '/tmp/ssh-.*/agent.*'
}

find_all_gpg_agent_sockets() {
	find /tmp -type s -name S.gpg-agent 2> /dev/null | grep '/tmp/gpg-.*/S.gpg-agent'
}

find_all_gnome_keyring_agent_sockets() {
	find /tmp -type s -name ssh 2> /dev/null | grep '/tmp/keyring-.*/ssh$'
}

find_gpg_agent_processes() {
	pgrep gpg-agent
}

find_gnome_keyring_agent_processes() {
	pgrep -f gnome-keyring-daemon
}

find_all_agent_sockets() {
	find_all_ssh_agent_sockets
	find_all_gpg_agent_sockets
	find_gpg_agent_processes
	find_all_gnome_keyring_agent_sockets
	find_gnome_keyring_agent_processes
}

