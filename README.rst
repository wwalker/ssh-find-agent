ssh-find-agent
==============

ssh-find-agent is a tool for locating existing ssh compatible agent processes (e.g., ssh-agent, gpg-agent, gnome-keyring); and, optionally, setting SSH_AUTH_SOCK accordingly.

ssh-find-agent is written in bash due to it's near ubiquitousness.

Usage
-----

Nowhere near done, but this works for now:

. ssh-find-agent.bash; find_all_agent_sockets

Copyright (C) 2011 by Wayne Walker <wwalker@solid-constructs.com>
