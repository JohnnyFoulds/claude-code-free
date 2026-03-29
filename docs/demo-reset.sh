#!/usr/bin/env bash
# demo-reset.sh — Clean slate before recording.
# Stops container, wipes config, clears known_hosts, opens a clean shell.

docker stop claude-code-free 2>/dev/null || true
docker rm   claude-code-free 2>/dev/null || true
rm -rf ~/.claude-code-free
ssh-keygen -R "[localhost]:2223" 2>/dev/null || true

exec env -i HOME="$HOME" TERM=xterm-256color PATH="$PATH" OPENROUTER_KEY="${OPENROUTER_KEY:-}" \
    bash --norc --noprofile --init-file <(echo "PS1='$ '")
