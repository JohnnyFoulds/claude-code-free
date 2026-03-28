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
CONTAINER_NAME="claude-code-free"
SSH_PORT=2223
SSH_CONFIG_HOST="claude-code-free"

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
echo "    1. Install Docker if needed, or start it if not running"
echo "    2. Ask for your free OpenRouter API key"
echo "    3. Ask where to store your workspace files"
echo "    4. Download and start the Claude Code container"
echo "    5. Configure VS Code Remote SSH"
echo ""
echo "  Takes about 2-5 minutes on first run."
echo ""
# Skip prompt if running non-interactively (piped)
if [ -t 0 ]; then
    read -r -p "  Press Enter to continue, or Ctrl-C to cancel... "
fi

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"

# ---------------------------------------------------------------------------
# Step 1: Docker
# ---------------------------------------------------------------------------
heading "Step 1: Docker"

install_docker_mac() {
    warn "Docker Desktop is not installed."
    echo ""
    read -r -p "  Install Docker Desktop now? [Y/n] " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
        echo ""
        echo "  Install it from: https://www.docker.com/products/docker-desktop/"
        echo "  Then re-run this script."
        exit 0
    fi
    echo ""

    # Check for Homebrew first — easiest path
    if command -v brew &> /dev/null; then
        info "Installing Docker Desktop via Homebrew..."
        brew install --cask docker
        ok "Docker Desktop installed."
    else
        # Download the right DMG for the architecture
        if [ "$ARCH" = "arm64" ]; then
            DMG_URL="https://desktop.docker.com/mac/main/arm64/Docker.dmg"
        else
            DMG_URL="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
        fi
        info "Downloading Docker Desktop (~600 MB)..."
        curl -L "$DMG_URL" -o /tmp/Docker.dmg
        info "Mounting installer..."
        hdiutil attach /tmp/Docker.dmg -quiet
        info "Installing Docker Desktop (you may be prompted for your password)..."
        sudo cp -R "/Volumes/Docker/Docker.app" /Applications/
        hdiutil detach "/Volumes/Docker" -quiet
        rm /tmp/Docker.dmg
        ok "Docker Desktop installed to /Applications/Docker.app"
    fi

    info "Starting Docker Desktop..."
    open -a Docker
    echo ""
    warn "Docker Desktop is starting up — this takes about 30 seconds on first launch."
    echo "  Waiting for Docker to be ready..."
    local elapsed=0
    while ! docker info &> /dev/null; do
        sleep 3
        elapsed=$((elapsed + 3))
        if [ $elapsed -ge 120 ]; then
            error "Docker did not start within 2 minutes."
            echo "  Please open Docker Desktop manually and re-run this script."
            exit 1
        fi
        echo -n "."
    done
    echo ""
}

install_docker_linux() {
    warn "Docker is not installed."
    echo ""
    read -r -p "  Install Docker Engine now? (requires sudo) [Y/n] " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
        echo ""
        echo "  Install it from: https://docs.docker.com/engine/install/"
        echo "  Then re-run this script."
        exit 0
    fi
    echo ""

    # Detect distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    else
        DISTRO="unknown"
    fi

    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop)
            info "Installing Docker Engine via apt (requires sudo)..."
            sudo apt-get update -qq
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
                | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
                https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
                | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update -qq
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo usermod -aG docker "$USER"
            sudo systemctl enable --now docker
            ok "Docker Engine installed."
            warn "You have been added to the 'docker' group."
            warn "You may need to log out and back in for group changes to take effect."
            warn "If docker commands fail, run: newgrp docker"
            ;;
        fedora|rhel|centos|rocky|alma)
            info "Installing Docker Engine via dnf (requires sudo)..."
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo usermod -aG docker "$USER"
            sudo systemctl enable --now docker
            ok "Docker Engine installed."
            warn "You may need to log out and back in, or run: newgrp docker"
            ;;
        *)
            error "Unsupported Linux distribution: $DISTRO"
            echo ""
            echo "  Please install Docker manually: https://docs.docker.com/engine/install/"
            echo "  Then re-run this script."
            exit 1
            ;;
    esac
}

