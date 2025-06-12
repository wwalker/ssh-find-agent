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

sfa_init() {
  _ssh_agent_sockets=()
  _live_agent_list=()
  _live_agent_sock_list=()
  _sorted_live_agent_list=()
  _sfa_timeout=1.0
  _sfa_no_timeout_command=0

  # Set $sfa_path array to the dirs to search for ssh-agent sockets
  sfa_set_path

  if ! command -v 'timeout' &>/dev/null; then
    printf "ssh-find-agent.sh: 'timeout' command could not be found.\n"
    printf "  Please install 'coreutils' via your system's package manager.\n"
    printf "Meanwhile, we will run without \`timeout\` support.\n"
    printf "  This may cause delays or complete hangs if the agent is slow or unresponsive.\n"
    _sfa_no_timeout_command=1
  fi
}

# Allow users to override the default path to search for ssh-agent sockets
# The first of the variable found is used to set the path:
#   SSH_FIND_AGENT_PATH (colon separated dir list)
#   _TMPDIR_OVERRIDE for legacy compatibility
#   TMPDIR (if set) (plus /tmp due to ssh bug)
sfa_set_path() {
  sfa_path=()
  if [[ -n "$SSH_FIND_AGENT_PATH" ]]; then
    IFS=':' read -r -a sfa_path <<<"$SSH_FIND_AGENT_PATH"
  else
    # Maintain backwards compatibility with the old _TMPDIR_OVERRIDE variable
    if [[ -n "$_TMPDIR_OVERRIDE" ]]; then
      sfa_path=("$_TMPDIR_OVERRIDE")
    else
      if [[ -n "$TMPDIR" ]]; then
        sfa_path=("/tmp" "$TMPDIR")
      else
        sfa_path=("/tmp")
      fi
    fi
  fi
}

sfa_err() {
  # shellcheck disable=SC2059
  printf "$@" 1>&2
}

sfa_debug() {
  if ((_DEBUG > 0)); then
    sfa_err "$@" 1>&2
  fi
}

sfa_find_all_agent_sockets() {
  _ssh_agent_sockets=($(
    find "${sfa_path[@]}" -maxdepth 2 -type s -name agent.\* \
      -o -name S.gpg-agent.ssh -o -name ssh -o -regex '.*/ssh-.*/agent..*$' \
      2>/dev/null | grep -E \
      '/ssh-.*/agent.*|/gpg-  .*/S.gpg-agent.ssh|/keyring-.*/ssh$|.*/ssh-.*/agent..*$'
  ))

  sfa_debug "${_ssh_agent_sockets[@]}"
}

sfa_test_agent_socket() {
  local socket=$1
  local output

  if [[ _sfa_no_timeout_command -eq 1 ]]; then
    output=$(SSH_AUTH_SOCK=$socket sh-add -l 2>&1)
  else
    output=$(SSH_AUTH_SOCK=$socket timeout "$_sfa_timeout" ssh-add -l 2>&1)
  fi
  result=$?

  [[ "$output" == "error fetching identities: communication with agent failed" ]] && result=2
  sfa_debug $result

  case $result in
    0 | 1 | 141)
      # contactible and has keys loaded
      {
        OIFS="$IFS"
        IFS=$'\n'
        # shellcheck disable=SC2207
        _keys=($(SSH_AUTH_SOCK=$socket ssh-add -l 2>/dev/null))
        IFS="$OIFS"
      }
      _live_agent_list+=("${#_keys[@]}:$socket")
      return 0
      ;;
    2 | 124)
      # socket is dead, delete it
      sfa_err 'socket (%s) is dead, removing it.\n' "$socket"
      sfa_debug "rm -rf ${socket%/*}"
      rm -rf "${socket%/*}"
      ;;
    125 | 126 | 127)
      sfa_err 'timeout returned <%s>\n' "$result" 1>&2
      ;;
    *)
      sfa_err 'Unknown failure timeout returned <%s>\n' "$result" 1>&2
      ;;
  esac

  case $result in
    0 | 1)
      _live_agent_list+=("$_key_count:$socket")
      return 0
      ;;
  esac

  return 1
}

