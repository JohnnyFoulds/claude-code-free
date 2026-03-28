#!/usr/bin/env bash
# install.sh — Set up Claude Code (free AI coding assistant) on your laptop.
#
# One-liner usage:
#   curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash
#
# Or with your API key pre-supplied:
#   curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash -s -- --key sk-or-v1-your-key-here

set -euo pipefail

GITHUB_RAW="https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main"
INSTALL_DIR="${HOME}/.claude-code-free"
CONTAINER_NAME="claude-code"
SSH_PORT=2222
SSH_CONFIG_HOST="claude-code"

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[•]${NC} $*"; }
ok()      { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*" >&2; }
heading() { echo ""; echo -e "${CYAN}━━━ $* ━━━${NC}"; echo ""; }

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
API_KEY=""
if [ "${1:-}" = "--key" ]; then
    API_KEY="${2:-}"
fi

# ---------------------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------------------
clear
echo ""
echo -e "${CYAN}  Claude Code — Free AI Coding Assistant${NC}"
echo -e "  Powered by Step-3.5-Flash via OpenRouter (free tier)"
echo ""
echo "  This script will:"
echo "    1. Check that Docker Desktop is running"
echo "    2. Ask for your free OpenRouter API key (if not provided)"
echo "    3. Download and start the Claude Code container"
echo "    4. Configure VS Code Remote SSH"
echo ""
echo "  Takes about 5 minutes on first run."
echo ""
# Skip prompt if running via pipe (non-interactive)
if [ -t 0 ]; then
    read -r -p "  Press Enter to continue, or Ctrl-C to cancel... "
fi

# ---------------------------------------------------------------------------
# Step 1: Docker
# ---------------------------------------------------------------------------
heading "Step 1: Docker Desktop"

if ! command -v docker &> /dev/null; then
    error "Docker is not installed."
    echo ""
    echo "  Install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    echo "  Then re-run this script."
    exit 1
fi

if ! docker info &> /dev/null; then
    error "Docker Desktop is not running."
    echo ""
    echo "  Please start Docker Desktop and wait for it to fully load,"
    echo "  then re-run this script."
    exit 1
fi

ok "Docker Desktop is running ($(docker --version | cut -d' ' -f3 | tr -d ','))"

# ---------------------------------------------------------------------------
# Step 2: OpenRouter API key
# ---------------------------------------------------------------------------
heading "Step 2: OpenRouter API key"

if [ -z "$API_KEY" ]; then
    echo "  You need a free OpenRouter API key to use Claude Code."
    echo ""
    echo "  To get one (takes 1 minute):"
    echo "    1. Go to https://openrouter.ai"
    echo "    2. Sign up with Google or GitHub"
    echo "    3. Go to https://openrouter.ai/keys"
    echo "    4. Click 'Create key' and copy it"
    echo ""
    echo "  The key looks like: sk-or-v1-abc123..."
    echo ""
    while true; do
        read -r -p "  Paste your OpenRouter API key: " API_KEY
        if [[ "$API_KEY" == sk-or-v1-* ]]; then
            break
        else
            warn "That doesn't look right — it should start with 'sk-or-v1-'. Try again."
        fi
    done
fi

ok "API key accepted."

# ---------------------------------------------------------------------------
# Step 3: SSH public key (optional, silent)
# ---------------------------------------------------------------------------
SSH_PUB_KEY=""
for key_file in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub; do
    if [ -f "$key_file" ]; then
        SSH_PUB_KEY=$(cat "$key_file")
        break
    fi
done

# ---------------------------------------------------------------------------
# Step 4: Download files
# ---------------------------------------------------------------------------
heading "Step 4: Downloading container files"

mkdir -p "$INSTALL_DIR"

for file in Dockerfile entrypoint.sh set-env.sh docker-compose.yml; do
    info "Downloading $file..."
    curl -fsSL "${GITHUB_RAW}/${file}" -o "${INSTALL_DIR}/${file}"
done

ok "Files downloaded to ${INSTALL_DIR}"

# ---------------------------------------------------------------------------
# Step 5: Write .env and start container
# ---------------------------------------------------------------------------
heading "Step 5: Starting container"

cat > "${INSTALL_DIR}/.env" <<EOF
OPENROUTER_API_KEY=${API_KEY}
SSH_AUTHORIZED_KEY=${SSH_PUB_KEY}
EOF

# Stop existing container if running
if docker ps -aq --filter "name=^${CONTAINER_NAME}$" | grep -q .; then
    info "Removing existing container..."
    docker compose -f "${INSTALL_DIR}/docker-compose.yml" down 2>/dev/null || true
fi

info "Building and starting Claude Code container..."
info "(First run downloads ~500 MB and takes a few minutes)"
echo ""
docker compose --env-file "${INSTALL_DIR}/.env" -f "${INSTALL_DIR}/docker-compose.yml" up -d --build
echo ""
ok "Container started."

# ---------------------------------------------------------------------------
# Step 6: VS Code SSH config
# ---------------------------------------------------------------------------
heading "Step 6: VS Code SSH config"

mkdir -p "${HOME}/.ssh"
SSH_CONFIG="${HOME}/.ssh/config"

if grep -q "Host ${SSH_CONFIG_HOST}" "${SSH_CONFIG}" 2>/dev/null; then
    ok "SSH config entry already exists."
else
    cat >> "${SSH_CONFIG}" <<EOF

Host ${SSH_CONFIG_HOST}
    HostName localhost
    Port ${SSH_PORT}
    User coder
    StrictHostKeyChecking no
EOF
    ok "SSH config entry added."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
heading "All done"

echo "  Claude Code is running and ready."
echo ""
echo "  Connect from VS Code:"
echo "    1. Install the 'Remote - SSH' extension (if not already installed)"
echo "    2. Press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows/Linux)"
echo "    3. Type:   Remote-SSH: Connect to Host"
echo "    4. Select: ${SSH_CONFIG_HOST}"
if [ -z "$SSH_PUB_KEY" ]; then
    echo "    5. Password: coder"
fi
echo ""
echo "  Once connected, open a VS Code terminal and run:"
echo "    cd /workspace"
echo "    claude"
echo ""
echo "  To stop:    docker compose -f ${INSTALL_DIR}/docker-compose.yml down"
echo "  To restart: docker compose -f ${INSTALL_DIR}/docker-compose.yml up -d"
echo ""
