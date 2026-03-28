# claude-code-free

Run [Claude Code](https://claude.ai/code) on your laptop for free — no subscription, no GPU, no server.

Uses the [Step-3.5-Flash](https://openrouter.ai/stepfun/step-3.5-flash:free) model (196B MoE, free tier) via [OpenRouter](https://openrouter.ai).

## Install

**Mac / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash
```

**Windows** (PowerShell)
```powershell
irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 | iex
```

The script checks for Docker, walks you through getting a free API key if you need one, builds the container, and configures VS Code — all in one go.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac, Windows, Linux)
- [VS Code](https://code.visualstudio.com/) + [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension
- A free [OpenRouter](https://openrouter.ai) account (the script helps you get one)

## Usage

After install, connect from VS Code:

1. `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows) → `Remote-SSH: Connect to Host` → `claude-code`
2. Open a terminal and run:

```bash
cd /workspace
claude
```

Your files in `/workspace` persist across restarts.

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

## What's inside the container

| Component | Details |
|-----------|---------|
| OS | Ubuntu 24.04 |
| Claude Code | latest |
| Miniconda | latest (Python) |
| Node.js | 22 LTS |

## Cost

Free. The Step-3.5-Flash model is on OpenRouter's free tier. Rate limits apply for heavy use — see [openrouter.ai/stepfun/step-3.5-flash:free](https://openrouter.ai/stepfun/step-3.5-flash:free) for current limits.

To switch models, edit `~/.claude-code-free/docker-compose.yml` (Mac/Linux) or `%USERPROFILE%\.claude-code-free\docker-compose.yml` (Windows) and change `ANTHROPIC_MODEL` to any model ID from [openrouter.ai/models](https://openrouter.ai/models).

## How it works

```
VS Code (your laptop)
    └── Remote SSH → port 2222
            └── Docker container
                    ├── Claude Code CLI
                    ├── Miniconda (Python)
                    └── /workspace (persistent volume)
                            └── OpenRouter API → Step-3.5-Flash (free)
```

## Uninstall

**Mac / Linux**
```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down --volumes
rm -rf ~/.claude-code-free
# Remove the 'claude-code' block from ~/.ssh/config
```

**Windows** (PowerShell)
```powershell
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" down --volumes
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude-code-free"
# Remove the 'claude-code' block from %USERPROFILE%\.ssh\config
```