sfa_verify_sockets() {
  for i in "${_ssh_agent_sockets[@]}"; do
    sfa_test_agent_socket "$i"
  done
}

sfa_fingerprints() {
  local file="$1"
  while read -r l; do
    [[ -n "$l" && ${l##\#} = "$l" ]] && ssh-keygen -l -f /dev/stdin <<<"$l"
  done <"$file"
}

sfa_print_choose_menu() {
  # find all the apparent socket files
  # the sockets go into $_ssh_agent_sockets[]
  sfa_find_all_agent_sockets

  # verify each socket, discarding if dead
  # the live sockets go into $_live_agent_list[]
  sfa_verify_sockets
  sfa_debug '<%s>\n' "${_live_agent_list[@]}"

  # shellcheck disable=SC2207
  IFS=$'\n' _sorted_live_agent_list=($(sort -u <<<"${_live_agent_list[*]}"))
  unset IFS

  sfa_debug "SORTED:\n"
  sfa_debug '    <%s>\n' "${_sorted_live_agent_list[@]}"

  local i=0
  local sock

  for agent in "${_sorted_live_agent_list[@]}"; do
    i=$((i + 1))
    sock=${agent/*:/}
    if [[ "$1" = "-i" ]]; then
      _live_agent_sock_list[i]=$sock

      printf '#%i)\n' "$i"
      printf '    export SSH_AUTH_SOCK=%s\n' "$sock"
      # Get all the forwarded keys for this agent, parse them and print them
      SSH_AUTH_SOCK=$sock ssh-add -l 2>&1 |
        grep -v 'error fetching identities for protocol 1: agent refused operation' |
        while IFS= read -r key; do
          parts=("$key")
          key_size="${parts[0]}"
          fingerprint="${parts[1]}"
          remote_name="${parts[2]}"
          key_type="${parts[3]}"
          printf '        %s %s\t%s\t%s\n' "$key_size" "$key_type" "$remote_name" "$fingerprint"
        done
    else
      printf '%s\n' "$sock"
    fi
  done
}

sfa_set_ssh_agent_socket() {
  case $1 in
    -c | --choose)
      sfa_print_choose_menu -i

      ((0 == ${#_live_agent_list[@]})) && {
        sfa_err 'No agents found.\n'
        return 1
      }

      read -p "Choose (1-${#_live_agent_sock_list[@]})? " -r choice
      if [ "$choice" -eq "$choice" ]; then
        [[ -z "${_live_agent_sock_list[$choice]}" ]] && {
          sfa_err 'Invalid choice.\n'
          return 1
        }
        printf 'Setting export SSH_AUTH_SOCK=%s\n' "${_live_agent_sock_list[$choice]}"
        export SSH_AUTH_SOCK=${_live_agent_sock_list[$choice]}
      fi
      ;;
    -a | --auto)
      # Choose the last one, as they are sorted numerically by how many keys they have
      sock=$(sfa_print_choose_menu | tail -n -1)
      [[ -z "$sock" ]] && return 1
      sfa_debug 'export SSH_AUTH_SOCK=%s\n' "$sock"
      export SSH_AUTH_SOCK=$sock
      ;;
    *)
      sfa_usage
      ;;
  esac

  # set agent pid - this is unreliable as the pid may be of the child rather than the agent
  if [ -n "$SSH_AUTH_SOCK" ]; then
    export SSH_AGENT_PID=$(($(basename "$SSH_AUTH_SOCK" | cut -d. -f2) + 1))
  fi

  return 0
}

sfa_usage() {
  sfa_err 'ssh-find-agent <[-c|--choose|-a|--auto|-h|--help]>\n'
  return 1
}

# Renamed for https://github.com/wwalker/ssh-find-agent/issues/12
ssh_find_agent() {
  sfa_init

  case $1 in
    -c | --choose | -a | --auto)
      sfa_set_ssh_agent_socket "$1"
      return $?
      ;;
    -l | --list)
      sfa_print_choose_menu -i
      ;;
    *)
      sfa_usage
      ;;
  esac
}

# Original function name is still supported.
# https://github.com/wwalker/ssh-find-agent/issues/12 points out that I
# should use ssh_find_agent() for best compatibility.
ssh-find-agent() {
  ssh_find_agent "$@"
}
