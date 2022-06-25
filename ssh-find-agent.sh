#!/bin/bash

# Copyright (C) 2011 by Wayne Walker <wwalker@solid-constructs.com>
#
# Released under one of the versions of the MIT License.
#
# Copyright (C) 2011 by Wayne Walker <wwalker@solid-constructs.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

_LIVE_AGENT_LIST=""
declare -a _LIVE_AGENT_SOCK_LIST
_LIVE_AGENT_SOCK_LIST=()

# temp dir. Defaults to /tmp
TMPDIR="${TMPDIR:-/tmp}"

_debug_print() {
  if [[ $_DEBUG -gt 0 ]]
  then
    printf "%s\n" "$1"
  fi
}

find_all_ssh_agent_sockets() {
  _SSH_AGENT_SOCKETS=$( find "$TMPDIR" -maxdepth 2 -type s -name agent.\* 2> /dev/null | grep '/ssh-.*/agent.*' )
  _debug_print "$_SSH_AGENT_SOCKETS"
}

find_all_gpg_agent_sockets() {
  _GPG_AGENT_SOCKETS=$( find "$TMPDIR" -maxdepth 2 -type s -name S.gpg-agent.ssh 2> /dev/null | grep '/gpg-.*/S.gpg-agent.ssh' )
  _debug_print "$_GPG_AGENT_SOCKETS"
}

find_all_gnome_keyring_agent_sockets() {
  _GNOME_KEYRING_AGENT_SOCKETS=$( find "$TMPDIR" -maxdepth 2 -type s -name ssh 2> /dev/null | grep '/keyring-.*/ssh$' )
  _debug_print "$_GNOME_KEYRING_AGENT_SOCKETS"
}

find_all_osx_keychain_agent_sockets() {
  _OSX_KEYCHAIN_AGENT_SOCKETS=$( find "$TMPDIR" -maxdepth 2 -type s -regex '.*/ssh-.*/agent..*$' 2> /dev/null )
  _debug_print "$_OSX_KEYCHAIN_AGENT_SOCKETS"
}

test_agent_socket() {
  local SOCKET=$1
  SSH_AUTH_SOCK=$SOCKET timeout 0.4 ssh-add -l 2> /dev/null > /dev/null
  result=$?

  _debug_print $result

  if [[ $result -eq 0 ]]
  then
    # contactible and has keys loaded
    _KEY_COUNT=$(SSH_AUTH_SOCK=$SOCKET ssh-add -l |& grep -c 'error fetching identities for protocol 1: agent refused operation' )
  fi

  if [[ $result -eq 1 ]]
  then
    # contactible but no keys loaded
    _KEY_COUNT=0
  fi

  if [[ $result -eq 2 ]]
  then
    # socket is dead, delete it
    rm -r ${SOCKET%/*} 2>&1 1>/dev/null
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
    test_agent_socket "$i"
  done
}

find_live_osx_keychain_agents() {
  for i in $_OSX_KEYCHAIN_AGENT_SOCKETS
  do
    test_agent_socket "$i"
  done
}

find_live_gpg_agents() {
  for i in $_GPG_AGENT_SOCKETS
  do
    test_agent_socket "$i"
  done
}

find_live_ssh_agents() {
  for i in $_SSH_AGENT_SOCKETS
  do
    test_agent_socket "$i"
  done
}

function fingerprints() {
  local file="$1"
  while read -r l; do
    [[ -n "$l" && ${l##\#} = "$l" ]] && ssh-keygen -l -f /dev/stdin <<<"$l"
  done < "$file"
}

find_all_agent_sockets() {
  _SHOW_IDENTITY=0
  if [ "$1" = "-i" ] ; then
    _SHOW_IDENTITY=1
  fi
  _LIVE_AGENT_LIST=
  find_all_ssh_agent_sockets
  find_all_gpg_agent_sockets
  find_all_gnome_keyring_agent_sockets
  find_all_osx_keychain_agent_sockets
  find_live_ssh_agents
  find_live_gpg_agents
  find_live_gnome_keyring_agents
  find_live_osx_keychain_agents
  _debug_print "$_LIVE_AGENT_LIST"
  _LIVE_AGENT_LIST=$(printf '%s\n' "$_LIVE_AGENT_LIST" | tr ' ' '\n' | sort -n -t: -k 2 -k 1 | uniq)
  _LIVE_AGENT_SOCK_LIST=()
  _debug_print "SORTED: $_LIVE_AGENT_LIST"

  if [ -e ~/.ssh/authorized_keys ] ; then
    _FINGERPRINTS=$(fingerprints ~/.ssh/authorized_keys)
  fi

  if [[ $_SHOW_IDENTITY -gt 0 ]]
  then
    i=0
    for a in $_LIVE_AGENT_LIST ; do
      sock=${a/:*/}
      _LIVE_AGENT_SOCK_LIST[$i]=$sock
      # technically we could have multiple keys forwarded
      # But I haven't seen anyone do it
      akeys=$(SSH_AUTH_SOCK=$sock ssh-add -l |& grep -v 'error fetching identities for protocol 1: agent refused operation' )
      key_size=$(echo "${akeys}" | awk '{print $1}')
      fingerprint=$(echo "${akeys}" | awk '{print $2}')
      remote_name=$(echo "${akeys}" | awk '{print $3}')
      if [ -e ~/.ssh/authorized_keys ] ; then
        authorized_entry=$(fingerprints ~/.ssh/authorized_keys | grep "$fingerprint")
      fi
      comment=$(echo "${authorized_entry}" | awk '{print $3,$4,$5,$6,$7}')
      printf "export SSH_AUTH_SOCK=%s \t#%i) \t%s\n" "$sock" $((i+1)) "$comment"
      i=$((i+1))
    done
  else
    printf "%s\n" "$_LIVE_AGENT_LIST" | sed -e 's/ /\n/g' | sort -n -t: -k 2 -k 1
  fi
}

