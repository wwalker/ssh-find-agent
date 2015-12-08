# ssh-find-agent

ssh-find-agent is a tool:

1. locating existing ssh compatible agent sockets (e.g., ssh-agent, gpg-agent, gnome-keyring, osx-keychain).
2. prompt to create one if no agents found.
3. optionally (invoked with `-a` or `-c`), sets `SSH_AUTH_SOCK`, `SSH_AGENT_PID` environment variables accordingly.
    1. and/or set temporal ssh alias

```bash
create_an_agent_socket() {
    echo "No agents found"
    read -p "Create an agent and add keys (y/n)?" -n 1 -r
    echo # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
	if [ -z "$SSH_AUTH_SOCK" && -z "$SSH_AGENT_PID"]; then
	    eval "$(ssh-agent -s)" > /dev/null
	fi
    else
        echo "Exit without creating"
        # kill -INT $$
        return 1
    fi
}

ssh-add -l > /dev/null || alias ssh='ssh-add -l > /dev/null || ssh-add && unalias ssh; ssh'
```

1. Temporal *ssh* alias will prompt for public-key passphrase at the very firt execution of *ssh*.

    As you know, `ssh-add` without any arguments only add default keys *~/.ssh/id_rsa*, *~/.ssh/id_dsa* and *~/.ssh/identity*. Other keys (i.e. defined in *~/ssh/config*) won't be added!
2. Many ssh-related commands depends on current X/shell `SSH_AUTH_SOCK` and `SSH_AGENT_PID` variables. If you login a system as a different user account or login into another virtual terminal/console, these two environment variables are probably not exported, thusing causing errors.

    In such a login environment, commands like `ssh-add` and `ssh-agent -k` will report error since it cannot find `SSH_AUTH_SOCK` variable:

        Could not open a connection to your authentication agent.

## Usage

Somewhere in shell initialization (`~/.bashrc` or `~/.zshrc`). Since the script will also export environment variables, it should be *sourced* instead of *direct execution* on shell prompt.

```bash
. /path/to/ssh-find-agent.sh
# or
source /path/to/ssh-find-agent.sh
```

Without any arguments, it just lists existing agents on system.

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

1. Regardless of arguments or not, if no agents exist on system, it prompts to create one for current shell/X session.
2. With `-a` or `-c` argument, if no keys added to the selected agent, it will create temporal *ssh* alias. Use `type ssh` to check the alias. The temporal alias guarantees the very first execution of *ssh* prompots for public-key passphrase to add keys.

### NOTE

1. The `-c || --choose` option is useful when you actually want multiple agents forwaded.  eg. pairing
2. Whether with arguments or not, ssh-find-agent will prompt you to create one if no agents found.

## Status

1. <s>Aslo export `SSH_AGENT_PID`.</s> Yes.
2. <s>`~ $ ssh-add` only add default key files?</s> Yes.

## Alternatives

* [keychain](https://github.com/funtoo/keychain)
* [envoy](https://github.com/vodik/envoy)
