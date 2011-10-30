# Copyright (C) 2011 by Wayne Walker <wwalker@solid-constructs.com>
#
# Released under one of the versions of the MIT License.
#
# See LICENSE for details

_LIVE_AGENT_LIST=""

_debug_print() {
	if [[ $_DEBUG -gt 0 ]]
	then
		printf "%s\n" $1
	fi
}

find_all_ssh_agent_sockets() {
	_SSH_AGENT_SOCKETS=`find /tmp -type s -name agent.\* 2> /dev/null | grep '/tmp/ssh-.*/agent.*'`
	_debug_print "$_SSH_AGENT_SOCKETS"
}

find_all_gpg_agent_sockets() {
	_GPG_AGENT_SOCKETS=`find /tmp -type s -name S.gpg-agent.ssh 2> /dev/null | grep '/tmp/gpg-.*/S.gpg-agent.ssh'`
	_debug_print "$_GPG_AGENT_SOCKETS"
}

find_all_gnome_keyring_agent_sockets() {
	_GNOME_KEYRING_AGENT_SOCKETS=`find /tmp -type s -name ssh 2> /dev/null | grep '/tmp/keyring-.*/ssh$'`
	_debug_print "$_GNOME_KEYRING_AGENT_SOCKETS"
}

find_ssh_agent_pids() {
	_SSH_AGENT_PIDS=`pgrep ssh-agent`
	_debug_print "$_SSH_AGENT_PIDS"
}

find_gpg_agent_pids() {
	_GPG_AGENT_PIDS=`pgrep gpg-agent`
	_debug_print "$_GPG_AGENT_PIDS"
}

find_gnome_keyring_agent_pids() {
	_GNOME_KEYRING_AGENT_PIDS=`pgrep -f gnome-keyring-daemon`
	_debug_print "$_GNOME_KEYRING_AGENT_PIDS"
}

test_agent_socket() {
	local SOCKET=$1
	SSH_AUTH_SOCK=$SOCKET ssh-add -l 2> /dev/null > /dev/null
	result=$?

	_debug_print $result

	if [[ $result -eq 0 ]]
	then
		# contactible and has keys loaded
		_KEY_COUNT=`SSH_AUTH_SOCK=$SOCKET ssh-add -l | wc -l`
	fi

	if [[ $result -eq 1 ]]
	then
		# contactible butno keys loaded
		_KEY_COUNT=0
	fi

	if [[ ( ( $result -eq 0 ) || ( $result -eq 1 ) ) ]]
	then
		if [[ -n "$_LIVE_AGENT_LIST" ]]
		then
			_LIVE_AGENT_LIST="${_LIVE_AGENT_LIST} ${SOCKET}:$_KEY_COUNT"
		else
			_LIVE_AGENT_LIST="${SOCKET}:$_KEY_COUNT"
		fi
		return 0
	fi

	return 1
}

find_live_gnome_keyring_agents() {
	for i in $_GNOME_KEYRING_AGENT_SOCKETS
	do
		test_agent_socket $i
	done
}

find_live_gpg_agents() {
	for i in $_GPG_AGENT_SOCKETS
	do
		test_agent_socket $i
	done
}

find_live_ssh_agents() {
	for i in $_SSH_AGENT_SOCKETS
	do
		test_agent_socket $i
	done
}


find_all_agent_sockets() {
	find_all_ssh_agent_sockets
	find_ssh_agent_pids
	find_all_gpg_agent_sockets
	find_gpg_agent_pids
	find_all_gnome_keyring_agent_sockets
	find_gnome_keyring_agent_pids
	find_live_ssh_agents
	find_live_gpg_agents
	find_live_gnome_keyring_agents
	_debug_print "$_LIVE_AGENT_LIST"
	printf "%s\n" "$_LIVE_AGENT_LIST" | sed -e 's/ /\n/g' | sort -n -t: -k 2
}

