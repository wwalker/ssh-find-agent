# ssh-find-agent

ssh-find-agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain); and, optionally, setting `SSH_AUTH_SOCK` accordingly.

Pay attention to code below: create a new agent and/or create alias for temporal *ssh*:

```bash
if [ -z "$_LIVE_AGENT_LIST" ]
then
	echo "No agents found"
	read -p "Create an agent and add keys (y/n)?" -n 1 -r
	echo # (optional) move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		if [ -z "$SSH_AUTH_SOCK" ]
		then
			eval "$(ssh-agent -s)" > /dev/null
			ssh-add -l > /dev/null || alias ssh='ssh-add -l >/dev/null || ssh-add && unalias ssh; ssh'
		fi
	elif  [[ ! $REPLY =~ ^[Yy]$ ]]; then
		:
	fi
else
	ssh-add -l > /dev/null || alias ssh='ssh-add -l >/dev/null || ssh-add && unalias ssh; ssh'
fi
```
Temporal *ssh* alias will prompt for public-key passphrase at the very firt execution of *ssh*.

## Usage

Somewhere in shell initialization (`~/.bashrc` or `~/.zshrc`)

```bash
. /path/to/ssh-find-agent.sh
# or
source /path/to/ssh-find-agent.sh
```

Without any arguments, it just lists existing agents. But no agents exist, it prompts to create a new one. If no keys added, it creates temporal *ssh* alias. Use `type ssh` to test the alias. The temporal alias guarantees the very first execution of *ssh* prompots for public-key passphrase to add keys.

```bash
ssh-find-agent
```

Argument `-a` *automatically* chooses the first agent:

```bash
ssh-find-agent -a
```

Argument `-c` let you choose the agent *manually*:

```bash
ssh-find-agent -c
```

### NOTE

1. The choose option is Useful when you actually want multiple agents forwaded.  eg. pairing
2. Whether with arguments or not, ssh-find-agent will prompt you to create one if no agents found.

## Status

## Alternatives

* [keychain](https://github.com/funtoo/keychain)
* [envoy](https://github.com/vodik/envoy)
