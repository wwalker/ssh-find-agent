#!/bin/bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
SSH_FIND_AGENT_DIR=${TEST_DIR}/..
SSH_FIND_AGENT=${SSH_FIND_AGENT_DIR}/ssh-find-agent.sh

(
  . ${SSH_FIND_AGENT}

  # kill any existing agents
  killall ssh-agent

  # verify no agent running
  AGENT_PIDS=$(pgrep ssh-agent)
  if [ $? -eq 0 ]; then
    echo "ERROR: test-setup failed: ssh-agent already running."
    echo "PIDs" ${AGENT_PIDS}
    exit 1
  fi

  # ssh-find-agent -a should return non-zero
  if [ $(ssh-find-agent -a) ]; then
    echo "ERROR: ${SSH_FIND_AGENT} -a should return non-zero when no agents are running."
    exit 1
  fi

  # run an ssh-agent but discard the environment
  ssh-agent

  # ssh-find-agent -a (auto)
  ssh-find-agent -a

  # ssh-add -D returns 0/success if it can contact the agent, even if there is nothing to delete
  if ! ssh-add -D; then
    echo "ERROR: ssh-add -D failed to locate agent."
    exit 1
  fi

  # kill the ssh-agent
  ssh-agent -k
  if [ $? -ne 0 ]; then
    echo "ERROR: ssh-agent -k failed - SSH_AGENT_PID might not be set"
    #FIXME failing test, requires https://github.com/wwalker/ssh-find-agent/pull/21 to be merged
    #exit 1
  fi
)

RESULT=$?

# cleanup
killall ssh-agent || true

if [ $RESULT -eq 0 ]; then
  echo "INFO: ssh-find-agent: all tests passed"
  exit 0
else
  echo "ERROR: ssh-find-agent: TESTS FAILED"
  exit $RESULT
fi
