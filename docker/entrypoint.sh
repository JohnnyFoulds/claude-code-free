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

# Write CLAUDE.md to /workspace after the volume is mounted.
# Cannot be baked into the image because /workspace is a Docker volume
# that shadows the image layer at runtime.
# Only write if absent — preserve any user-created CLAUDE.md.
if [ ! -f /workspace/CLAUDE.md ]; then
    cat > /workspace/CLAUDE.md << 'CLAUDEMD'
# Web access

You have internet access via the Bash tool. `w3m` and `curl` are installed.

**To search the web**, use Bash:
```
w3m -dump 'https://lite.duckduckgo.com/lite/?q=QUERY' 2>/dev/null | head -c 50000
```
(replace spaces in QUERY with +)

**To fetch a URL**, use Bash:
```
w3m -dump 'URL' 2>/dev/null | head -c 50000
```

**If w3m fails**, fall back to curl:
```
curl -fsSL --max-time 15 -A 'Mozilla/5.0' 'URL' 2>/dev/null \
  | python3 -c 'import sys,markdownify; print(markdownify.markdownify(sys.stdin.read(), heading_style="ATX"))' \
  2>/dev/null | head -c 50000
```

Do NOT use the Agent tool or WebFetch/WebSearch for web access — both are disabled. Use Bash directly.
CLAUDEMD
    chown coder:coder /workspace/CLAUDE.md
fi

# Start SSH daemon
exec /usr/sbin/sshd -D
