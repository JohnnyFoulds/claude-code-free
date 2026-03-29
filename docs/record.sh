#!/usr/bin/env bash
# record.sh — Produce the claude-code-free demo GIF.
#
# Usage:
#   bash docs/record.sh
#
# Requirements:
#   brew install vhs
#   docker/.env.local must contain OPENROUTER_API_KEY
#
# What it does:
#   1. Reads the API key from docker/.env.local
#   2. Resets the environment (stops container, removes config, clears known_hosts)
#   3. Injects the API key into a temp copy of demo.tape
#   4. Runs VHS to produce docs/demo.gif
#   5. Opens the GIF for review
#
# To re-record: just run this script again.
# To change what the demo shows: edit demo.tape, then re-run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TAPE_FILE="${SCRIPT_DIR}/demo.tape"
TEMP_TAPE="/tmp/demo-with-key.tape"

# ---------------------------------------------------------------------------
# Read API key from docker/.env.local
# ---------------------------------------------------------------------------
ENV_LOCAL="${REPO_ROOT}/../docker/.env.local"
if [[ ! -f "$ENV_LOCAL" ]]; then
    # Try one level up (when running from within the submodule checkout)
    ENV_LOCAL="${REPO_ROOT}/docker/.env.local"
fi

OPENROUTER_KEY=$(grep '^OPENROUTER_API_KEY=' "$ENV_LOCAL" 2>/dev/null \
    | cut -d= -f2- | tr -d "'" | tr -d '"' || true)

if [[ -z "$OPENROUTER_KEY" ]]; then
    echo "Error: OPENROUTER_API_KEY not found in $ENV_LOCAL"
    exit 1
fi

# ---------------------------------------------------------------------------
# Check requirements
# ---------------------------------------------------------------------------
if ! command -v vhs &>/dev/null; then
    echo "Error: vhs not installed. Run: brew install vhs"
    exit 1
fi

# ---------------------------------------------------------------------------
# Reset environment
# ---------------------------------------------------------------------------
echo "[1/4] Resetting environment..."
docker stop claude-code-free 2>/dev/null || true
docker rm   claude-code-free 2>/dev/null || true
rm -rf ~/.claude-code-free
ssh-keygen -R "[localhost]:2223" 2>/dev/null || true
echo "      Done."

# ---------------------------------------------------------------------------
# Inject API key into tape
# ---------------------------------------------------------------------------
echo "[2/4] Preparing tape file..."
sed "s|OPENROUTER_API_KEY_PLACEHOLDER|${OPENROUTER_KEY}|g" \
    "$TAPE_FILE" > "$TEMP_TAPE"
echo "      Done."

# ---------------------------------------------------------------------------
# Record
# ---------------------------------------------------------------------------
echo "[3/4] Recording (this takes 2-4 minutes)..."
cd "$SCRIPT_DIR"
vhs "$TEMP_TAPE"
rm -f "$TEMP_TAPE"
echo "      Done."

# ---------------------------------------------------------------------------
# Open for review
# ---------------------------------------------------------------------------
echo "[4/4] Opening for review..."
open -a Safari "${SCRIPT_DIR}/demo.gif"

echo ""
echo "Output: docs/demo.gif"
echo ""
echo "To publish:"
echo "  git add docs/demo.gif && git commit -m 'docs: update demo recording'"
