FROM ubuntu:24.04

# Avoid interactive prompts during apt
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    curl \
    git \
    openssh-server \
    sudo \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Node.js 22 (LTS) — Claude Code requires Node 18+
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Miniconda3
# ---------------------------------------------------------------------------
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p $CONDA_DIR \
    && rm /tmp/miniconda.sh \
    && conda clean -afy \
    && echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /etc/profile.d/conda.sh \
    && chmod +x /etc/profile.d/conda.sh

# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code

# ---------------------------------------------------------------------------
# SSH server setup
# ---------------------------------------------------------------------------
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config \
    && echo "X11Forwarding no" >> /etc/ssh/sshd_config

# ---------------------------------------------------------------------------
# Non-root user for VS Code Remote SSH
# ---------------------------------------------------------------------------
RUN useradd -m -s /bin/bash -G sudo coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder

# Set password for password-based SSH (VS Code fallback)
RUN echo "coder:coder" | chpasswd

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