start_docker_mac() {
    warn "Docker Desktop is installed but not running."
    read -r -p "  Start Docker Desktop now? [Y/n] " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
        echo ""
        echo "  Please start Docker Desktop manually and re-run this script."
        exit 0
    fi
    info "Starting Docker Desktop..."
    open -a Docker
    echo ""
    echo "  Waiting for Docker to be ready..."
    local elapsed=0
    while ! docker info &> /dev/null; do
        sleep 3
        elapsed=$((elapsed + 3))
        if [ $elapsed -ge 120 ]; then
            error "Docker did not start within 2 minutes."
            echo "  Please open Docker Desktop manually and re-run this script."
            exit 1
        fi
        echo -n "."
    done
    echo ""
}

# Main Docker check
if ! command -v docker &> /dev/null; then
    # Not installed at all
    case "$OS" in
        Darwin) install_docker_mac ;;
        Linux)  install_docker_linux ;;
        *)
            error "Unsupported OS: $OS"
            echo "  Please install Docker manually: https://www.docker.com/products/docker-desktop/"
            exit 1
            ;;
    esac
fi

# Installed but not running
if ! docker info &> /dev/null; then
    case "$OS" in
        Darwin) start_docker_mac ;;
        Linux)
            warn "Docker is installed but not running."
            read -r -p "  Start Docker daemon now? (requires sudo) [Y/n] " answer
            if [[ "$answer" == "n" || "$answer" == "N" ]]; then
                echo "  Please start Docker manually and re-run this script."
                exit 0
            fi
            sudo systemctl start docker
            sleep 3
            ;;
    esac
fi

# Final check
if ! docker info &> /dev/null; then
    error "Docker is still not running."
    echo "  Please start Docker Desktop manually and re-run this script."
    exit 1
fi

ok "Docker is ready ($(docker --version | cut -d' ' -f3 | tr -d ','))"

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
# Step 2b: Model selection (optional)
# ---------------------------------------------------------------------------
DEFAULT_MODEL="stepfun/step-3.5-flash:free"
MODEL="${OPENROUTER_MODEL:-}"

if [ -z "$MODEL" ]; then
    echo ""
    echo "  Default model: ${DEFAULT_MODEL}"
    echo "  To use a different OpenRouter model, enter its ID below."
    echo "  Press Enter to keep the default."
    echo ""
    read -r -p "  Model ID (or Enter for default): " MODEL
fi

if [ -z "$MODEL" ]; then
    MODEL="$DEFAULT_MODEL"
fi

ok "Model: ${MODEL}"

# ---------------------------------------------------------------------------
# Step 3: SSH public key — use dedicated passwordless key for claude-code-free
# ---------------------------------------------------------------------------
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Always use a dedicated key so we never rely on a user key that may have a passphrase.
CLAUDE_KEY="${HOME}/.ssh/id_ed25519_claude_code_free"
if [ ! -f "${CLAUDE_KEY}.pub" ]; then
    ssh-keygen -t ed25519 -f "$CLAUDE_KEY" -N "" -q
fi
SSH_PUB_KEY=$(cat "${CLAUDE_KEY}.pub")

# ---------------------------------------------------------------------------
# Step 4: Workspace location
# ---------------------------------------------------------------------------
heading "Step 4: Workspace location"

DEFAULT_WORKSPACE="${HOME}/claude-workspace"

echo "  Where should your workspace files be stored?"
echo ""
echo "  [1] ${DEFAULT_WORKSPACE}  (recommended)"
echo "      Files saved here are visible in Finder/file manager and easy to back up."
echo ""
echo "  [2] Docker volume  (managed by Docker, not directly visible)"
echo "      Use this if you only access files via VS Code Remote SSH."
echo ""
echo "  [3] Custom path"
echo "      Enter any directory on this machine."
echo ""

