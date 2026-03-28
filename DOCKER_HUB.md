# johannesfoulds/claude-code-free

Run [Claude Code](https://claude.ai/code) in a container using free AI models via [OpenRouter](https://openrouter.ai) — no Anthropic subscription required.

**Maintained by:** [Johannes Foulds](https://github.com/JohnnyFoulds/claude-code-free)
**Where to get help:** [GitHub Issues](https://github.com/JohnnyFoulds/claude-code-free/issues) · [Source repository](https://github.com/JohnnyFoulds/claude-code-free)
**Supported architectures:** `amd64`

---

## Supported tags

| Tag | Description |
| --- | --- |
| `latest` | Latest stable build — [Dockerfile](https://github.com/JohnnyFoulds/claude-code-free/blob/master/docker/Dockerfile) |

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

Connect via SSH (key auth — no password needed if `SSH_AUTHORIZED_KEY` is set):

```bash
ssh -p 2223 coder@localhost
```

Fallback password (if no key is configured): `coder`

Get a free OpenRouter API key at [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys).

> **Note:** Free-tier models are community-supported and subject to rate limits. For higher throughput, [add credits](https://openrouter.ai/settings/credits) to your OpenRouter account or switch to a paid model.

---

## Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `ANTHROPIC_BASE_URL` | Yes | API base URL. Set to `https://openrouter.ai/api` for OpenRouter. |
| `ANTHROPIC_AUTH_TOKEN` | Yes | Your OpenRouter API key. |
| `ANTHROPIC_MODEL` | Yes | Model ID. See [Models](#models) below. |
| `ANTHROPIC_API_KEY` | No | Alternative to `ANTHROPIC_AUTH_TOKEN`. Either works. |
| `SSH_AUTHORIZED_KEY` | No | Public key written to `/home/coder/.ssh/authorized_keys` at startup. Recommended over password auth. |

### Using Docker Secrets

Sensitive values can be injected via the `_FILE` suffix convention. The entrypoint reads the file path and exports the value:

```bash
# Example — inject API key from a Docker secret
-e ANTHROPIC_AUTH_TOKEN_FILE=/run/secrets/openrouter_key
```

---

## Volumes

| Mount path | Purpose |
| --- | --- |
| `/workspace` | Your project files. Persist this volume across container restarts. |

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

Add to `~/.ssh/config`:

```sshconfig
Host claude-code-free
    HostName localhost
    Port 2223
    User coder
```

Then connect: `Cmd+Shift+P` → `Remote-SSH: Connect to Host` → `claude-code-free`.

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

```bash
# Use whichever public key you have (id_ed25519, id_rsa, etc.)
docker run -d \
  -e SSH_AUTHORIZED_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  ... \
  johannesfoulds/claude-code-free
```

Or mount a Kubernetes ConfigMap at `/root/ssh-keys/authorized_keys`.

---

## Models

Set `ANTHROPIC_MODEL` to any OpenRouter model ID. The default is chosen for rate-limit headroom — for best coding quality with occasional use, try `qwen/qwen3-coder:free`.

| Model | Context | Req/min | Notes |
| --- | --- | --- | --- |
| `stepfun/step-3.5-flash:free` | 256K | **50** | **Default** — best availability; SWE-bench 74% |
| `qwen/qwen3-coder:free` | 262K | 8 | Best coding quality; privacy-safe |
| `openai/gpt-oss-120b:free` | 131K | — | ⚠ Free provider trains on your prompts |
| `openai/gpt-oss-20b:free` | 131K | — | ⚠ Free provider trains on your prompts |
| `nvidia/nemotron-3-super-120b-a12b:free` | 262K | — | ⚠ NVIDIA logs all prompts (trial use only) |
| `meta-llama/llama-3.3-70b-instruct:free` | 65K | 8 | Simple tasks; context halved on free tier |
| `google/gemma-3-27b-it:free` | 131K | — | ⚠ No tool use on free tier — incompatible |

Full list: [openrouter.ai/models?q=free](https://openrouter.ai/models?q=free) · [Model guide with benchmarks and pricing](https://github.com/JohnnyFoulds/claude-code-free/blob/main/docs/model-guide.md)

---

## What's inside

| Component | Details |
| --- | --- |
| Base image | `node:22-slim` (Debian) |
| Claude Code | Latest stable (`@anthropic-ai/claude-code`) |
| Node.js | 22 LTS |
| Python | 3 (system) |
| Web access | `w3m`, `curl`, `markdownify` |
| SSH server | OpenSSH |
| User | `coder` (non-root, passwordless sudo) |

---

## Updating

Pull the latest image and recreate the container:

```bash
docker pull johannesfoulds/claude-code-free:latest
docker stop claude-code-free && docker rm claude-code-free
# re-run your original docker run command
```

With Docker Compose:

```bash
docker compose pull && docker compose up -d
```

---

## Source

[github.com/JohnnyFoulds/claude-code-free](https://github.com/JohnnyFoulds/claude-code-free) · MIT License
