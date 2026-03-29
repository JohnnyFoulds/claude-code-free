FROM node:22-slim

# ---------------------------------------------------------------------------
# System packages + web fetch fallback tools
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    openssh-server \
    sudo \
    ca-certificates \
    python3 \
    python3-pip \
    w3m \
    lynx \
    && pip3 install --break-system-packages markdownify \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Claude Code (Node.js 22 bundled with node:22-slim)
# ---------------------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code

# ---------------------------------------------------------------------------
# SSH server setup
# ---------------------------------------------------------------------------
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config \
    && echo "X11Forwarding no" >> /etc/ssh/sshd_config \
    && mkdir -p /run/sshd
# SSH host keys are NOT generated here — they are generated at first container start
# by entrypoint.sh so each container instance has unique keys.

# ---------------------------------------------------------------------------
# Non-root user for VS Code Remote SSH
# ---------------------------------------------------------------------------
RUN useradd -m -s /bin/bash coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "coder:coder" | chpasswd

# SSH keys directory
RUN mkdir -p /home/coder/.ssh && chmod 700 /home/coder/.ssh && chown coder:coder /home/coder/.ssh

# ---------------------------------------------------------------------------
# OpenRouter / Claude Code environment
# ---------------------------------------------------------------------------
# These are set at container runtime via --env-file or -e flags.
# They are listed here for documentation only.
# ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_API_KEY, ANTHROPIC_MODEL
# are passed at runtime via docker run or docker-compose.

# Persist env vars for SSH sessions (VS Code Remote SSH doesn't inherit docker -e vars)
COPY set-env.sh /etc/profile.d/claude-code-env.sh
RUN chmod +x /etc/profile.d/claude-code-env.sh

# ---------------------------------------------------------------------------
# Claude Code settings
# ---------------------------------------------------------------------------
COPY init-claude.js /tmp/init-claude.js
RUN mkdir -p /home/coder/.claude \
    && node /tmp/init-claude.js \
    && chown -R coder:coder /home/coder/.claude /home/coder/.claude.json \
    && rm /tmp/init-claude.js

# ---------------------------------------------------------------------------
# Workspace
# ---------------------------------------------------------------------------
RUN mkdir -p /workspace && chown coder:coder /workspace
WORKDIR /workspace

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
