# ssh-find-agent

ssh-find-agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain); and, optionally, setting `SSH_AUTH_SOCK` accordingly.

## Build Status

[![Build Status](https://travis-ci.org/wwalker/ssh-find-agent.svg?branch=master)](https://travis-ci.org/wwalker/ssh-find-agent)


## Usage

Somewhere in shell initialization (`~/.bashrc` or `~./.zshrc`)

```bash
source ssh-find-agent.sh # for bash
emulate ksh -c "source ssh-find-agent.sh" # for zsh
```

Add the following to automatically choose the first agent
```bash
ssh-add -l >&/dev/null || ssh-find-agent -a || eval $(ssh-agent) > /dev/null
```

To choose the agent manually run
```bash
ssh-find-agent -c
```

NOTE: The choose option is Useful when you actually want multiple agents forwarded.  E.g., while pairing.

To list the agents run
```bash
ssh-find-agent -l
```

This will return a list of export commands that can be used to set the socket.

Should this output be executed it will set the socket to the last agent found.
```bash
eval $(ssh-find-agent -l)
```

## Status

## Alternatives

  * [keychain](https://github.com/funtoo/keychain)
  * [envoy](https://github.com/vodik/envoy)
