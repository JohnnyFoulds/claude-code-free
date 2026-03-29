#!/bin/sh
# Claude Code environment — loaded by /etc/profile.d/ for all login shells.
#
# SSH sessions do not inherit the container's process environment directly,
# so ANTHROPIC_* credentials would not be visible to Claude Code when
# connecting via VS Code Remote SSH.
#
# entrypoint.sh writes the runtime ANTHROPIC_* values to /etc/claude-code-env
# at container start. This script sources that file so every login shell
# (including VS Code terminals) has the credentials available.

if [ -f /etc/claude-code-env ]; then
    . /etc/claude-code-env
fi
