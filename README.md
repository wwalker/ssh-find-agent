# ssh-find-agent

ssh-find-agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain); and, optionally, setting `SSH_AUTH_SOCK` accordingly.

Pay attention to code below: create a new agent and add/cache keys to it:

```
if [ -z "$SSH_AUTH_SOCK" ]
then
   eval $(ssh_agent) > /dev/null
   ssh-add -l >/dev/null || alias ssh='ssh-add -l >/dev/null || ssh-add && unalias ssh; ssh'
fi
```

## Usage

Somewhere in shell initialization (`~/.bash_profile`, `~/.bashrc` or `~/.zshrc`)

```bash
. /path/to/ssh-find-agent.sh
or
source /path/to/ssh-find-agent.sh
```

Argument `-a` *automatically* choose the first agent:

```bash
ssh-find-agent -a
```

Argument `-c` let you choose the agent *manually*:

```bash
ssh-find-agent -c
```

Without any arguments, it just list existing agents:

```bash
ssh-find-agent
```

### NOTE

1. The choose option is Useful when you actually want multiple agents forwaded.  eg. pairing
2. Whether with arguments or not, ssh-find-agent will prompt you to create one if no agents found.

## Status

## Alternatives

* [keychain](https://github.com/funtoo/keychain)
* [envoy](https://github.com/vodik/envoy)