WORKSPACE_TYPE=""
while true; do
    read -r -p "  Choose [1/2/3] (default: 1): " WORKSPACE_TYPE
    WORKSPACE_TYPE="${WORKSPACE_TYPE:-1}"
    case "$WORKSPACE_TYPE" in
        1|2|3) break ;;
        *) warn "Please enter 1, 2, or 3." ;;
    esac
done

WORKSPACE_VOLUME=""   # compose volume line
WORKSPACE_VOLUMES=""  # compose top-level volumes block (only for named volume)
WORKSPACE_DISPLAY=""  # shown to user in summary

case "$WORKSPACE_TYPE" in
    1)
        WORKSPACE_PATH="${DEFAULT_WORKSPACE}"
        mkdir -p "${WORKSPACE_PATH}"
        WORKSPACE_VOLUME="      - ${WORKSPACE_PATH}:/workspace"
        WORKSPACE_DISPLAY="${WORKSPACE_PATH}"
        ok "Workspace: ${WORKSPACE_PATH}"
        ;;
    2)
        WORKSPACE_VOLUME="      - workspace:/workspace"
        WORKSPACE_VOLUMES="
volumes:
  workspace:"
        WORKSPACE_DISPLAY="Docker volume (docker volume inspect claude-workspace to locate)"
        ok "Workspace: Docker named volume"
        ;;
    3)
        while true; do
            read -r -p "  Enter full path (e.g. /home/you/projects): " WORKSPACE_PATH
            if [ -z "$WORKSPACE_PATH" ]; then
                warn "Path cannot be empty."
            elif [ -d "$WORKSPACE_PATH" ]; then
                break
            else
                read -r -p "  Directory does not exist. Create it? [Y/n] " create_it
                if [[ "$create_it" != "n" && "$create_it" != "N" ]]; then
                    mkdir -p "$WORKSPACE_PATH"
                    break
                fi
            fi
        done
        WORKSPACE_VOLUME="      - ${WORKSPACE_PATH}:/workspace"
        WORKSPACE_DISPLAY="${WORKSPACE_PATH}"
        ok "Workspace: ${WORKSPACE_PATH}"
        ;;
esac

# ---------------------------------------------------------------------------
# Step 5: Write docker-compose.yml and .env, start container
# ---------------------------------------------------------------------------
heading "Step 5: Starting container"

mkdir -p "$INSTALL_DIR"

# Write a tailored docker-compose.yml based on workspace choice
cat > "${INSTALL_DIR}/docker-compose.yml" <<EOF
services:
  claude-code:
    image: johannesfoulds/claude-code-free:latest
    container_name: ${CONTAINER_NAME}
    ports:
      - "${SSH_PORT}:22"
    volumes:
${WORKSPACE_VOLUME}
    environment:
      - ANTHROPIC_BASE_URL=https://openrouter.ai/api
      - ANTHROPIC_AUTH_TOKEN=\${OPENROUTER_API_KEY}
      - ANTHROPIC_API_KEY=
      - ANTHROPIC_MODEL=\${OPENROUTER_MODEL:-stepfun/step-3.5-flash:free}
      - SSH_AUTHORIZED_KEY=\${SSH_AUTHORIZED_KEY:-}
    restart: unless-stopped
${WORKSPACE_VOLUMES}
EOF

cat > "${INSTALL_DIR}/.env" <<EOF
OPENROUTER_API_KEY=${API_KEY}
OPENROUTER_MODEL=${MODEL}
SSH_AUTHORIZED_KEY=${SSH_PUB_KEY}
EOF

# Stop existing container if running
if docker ps -aq --filter "name=^${CONTAINER_NAME}$" | grep -q .; then
    info "Removing existing container..."
    docker compose -f "${INSTALL_DIR}/docker-compose.yml" down 2>/dev/null || true
