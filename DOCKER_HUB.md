# johannesfoulds/claude-code-free

Run [Claude Code](https://claude.ai/code) with free AI models via [OpenRouter](https://openrouter.ai) — no Anthropic subscription required.

Full documentation and source: [github.com/JohnnyFoulds/claude-code-free](https://github.com/JohnnyFoulds/claude-code-free)

---

## Quick start

```bash
docker run -d \
  --name claude-code-free \
  -p 2223:22 \
  -v claude-workspace:/workspace \
  -e ANTHROPIC_BASE_URL=https://openrouter.ai/api \
  -e ANTHROPIC_AUTH_TOKEN=your-openrouter-api-key \
  -e ANTHROPIC_MODEL=stepfun/step-3.5-flash:free \
  johannesfoulds/claude-code-free
```

Then connect via SSH:

```bash
ssh -p 2223 coder@localhost
```

Password: `coder` (for initial access — inject a public key via `SSH_AUTHORIZED_KEY` for normal use).

---

## Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `ANTHROPIC_BASE_URL` | Yes | API base URL. Set to `https://openrouter.ai/api` for OpenRouter. |
| `ANTHROPIC_AUTH_TOKEN` | Yes | Your OpenRouter API key. Get one free at [openrouter.ai](https://openrouter.ai). |
| `ANTHROPIC_MODEL` | Yes | Model ID to use. See the models table below. |
| `ANTHROPIC_API_KEY` | No | Alternative to `ANTHROPIC_AUTH_TOKEN`. Either works. |
| `SSH_AUTHORIZED_KEY` | No | Public key injected into `/home/coder/.ssh/authorized_keys` at startup. Recommended over password auth. |

---

## Volumes

| Mount path | Purpose |
| --- | --- |
| `/workspace` | Your project files. Persist this across container restarts. |

```bash
# Named volume (recommended)
-v claude-workspace:/workspace

# Bind mount your local directory
-v /path/to/your/project:/workspace
```

---

## Ports

| Port | Protocol | Description |
| --- | --- | --- |
| `22` | TCP | SSH — used by VS Code Remote SSH and direct terminal access. |

---

## Using with VS Code Remote SSH

Add this to your `~/.ssh/config`:

```
Host claude-code-free
    HostName localhost
    Port 2223
    User coder
```

Then connect from VS Code: `Cmd+Shift+P` → `Remote-SSH: Connect to Host` → `claude-code-free`.

---

## Using with Docker Compose

```yaml
services:
  claude-code:
    image: johannesfoulds/claude-code-free:latest
    ports:
      - "2223:22"
    volumes:
      - workspace:/workspace
    environment:
      - ANTHROPIC_BASE_URL=https://openrouter.ai/api
      - ANTHROPIC_AUTH_TOKEN=${OPENROUTER_API_KEY}
      - ANTHROPIC_MODEL=${OPENROUTER_MODEL:-stepfun/step-3.5-flash:free}
      - SSH_AUTHORIZED_KEY=${SSH_AUTHORIZED_KEY}
    restart: unless-stopped

volumes:
  workspace:
```

---

## Injecting an SSH public key

Pass your public key via the `SSH_AUTHORIZED_KEY` environment variable:

```bash
docker run -d \
  -e SSH_AUTHORIZED_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  ... \
  johannesfoulds/claude-code-free
```

Or mount a Kubernetes ConfigMap at `/root/ssh-keys/authorized_keys`.

---

## Models

Set `ANTHROPIC_MODEL` to any OpenRouter model ID. Free models are available at no cost subject to rate limits.

| Model | Context | Notes |
| --- | --- | --- |
| `stepfun/step-3.5-flash:free` | 256K | Default — fast, well-rounded |
| `qwen/qwen3-coder:free` | 262K | Strong at code generation and agentic tasks |
| `openai/gpt-oss-120b:free` | 131K | Strong reasoning |
| `openai/gpt-oss-20b:free` | 131K | Faster, lighter |
| `nvidia/nemotron-3-super-120b-a12b:free` | 262K | Complex reasoning |
| `meta-llama/llama-3.3-70b-instruct:free` | 65K | Solid all-rounder |
| `mistralai/mistral-small-3.1-24b-instruct:free` | 128K | Fast, multimodal |

Full list: [openrouter.ai/models?q=free](https://openrouter.ai/models?q=free)

> Free tier models are community-supported and subject to rate limits and availability changes. Consider [adding credits](https://openrouter.ai/settings/credits) to your OpenRouter account for higher limits and access to paid models.

---

## What's inside

| Component | Details |
| --- | --- |
| Base image | `node:22-alpine` |
| Claude Code | Latest stable (`@anthropic-ai/claude-code`) |
| Node.js | 22 LTS |
| Python | 3 (system) |
| Web access | `w3m`, `curl`, `markdownify` |
| SSH server | OpenSSH |
| User | `coder` (non-root, passwordless sudo) |

---

## Source

[github.com/JohnnyFoulds/claude-code-free](https://github.com/JohnnyFoulds/claude-code-free) · MIT License
