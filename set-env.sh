#!/bin/sh
# Claude Code environment — loaded by /etc/profile.d/ for all login shells.
#
# Credentials (ANTHROPIC_*) are injected at runtime by Kubernetes via the
# openrouter-creds secret. This file only sets non-secret defaults and
# propagates the runtime env vars into login shells (needed because SSH
# sessions don't inherit the container's process environment directly).
#
# The actual values come from /etc/environment which is written by the
# entrypoint from the container's env vars.

if [ -f /etc/claude-code-env ]; then
    . /etc/claude-code-env
fi
