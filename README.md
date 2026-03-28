# claude-code-free

Run [Claude Code](https://claude.ai/code) on your laptop for free — no subscription, no GPU, no server.

Uses the [Step-3.5-Flash](https://openrouter.ai/stepfun/step-3.5-flash:free) model (196B MoE, free tier) via [OpenRouter](https://openrouter.ai).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash
```

The script checks for Docker, walks you through getting a free API key if you need one, builds the container, and configures VS Code — all in one go.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac, Windows, Linux)
- [VS Code](https://code.visualstudio.com/) + [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension
- A free [OpenRouter](https://openrouter.ai) account

## Usage

After install, connect from VS Code:

1. `Cmd+Shift+P` → `Remote-SSH: Connect to Host` → `claude-code`
2. Open a terminal and run:

```bash
cd /workspace
claude
```

Your files in `/workspace` persist across restarts.

## Daily commands

```bash
# Start
docker compose -f ~/.claude-code-free/docker-compose.yml up -d

# Stop
docker compose -f ~/.claude-code-free/docker-compose.yml down
```

## What's inside the container

| Component | Version |
|-----------|---------|
| OS | Ubuntu 24.04 |
| Claude Code | latest |
| Miniconda | latest |
| Node.js | 22 LTS |

## Cost

Free. The Step-3.5-Flash model is on OpenRouter's free tier. Rate limits apply for heavy use — see [openrouter.ai/stepfun/step-3.5-flash:free](https://openrouter.ai/stepfun/step-3.5-flash:free) for current limits.

To use a different model, edit `~/.claude-code-free/docker-compose.yml` and change `ANTHROPIC_MODEL`.

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

```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down --volumes
rm -rf ~/.claude-code-free
```

Remove the `claude-code` entry from `~/.ssh/config` manually.
