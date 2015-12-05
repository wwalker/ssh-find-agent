# ssh-find-agent

ssh-find-agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain); and, optionally, setting `SSH_AUTH_SOCK` and `SSH_AGENT_PID` accordingly.

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
            fi
        elif  [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Exit without creating"
	    return
        fi
    else
	ssh-add -l &> /dev/null
	local status=$?
	if [[ $status -eq 1 ]]
	then
	    alias ssh='ssh-add -l > /dev/null || ssh-add && unalias ssh; ssh'
	    echo "Ready to run ssh"
	elif [[ $status -eq 2 ]]
	then
	    printf "Agent found!\n  Run with '-a' or '-c' argument to set SSH_AUTH_SOCK and SSH_AGENT_PID.\n"
	fi
    fi
```

1. Temporal *ssh* alias will prompt for public-key passphrase at the very firt execution of *ssh*. As you know, `ssh-add` without any arguments only add default keys *~/.ssh/id_rsa*, *~/.ssh/id_dsa* and *~/.ssh/identity*. Other keys (i.e. defined in *~/ssh/config*) won't be added!
2. `$status -eq 2` means agent exists on system. However, in current login/session `SSH_AUTH_SOCK` and `SSH_AGENT_PID` variables are not *export*ed. This happens when you login a system as a different user account or when you login in a different virtual terminal/console.

    In such a login environment, *ssh-add* will report error since it depends on `SSH_AUTH_SOCK` environment variable:

        Could not open a connection to your authentication agent.

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

1. <s>Aslo export `SSH_AGENT_PID`</s>.
2. <s>`~ $ ssh-add` only add default key files?</s> Yes.

## Alternatives

* [keychain](https://github.com/funtoo/keychain)
* [envoy](https://github.com/vodik/envoy)
