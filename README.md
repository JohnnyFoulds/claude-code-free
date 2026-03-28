# Claude Code — Free

Run [Claude Code](https://claude.ai/code) with free AI models on your own machine — no Anthropic subscription required.

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/johannesfoulds/claude-code-free)
![Docker Image Size](https://img.shields.io/docker/image-size/johannesfoulds/claude-code-free/latest)

Powered by [OpenRouter](https://openrouter.ai). One free API key gives you access to dozens of capable models through a single interface.

---

## Install

| Platform | Command |
| --- | --- |
| Mac / Linux | `curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh \| bash` |
| Windows (PowerShell) | `irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 \| iex` |

The installer checks that Docker is running, walks you through getting a free OpenRouter API key, pulls the container, and configures VS Code Remote SSH.

**Requirements:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) · [VS Code](https://code.visualstudio.com/) · [Remote - SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)

---

## Usage

Connect from VS Code:

1. `Cmd+Shift+P` → `Remote-SSH: Connect to Host` → `claude-code-free`
2. Open a terminal and run:

```bash
cd /workspace
claude
```

Your `/workspace` directory persists across container restarts. You can also connect via SSH directly:

```bash
ssh -p 2223 coder@localhost
```

---

## Start and stop

### Mac / Linux

```bash
docker compose -f ~/.claude-code-free/docker-compose.yml up -d   # start
docker compose -f ~/.claude-code-free/docker-compose.yml down    # stop
```

### Windows (PowerShell)

```powershell
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" up -d   # start
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" down    # stop
```

---

## Switching models

The installer prompts you to choose a model. Change it any time by editing `~/.claude-code-free/.env`:

```env
OPENROUTER_MODEL=qwen/qwen3-coder:free
```

Then restart the container:

```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down
docker compose --env-file ~/.claude-code-free/.env -f ~/.claude-code-free/docker-compose.yml up -d
```

> **Note:** Claude Code's built-in `/model` command is designed for Anthropic's model roster and does not work with OpenRouter model IDs. Use `.env` as shown above.

### Models worth trying

| Model | Size | Context | Notes |
| --- | --- | --- | --- |
| `stepfun/step-3.5-flash:free` | 196B MoE | 256K | Default — fast, well-rounded |
| `qwen/qwen3-coder:free` | 480B MoE | 262K | Strong at code generation and agentic tasks |
| `openai/gpt-oss-120b:free` | 120B MoE | 131K | Strong reasoning |
| `openai/gpt-oss-20b:free` | 21B MoE | 131K | Faster, lighter |
| `nvidia/nemotron-3-super-120b-a12b:free` | 120B MoE | 262K | Complex reasoning |
| `meta-llama/llama-3.3-70b-instruct:free` | 70B | 65K | Solid all-rounder |
| `mistralai/mistral-small-3.1-24b-instruct:free` | 24B | 128K | Fast, multimodal |
| `google/gemma-3-27b-it:free` | 27B | 131K | Google Gemma 3 |
| `nousresearch/hermes-3-llama-3.1-405b:free` | 405B | 131K | Large, agentic tasks |

Full list at [openrouter.ai/models?q=free](https://openrouter.ai/models?q=free). Different models have different strengths — it is worth trying a few to find what works best for your workflow.

---

## How it works

```text
Your machine
├── VS Code  ──── Remote SSH ────► Docker container (johannesfoulds/claude-code-free)
│                                  ├── Claude Code CLI
│                                  ├── Node.js 22
│                                  ├── Python 3 + w3m + curl
│                                  └── /workspace  (your files, persisted via volume)
│
└────────────────────────────────► OpenRouter API ──► your chosen model
```

Claude Code speaks the OpenAI API format. This project points it at OpenRouter, which proxies that format to whichever model you select.

---

## What's inside

| Component | Details |
| --- | --- |
| OS | Alpine Linux (`node:22-alpine`) — 345 MB image |
| Claude Code | Latest stable release |
| Node.js | 22 LTS |
| Python | 3 (system) |
| Web access | `w3m`, `curl`, `markdownify` — the model can browse URLs and search the web via Bash |

---

## Why use this

Anthropic's Claude Code requires a Claude Pro subscription ($20/month) or API credits. This project lets you run the same interface against free models on OpenRouter at no cost.

| | This project | Claude Pro |
| --- | --- | --- |
| Cost | Free | $20/month |
| Setup | One command | Built-in |
| Models | Any OpenRouter model | Claude only |
| Code stays on your machine | Yes | No |

### Good fit if you

- Want to try Claude Code before committing to a subscription
- Are a student or working in a cost-sensitive environment
- Want to experiment with different models through the same interface

### Stick with Claude Pro if you

- Do serious daily coding work — the quality difference is real
- Need the latest Claude Sonnet or Opus models

---

## On the free tier

OpenRouter's free models are community-supported. Rate limits, availability, and which models are offered at no cost can change without notice. If you find yourself using this setup regularly, consider [adding credits to your OpenRouter account](https://openrouter.ai/settings/credits) — even a small balance gives you higher rate limits and access to a broader model selection. OpenRouter is pay-as-you-go with no subscription, and most requests cost a fraction of a cent under normal coding use.

---

## Uninstall

**Mac / Linux** — run in a terminal:

```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down --volumes
rm -rf ~/.claude-code-free
# Remove the 'claude-code-free' entry from ~/.ssh/config
```

**Windows** — run in PowerShell:

```powershell
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" down --volumes
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude-code-free"
# Remove the 'claude-code-free' entry from %USERPROFILE%\.ssh\config
```

---

## Contributing

Bug reports and pull requests are welcome. Please open an issue first for significant changes.

## License

MIT © Johannes Foulds
