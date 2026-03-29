#!/usr/bin/env bash
# record-driver.sh — Sends keystrokes to kitty via remote control socket.
#
# Called by record-kitty.sh. Drives the full demo:
#   curl install → prompts → container start → SSH → Claude Code → exit
#
# Required env vars:
#   OPENROUTER_KEY   Your OpenRouter API key
#   KITTY_SOCK       Path to kitty's unix socket (e.g. /tmp/kitty-demo.sock)
#   DONE_FILE        Path to create when the session is complete
#
# Timing constants (tweak these to control how the demo looks):
#   CHAR_DELAY_MS    Milliseconds between each typed character
#   WORD_PAUSE_MS    Extra milliseconds after each space
#   PROMPT_PAUSE_MS  Pause before responding to a prompt (looks like user is reading)

set -euo pipefail

CHAR_DELAY_MS="${CHAR_DELAY_MS:-80}"
WORD_PAUSE_MS="${WORD_PAUSE_MS:-120}"
PROMPT_PAUSE_MS="${PROMPT_PAUSE_MS:-2000}"
KITTY_SOCK="${KITTY_SOCK:-/tmp/kitty-demo.sock}"
DONE_FILE="${DONE_FILE:-/tmp/kitty-demo-done}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

send() {
    # Send text to the kitty window. Carriage return: pass $'\r' as argument.
    kitty @ --to "unix:${KITTY_SOCK}" send-text -- "$1"
}

pause() {
    # Pause for N milliseconds
    sleep "$(echo "scale=3; $1 / 1000" | bc)"
}

type_slowly() {
    local text="$1"
    local i char
    for (( i=0; i<${#text}; i++ )); do
        char="${text:$i:1}"
        send "$char"
        if [[ "$char" == " " ]]; then
            pause "$WORD_PAUSE_MS"
        else
            pause "$CHAR_DELAY_MS"
        fi
    done
}

wait_for_output() {
    # Poll the kitty window text content until the given pattern appears.
    # $1 = grep pattern, $2 = timeout seconds (default 180)
    local pattern="$1"
    local timeout="${2:-180}"
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if kitty @ --to "unix:${KITTY_SOCK}" get-text 2>/dev/null | grep -q "$pattern"; then
            return 0
        fi
        sleep 1
        (( elapsed++ )) || true
    done
    echo "Timeout waiting for: $pattern" >&2
    return 1
}

# ---------------------------------------------------------------------------
# Session starts: wait for the shell prompt inside asciinema
# ---------------------------------------------------------------------------
# asciinema prints "asciinema: recording asciicast to ..." before the shell prompt
wait_for_output "recording asciicast" 30

pause 1000

# ---------------------------------------------------------------------------
# Type the curl install command
# ---------------------------------------------------------------------------
type_slowly "curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash"
pause 1000
send $'\r'

# ---------------------------------------------------------------------------
# Welcome screen — wait for it, pause so viewer can read it, then Enter
# ---------------------------------------------------------------------------
wait_for_output "Press Enter to continue" 60
pause "$PROMPT_PAUSE_MS"
send $'\r'

# ---------------------------------------------------------------------------
# API key prompt
# ---------------------------------------------------------------------------
wait_for_output "Paste your OpenRouter API key" 30
pause "$PROMPT_PAUSE_MS"
type_slowly "$OPENROUTER_KEY"
pause 800
send $'\r'

# ---------------------------------------------------------------------------
# Model ID — accept default
# ---------------------------------------------------------------------------
wait_for_output "Model ID" 30
pause "$PROMPT_PAUSE_MS"
send $'\r'

# ---------------------------------------------------------------------------
# Workspace — choose 1
# ---------------------------------------------------------------------------
wait_for_output "Choose" 30
pause "$PROMPT_PAUSE_MS"
send "1"
send $'\r'

# ---------------------------------------------------------------------------
# Container pull and start — wait up to 3 minutes
# ---------------------------------------------------------------------------
wait_for_output "Container started" 180
pause 1500

# ---------------------------------------------------------------------------
# "Try Claude Code right now?" — say yes
# ---------------------------------------------------------------------------
wait_for_output "Try Claude Code right now" 30
pause "$PROMPT_PAUSE_MS"
send "y"
send $'\r'

# ---------------------------------------------------------------------------
# Wait for SSH connect and Claude Code header
# ---------------------------------------------------------------------------
wait_for_output "Claude Code" 60
pause 2500

# ---------------------------------------------------------------------------
# Type the demo prompt
# ---------------------------------------------------------------------------
type_slowly "write a python function that reads a csv file and returns the top 5 rows sorted by a given column. include type hints and a docstring."
pause 800
send $'\r'

# ---------------------------------------------------------------------------
# Wait for Claude to finish responding — prompt returns as "❯"
# ---------------------------------------------------------------------------
wait_for_output "❯" 120
pause 3000

# ---------------------------------------------------------------------------
# Exit Claude Code
# ---------------------------------------------------------------------------
type_slowly "exit"
send $'\r'

# Give session time to close cleanly
sleep 2

# Signal completion
touch "$DONE_FILE"
