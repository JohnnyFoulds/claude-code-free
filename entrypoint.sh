#!/bin/bash
set -e

# Generate SSH host keys if they don't exist (first boot)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Write ANTHROPIC_* env vars from container environment into a sourced file.
# This makes them available in SSH login shells (VS Code Remote SSH terminals),
# which don't inherit the container process environment directly.
{
    for var in ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_MODEL; do
        val=$(printenv "$var" 2>/dev/null || true)
        if [ -n "$val" ]; then
            echo "export ${var}=\"${val}\""
        fi
    done
} > /etc/claude-code-env
chmod 644 /etc/claude-code-env

# SSH_AUTHORIZED_KEY env var: inject directly (docker run -e)
if [ -n "${SSH_AUTHORIZED_KEY:-}" ]; then
    echo "$SSH_AUTHORIZED_KEY" > /home/coder/.ssh/authorized_keys
    chmod 600 /home/coder/.ssh/authorized_keys
    chown coder:coder /home/coder/.ssh/authorized_keys
fi

# ConfigMap-mounted key: /root/ssh-keys/authorized_keys (Kubernetes)
if [ -f /root/ssh-keys/authorized_keys ] && [ -s /root/ssh-keys/authorized_keys ]; then
    cp /root/ssh-keys/authorized_keys /home/coder/.ssh/authorized_keys
    chmod 600 /home/coder/.ssh/authorized_keys
    chown coder:coder /home/coder/.ssh/authorized_keys
fi

# Start SSH daemon
exec /usr/sbin/sshd -D
