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

Edit `~/.claude-code-free/docker-compose.yml` and change `ANTHROPIC_MODEL` to any model ID from [openrouter.ai/models](https://openrouter.ai/models). Many models are free or very cheap.

Then restart:
```bash
docker compose -f ~/.claude-code-free/docker-compose.yml up -d
```

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
