# claude-code-free

Run [Claude Code](https://claude.ai/code) — Anthropic's AI coding assistant — completely free on your own laptop. No subscription. No credit card. No GPU required.

## Install

**Mac / Linux** — paste this in a terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash
```

**Windows** — paste this in PowerShell:
```powershell
irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 | iex
```

The script handles everything: checks Docker is running, walks you through getting a free API key, pulls the container, and configures VS Code. Takes about 2 minutes.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) — Mac, Windows, or Linux
- [VS Code](https://code.visualstudio.com/) with the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension
- A free [OpenRouter](https://openrouter.ai) account (the installer walks you through this)

## Why use this instead of the official Claude Code?

Anthropic's Claude Code requires a **Claude Pro subscription ($20/month)** or **API credits** that run out quickly under agentic use. This project gives you a working alternative that costs nothing, using the [Step-3.5-Flash](https://openrouter.ai/stepfun/step-3.5-flash:free) model — a capable 196B MoE model available free on [OpenRouter](https://openrouter.ai).

| | This project | Claude Pro |
|---|---|---|
| Cost | Free | $20/month |
| Setup | One command | Built-in |
| Model quality | Good | Excellent |
| Model flexibility | Any OpenRouter model | Claude only |
| Works offline | No | No |

**This is a good fit if you:**
- Want to try Claude Code before committing to a subscription
- Are a student or working in a cost-sensitive environment
- Want to experiment with different models using the same Claude Code interface
- Prefer keeping your code off Anthropic's servers

**Stick with Claude Pro if you:**
- Do serious daily coding work — the quality difference is real
- Want the latest Claude Sonnet/Opus models

## Usage

After install, connect from VS Code:

1. `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows) → `Remote-SSH: Connect to Host` → `claude-code-free`
2. Open a terminal in VS Code and run:

```bash
cd /workspace
claude
```

Your `/workspace` files persist across container restarts.

## Daily commands

**Mac / Linux**
```bash
docker compose -f ~/.claude-code-free/docker-compose.yml up -d   # start
docker compose -f ~/.claude-code-free/docker-compose.yml down    # stop
```

**Windows** (PowerShell)
```powershell
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" up -d   # start
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" down    # stop
```

## Switching models

The installer asks which model you want during setup. You can change it any time by editing `~/.claude-code-free/.env`:

```
OPENROUTER_MODEL=qwen/qwen3-coder:free
```

Then restart:
```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down
docker compose --env-file ~/.claude-code-free/.env -f ~/.claude-code-free/docker-compose.yml up -d
```

> **Note:** The `/model` command inside Claude Code will not work here — it is designed for Anthropic's own model roster and does not know about OpenRouter models. Use `.env` to switch models instead.

### Free models worth trying

All of these work with a free OpenRouter account. No credit card needed.

| Model ID | Size | Context | Good for |
|---|---|---|---|
| `stepfun/step-3.5-flash:free` | 196B MoE | 256K | **Default** — fast, well-rounded |
| `qwen/qwen3-coder:free` | 480B MoE | 262K | Code generation, agentic coding |
| `openai/gpt-oss-120b:free` | 120B MoE | 131K | Strong reasoning, complex tasks |
| `openai/gpt-oss-20b:free` | 21B MoE | 131K | Faster, lighter version of above |
| `meta-llama/llama-3.3-70b-instruct:free` | 70B | 65K | Solid all-rounder |
| `nvidia/nemotron-3-super-120b-a12b:free` | 120B MoE | 262K | Complex reasoning |
| `mistralai/mistral-small-3.1-24b-instruct:free` | 24B | 128K | Multimodal, fast |
| `google/gemma-3-27b-it:free` | 27B | 131K | Google's largest Gemma 3 |
| `nousresearch/hermes-3-llama-3.1-405b:free` | 405B | 131K | Large, agentic tasks |

For the full up-to-date list: [openrouter.ai/models?q=free](https://openrouter.ai/models?q=free)

## What's inside the container

| Component | Details |
|-----------|---------|
| OS | Ubuntu 24.04 |
| Claude Code | latest |
| Miniconda | latest (Python environment manager) |
| Node.js | 22 LTS |

## How it works

```
VS Code on your laptop
    └── Remote SSH → port 2223
            └── Docker container (shambi/claude-code-free)
                    ├── Claude Code CLI
                    ├── Miniconda / Python
                    └── /workspace  ← your files live here
                            └── OpenRouter API → Step-3.5-Flash (free)
```

Claude Code is designed to work with any OpenAI-compatible API. This project points it at OpenRouter, which provides access to dozens of models — including free ones — through a single API key.

## Uninstall

**Mac / Linux**
```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down --volumes
rm -rf ~/.claude-code-free
# Remove the 'claude-code-free' block from ~/.ssh/config
```

**Windows** (PowerShell)
```powershell
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" down --volumes
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude-code-free"
# Remove the 'claude-code-free' block from %USERPROFILE%\.ssh\config
```

## License

MIT