fi

info "Pulling and starting Claude Code container..."
info "(First run downloads ~140 MB — takes about 1-2 minutes)"
echo ""
docker compose --env-file "${INSTALL_DIR}/.env" -f "${INSTALL_DIR}/docker-compose.yml" up -d --pull always
echo ""
ok "Container started."

# ---------------------------------------------------------------------------
# Step 6: VS Code SSH config
# ---------------------------------------------------------------------------
heading "Step 6: VS Code SSH config"

mkdir -p "${HOME}/.ssh"
SSH_CONFIG="${HOME}/.ssh/config"

if grep -q "Host ${SSH_CONFIG_HOST}" "${SSH_CONFIG}" 2>/dev/null; then
    # Remove existing block and replace with updated entry
    perl -i -0pe "s/\n?Host ${SSH_CONFIG_HOST}\b.*?(?=\nHost |\z)//s" "${SSH_CONFIG}" 2>/dev/null || \
        sed -i "/^Host ${SSH_CONFIG_HOST}/,/^Host /{ /^Host ${SSH_CONFIG_HOST}/d; /^Host /!d; }" "${SSH_CONFIG}"
fi
cat >> "${SSH_CONFIG}" <<EOF

Host ${SSH_CONFIG_HOST}
    HostName localhost
    Port ${SSH_PORT}
    User coder
    IdentityFile ${CLAUDE_KEY}
    StrictHostKeyChecking no
EOF
ok "SSH config entry updated."

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
heading "All done"

echo "  Claude Code is running and ready."
echo ""
echo "  ── Workspace ───────────────────────────────────────────────────"
echo "  Your files are stored at:"
echo "    ${WORKSPACE_DISPLAY}"
echo "  Inside the container this is /workspace."
echo ""
echo "  ── SSH access ──────────────────────────────────────────────────"
echo "  Direct SSH:"
echo "    ssh -p ${SSH_PORT} coder@localhost"
if [ -z "$SSH_PUB_KEY" ]; then
    echo "    Password: coder"
fi
echo ""
echo "  ── VS Code Remote SSH ──────────────────────────────────────────"
echo "  1. Install the 'Remote - SSH' extension (if not already installed)"
echo "  2. Press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Linux)"
echo "  3. Type:   Remote-SSH: Connect to Host"
echo "  4. Select: ${SSH_CONFIG_HOST}"
if [ -z "$SSH_PUB_KEY" ]; then
    echo "  5. Password: coder"
fi
echo ""
echo "  ── Once inside the container ───────────────────────────────────"
echo "    cd /workspace"
echo "    claude"
echo ""
echo "  ── Daily commands ──────────────────────────────────────────────"
echo "  Stop:    docker compose -f ${INSTALL_DIR}/docker-compose.yml down"
echo "  Start:   docker compose -f ${INSTALL_DIR}/docker-compose.yml up -d"
echo ""

read -r -p "  Try Claude Code right now? [Y/n] " try_now
if [[ "$try_now" != "n" && "$try_now" != "N" ]]; then
    echo ""
    info "Waiting for SSH to be ready..."
    ssh_ready=false
    for i in $(seq 1 20); do
        if bash -c "echo >/dev/tcp/localhost/${SSH_PORT}" 2>/dev/null; then
            ssh_ready=true
            break
        fi
        sleep 3
    done
    if [ "$ssh_ready" = false ]; then
        warn "SSH not ready after 60s. Connect manually with:"
        echo "  ssh -p ${SSH_PORT} coder@localhost"
    else
        echo "  Connecting... (type 'exit' to leave the container)"
        echo ""
        exec ssh -t -o StrictHostKeyChecking=no -i "${CLAUDE_KEY}" -p "${SSH_PORT}" coder@localhost \
            "bash -l -c 'cd /workspace && exec claude'"
    fi
fi
