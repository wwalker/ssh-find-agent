# ssh-find-agent

ssh-find-agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain); and, optionally, setting `SSH_AUTH_SOCK` accordingly.

## Usage

Somewhere in shell initialization (`~/.bashrc` or `~./.zshrc`)

```bash
. ssh-find-agent.sh
```

Add the following to automatically choose the first agent
```bash
set_ssh_agent_socket
if [ -z "$SSH_AUTH_SOCK" ]
then
   eval $(ssh_agent) > /dev/null
   ssh-add -l >/dev/null || alias ssh='ssh-add -l >/dev/null || ssh-add && unalias ssh; ssh'
fi
```

To choose the agent manually run
```set_ssh_agent_socket -c```

NOTE: The choose option is Useful when you actually want multiple agents forwaded.  eg. pairing

## Status

## Alternatives

  * [keychain](https://github.com/funtoo/keychain)
  * [envoy](https://github.com/vodik/envoy)
