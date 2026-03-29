#!/usr/bin/env bash
# record-kitty.sh — Automated demo recording via the already-open kitty window.
#
# Usage:
#   OPENROUTER_KEY=sk-or-v1-your-key bash docs/record-kitty.sh
#
# Requirements:
#   brew install asciinema agg
#   kitty must be running with allow_remote_control=yes and listen_on set
#   (already configured in ~/.config/kitty/kitty.conf)
#
# Output:
#   docs/demo.gif

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAST_FILE="/tmp/claude-code-free-demo.cast"
CAST_V2_FILE="/tmp/claude-code-free-demo-v2.cast"
GIF_OUT="${SCRIPT_DIR}/demo.gif"
COLS=110
ROWS=30

# ---------------------------------------------------------------------------
# Find the kitty socket
# ---------------------------------------------------------------------------
SOCK=$(ls /tmp/kitty.sock-* 2>/dev/null | head -1)
if [[ -z "$SOCK" ]]; then
    echo "Error: no kitty socket found in /tmp/kitty.sock-*"
    echo "Make sure kitty is running with allow_remote_control=yes and listen_on set."
    exit 1
fi
echo "Using kitty socket: $SOCK"

# ---------------------------------------------------------------------------
# Check requirements
# ---------------------------------------------------------------------------
for tool in asciinema agg python3; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Missing: $tool  (brew install asciinema agg)"
        exit 1
    fi
done

# If OPENROUTER_KEY not set here, read it from the kitty window's environment
if [[ -z "${OPENROUTER_KEY:-}" ]]; then
    KITTY_WIN_ENV=$(kitty @ --to "unix:${SOCK}" ls 2>/dev/null)
    OPENROUTER_KEY=$(echo "$KITTY_WIN_ENV" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['tabs'][0]['windows'][0]['env'].get('OPENROUTER_KEY',''))" 2>/dev/null || true)
fi

if [[ -z "${OPENROUTER_KEY:-}" ]]; then
    echo "Error: OPENROUTER_KEY is not set in this shell or in the kitty window."
    exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
send() {
    kitty @ --to "unix:${SOCK}" send-text -- "$1"
}

pause() {
    sleep "$(echo "scale=3; $1 / 1000" | bc)"
}

type_slowly() {
    local text="$1" i char
    local char_delay="${CHAR_DELAY_MS:-80}"
    local word_pause="${WORD_PAUSE_MS:-120}"
    for (( i=0; i<${#text}; i++ )); do
        char="${text:$i:1}"
        send "$char"
        if [[ "$char" == " " ]]; then
            pause "$word_pause"
        else
            pause "$char_delay"
        fi
    done
}

wait_for() {
    local pattern="$1"
    local timeout="${2:-180}"
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if kitty @ --to "unix:${SOCK}" get-text 2>/dev/null | grep -q "$pattern"; then
            return 0
        fi
        sleep 1
        (( elapsed++ )) || true
    done
    echo "Timeout waiting for: $pattern" >&2
    return 1
}

# ---------------------------------------------------------------------------
# Reset environment
# ---------------------------------------------------------------------------
echo "[1/5] Resetting environment..."
docker stop claude-code-free 2>/dev/null || true
docker rm   claude-code-free 2>/dev/null || true
rm -rf ~/.claude-code-free
ssh-keygen -R "[localhost]:2223" 2>/dev/null || true
rm -f "$CAST_FILE" "$CAST_V2_FILE"
echo "      Clean."

# ---------------------------------------------------------------------------
# Start asciinema in the kitty window
# ---------------------------------------------------------------------------
echo "[2/5] Starting asciinema in kitty window..."

# Switch to a clean bash shell — no zsh prompt glyphs, no conda prefix, no fancy PS1
send "exec env -i HOME=\"$HOME\" TERM=xterm-256color PATH=\"$PATH\" bash --norc --noprofile\r"
pause 1000
send "PS1='$ '\r"
pause 500

send "asciinema rec ${CAST_FILE} --cols ${COLS} --rows ${ROWS} --overwrite\r"
pause 2000   # wait for asciinema to start

echo "      asciinema started."

# ---------------------------------------------------------------------------
# Drive the demo
# ---------------------------------------------------------------------------
echo "[3/5] Running demo..."
PROMPT_PAUSE="${PROMPT_PAUSE_MS:-2000}"

# Type the curl command
type_slowly "curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash"
pause 1000
send $'\r'

# Welcome screen
wait_for "Press Enter to continue" 60
pause "$PROMPT_PAUSE"
send $'\r'

# API key
wait_for "Paste your OpenRouter API key" 30
pause "$PROMPT_PAUSE"
type_slowly "$OPENROUTER_KEY"
pause 800
send $'\r'

# Model — accept default
wait_for "Model ID" 30
pause "$PROMPT_PAUSE"
send $'\r'

# Workspace — choose 1
wait_for "Choose" 30
pause "$PROMPT_PAUSE"
send "1"
send $'\r'

# Wait for container
wait_for "Container started" 180
pause 1500

# Try Claude Code now?
wait_for "Try Claude Code right now" 30
pause "$PROMPT_PAUSE"
send "y"
send $'\r'

# Wait for Claude Code to load
wait_for "Claude Code" 60
pause 2500

# Type the demo prompt
type_slowly "write a python function that reads a csv file and returns the top 5 rows sorted by a given column. include type hints and a docstring."
pause 800
send $'\r'

# Wait for Claude to finish
wait_for "❯" 120
pause 3000

# Exit
type_slowly "exit"
send $'\r'
pause 2000

# Stop asciinema (exit the recorded shell)
send "exit\r"
pause 1500

echo "      Demo complete."

# ---------------------------------------------------------------------------
# Convert v3 → v2
# ---------------------------------------------------------------------------
echo "[4/5] Converting cast to v2..."
python3 "${SCRIPT_DIR}/cast-v3-to-v2.py" "$CAST_FILE" "$CAST_V2_FILE"

# ---------------------------------------------------------------------------
# Render GIF
# ---------------------------------------------------------------------------
echo "[5/5] Rendering GIF..."
agg \
    --cols "$COLS" \
    --rows "$ROWS" \
    --font-size 14 \
    --speed 1.0 \
    --idle-time-limit 3 \
    "$CAST_V2_FILE" \
    "$GIF_OUT"

echo "Saved to $GIF_OUT ($(du -sh "$GIF_OUT" | cut -f1))"
open "$GIF_OUT"