set_ssh_agent_socket() {
  if [[ "$1" = "-c" ]] || [[ "$1" = "--choose" ]]
  then
    find_all_agent_sockets -i

    if [ -z "$_LIVE_AGENT_LIST" ] ; then
      echo "No agents found"
      return 1
    fi

    echo -n "Choose (1-${#_LIVE_AGENT_SOCK_LIST[@]})? "
    read -r choice
    if [ -n "$choice" ]
    then
      n=$((choice-1))
      if [ -z "${_LIVE_AGENT_SOCK_LIST[$n]}" ] ; then
        echo "Invalid choice"
        return 1
      fi
      echo "Setting export SSH_AUTH_SOCK=${_LIVE_AGENT_SOCK_LIST[$n]}"
      export SSH_AUTH_SOCK=${_LIVE_AGENT_SOCK_LIST[$n]}
    fi
  else
    # Choose the first available
    SOCK=$(find_all_agent_sockets|tail -n 1|awk -F: '{print $1}')
    if [ -z "$SOCK" ] ; then
      return 1
    fi
    export SSH_AUTH_SOCK=$SOCK
  fi

  # set agent pid
  if [ -n "$SSH_AUTH_SOCK" ] ; then
    export SSH_AGENT_PID=$(($(basename "$SSH_AUTH_SOCK" | cut -d. -f2) + 1))
  fi

  return 0
}

_sfa_usage(){
  printf 'ssh-find-agent <[-c|--choose|-a|--auto|-h|--help]>\n'
}

# Renamed for https://github.com/wwalker/ssh-find-agent/issues/12
ssh_find_agent() {
  case $1 in
    -c|--choose)
      set_ssh_agent_socket -c
      return $?
      ;;
    -a|--auto)
      set_ssh_agent_socket
      return $?
      ;;
    "")
      find_all_agent_sockets -i
      return 0
      ;;
    *)
      _sfa_usage
      ;;
  esac
}

# Original function name is still supported.
# https://github.com/wwalker/ssh-find-agent/issues/12 points out that I
# should use ssh_find_agent() for best compatibility.
ssh-find-agent() {
  ssh_find_agent "$@"
}
