# ssh_find_agent

ssh_find_agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain); and, optionally, setting `SSH_AUTH_SOCK` accordingly.

## Build Status

[![Build Status](https://travis-ci.org/wwalker/ssh-find-agent.svg?branch=master)](https://travis-ci.org/wwalker/ssh-find-agent)


## Usage

Somewhere in shell initialization (`~/.bashrc` or `~./.zshrc`)

```bash
. ssh-find-agent.sh
```

Add the following to automatically choose the first agent
```bash
ssh_find_agent -a
if [ -z "$SSH_AUTH_SOCK" ]
then
   eval $(ssh-agent) > /dev/null
   ssh-add -l >/dev/null || alias ssh='ssh-add -l >/dev/null || ssh-add && unalias ssh; ssh'
fi
```

... or, as `ssh_find_agent` with `-a` or `-c` returns non-zero if it cannot find a live-agent, simply:

```bash
ssh_find_agent -a || eval $(ssh-agent) > /dev/null
```

To choose the agent manually run
```bash
ssh_find_agent -c
```

NOTE: The choose option is Useful when you actually want multiple agents forwaded.  eg. pairing

To list the agents run
```bash
ssh_find_agent
```

This will return a list of export commands that can be used to set the socket.
Should this output be executed it will set the socket to the last agent found.
```bash
eval $(ssh_find_agent)
```

## Status

## Alternatives

  * [keychain](https://github.com/funtoo/keychain)
  * [envoy](https://github.com/vodik/envoy)
