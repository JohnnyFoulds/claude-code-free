#!/usr/bin/env bash
# record.sh — One-command demo recording for claude-code-free.
#
# Usage:
#   OPENROUTER_KEY=sk-or-v1-your-key bash docs/record.sh
#
# What it does:
#   1. Resets the environment (stops container, removes config, clears known_hosts)
#   2. Records the full install → SSH → Claude Code session via expect
#   3. Converts the recording to an animated SVG
#   4. Opens the SVG in your browser for review
#
# Requirements:
#   brew install expect asciinema
#   npm install -g svg-term-cli
#
# Output:
#   docs/demo.svg   — the animated SVG ready to embed in README.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAST_FILE="/tmp/claude-code-free-demo.cast"
CAST_V2_FILE="/tmp/claude-code-free-demo-v2.cast"
SVG_OUT="${SCRIPT_DIR}/demo.svg"

# ---------------------------------------------------------------------------
# Check requirements
# ---------------------------------------------------------------------------
for tool in expect asciinema svg-term; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Missing: $tool"
        echo "Install with:"
        echo "  brew install expect asciinema"
        echo "  npm install -g svg-term-cli"
        exit 1
    fi
done

if [[ -z "${OPENROUTER_KEY:-}" ]]; then
    echo "Error: OPENROUTER_KEY is not set."
    echo "Usage: OPENROUTER_KEY=sk-or-v1-... bash docs/record.sh"
    exit 1
fi

# ---------------------------------------------------------------------------
# Reset to clean state
# ---------------------------------------------------------------------------
echo "[1/5] Resetting environment..."
docker stop claude-code-free 2>/dev/null || true
docker rm   claude-code-free 2>/dev/null || true
rm -rf ~/.claude-code-free
ssh-keygen -R "[localhost]:2223" 2>/dev/null || true
echo "      Clean."

# ---------------------------------------------------------------------------
# Record
# ---------------------------------------------------------------------------
echo "[2/5] Recording session (this takes 2-4 minutes)..."
asciinema rec "$CAST_FILE" \
    --cols 110 \
    --rows 30 \
    --overwrite \
    --command "expect ${SCRIPT_DIR}/record.exp"

echo "      Recorded to $CAST_FILE"

# ---------------------------------------------------------------------------
# Convert to asciicast v2 (svg-term requires v2)
# ---------------------------------------------------------------------------
echo "[3/5] Converting to asciicast v2..."
asciinema convert -f asciicast-v2 "$CAST_FILE" "$CAST_V2_FILE" --overwrite
echo "      Converted."

# ---------------------------------------------------------------------------
# Render SVG
# ---------------------------------------------------------------------------
echo "[4/5] Rendering SVG..."
cat "$CAST_V2_FILE" | svg-term \
    --out "$SVG_OUT" \
    --window \
    --width 110 \
    --height 30

echo "      Saved to $SVG_OUT ($(du -sh "$SVG_OUT" | cut -f1))"

# ---------------------------------------------------------------------------
# Open for review
# ---------------------------------------------------------------------------
echo "[5/5] Opening in browser for review..."
open "$SVG_OUT"

echo ""
echo "Done. To add to README.md:"
echo "  ![claude-code-free demo](docs/demo.svg)"
echo ""
echo "Then: git add docs/demo.svg README.md && git commit -m 'docs: add animated demo'"
