# ssh-find-agent

ssh-find-agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain); and, optionally, setting `SSH_AUTH_SOCK` accordingly.

## Usage

somewhere in shell initialization (`~/.bashrc` or `~./.zshrc`)

```bash
. ssh-find-agent.sh
set_ssh_agent_socket
if [ -z "$SSH_AUTH_SOCK" ]
then
   eval $(ssh_agent) > /dev/null
   ssh-add -l >/dev/null || alias ssh='ssh-add -l >/dev/null || ssh-add && unalias ssh; ssh'
fi
```

## Status

Instead of this script you could/should use [keychain](https://github.com/funtoo/keychain)
