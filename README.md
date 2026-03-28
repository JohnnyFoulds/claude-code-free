# Claude Code — Free

Run [Claude Code](https://claude.ai/code), Anthropic's AI coding assistant, completely free on your own laptop. No subscription. No credit card. No GPU required.

Powered by [OpenRouter](https://openrouter.ai) — get access to dozens of free and low-cost models through a single API key.

## Install

**Mac / Linux** — paste this in a terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash
```

**Windows** — paste this in PowerShell:

```powershell
irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 | iex
```

The installer handles everything: checks Docker is running, walks you through getting a free API key, pulls the pre-built container, and configures VS Code Remote SSH. Takes about 2 minutes.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac, Windows, or Linux)
- [VS Code](https://code.visualstudio.com/) with the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension
- A free [OpenRouter](https://openrouter.ai) account — the installer walks you through this

## Why use this?

Anthropic's Claude Code requires a **Claude Pro subscription ($20/month)** or API credits that run out quickly under agentic use. This project gives you a fully working setup at no cost, using free models available on OpenRouter.

| | This project | Claude Pro |
| --- | --- | --- |
| Cost | Free | $20/month |
| Setup | One command | Built-in |
| Model quality | Good | Excellent |
| Model flexibility | Any OpenRouter model | Claude only |

**Good fit if you:**

- Want to try Claude Code before committing to a subscription
- Are a student or working in a cost-sensitive environment
- Want to experiment with different models through the same interface
- Prefer keeping your code off Anthropic's servers

**Stick with Claude Pro if you:**

- Do serious daily coding work — the quality difference is real
- Need the latest Claude Sonnet or Opus models

## Usage

After install, connect from VS Code:

1. `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
2. Select `Remote-SSH: Connect to Host` → `claude-code-free`
3. Open a terminal and run:

```bash
cd /workspace
claude
```

Your `/workspace` directory persists across container restarts.

You can also connect directly via SSH:

```bash
ssh -p 2223 coder@localhost
```

## Daily commands

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

## Switching models

The installer prompts you to choose a model. You can change it any time by editing `~/.claude-code-free/.env`:

```env
OPENROUTER_MODEL=qwen/qwen3-coder:free
```

Then restart the container:

```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down
docker compose --env-file ~/.claude-code-free/.env -f ~/.claude-code-free/docker-compose.yml up -d
```

### Free models worth trying

| Model ID | Size | Context | Good for |
| --- | --- | --- | --- |
| `stepfun/step-3.5-flash:free` | 196B MoE | 256K | **Default** — fast, well-rounded |
| `qwen/qwen3-coder:free` | 480B MoE | 262K | Code generation, agentic tasks |
| `openai/gpt-oss-120b:free` | 120B MoE | 131K | Strong reasoning, complex tasks |
| `openai/gpt-oss-20b:free` | 21B MoE | 131K | Faster, lighter version of above |
| `meta-llama/llama-3.3-70b-instruct:free` | 70B | 65K | Solid all-rounder |
| `nvidia/nemotron-3-super-120b-a12b:free` | 120B MoE | 262K | Complex reasoning |
| `mistralai/mistral-small-3.1-24b-instruct:free` | 24B | 128K | Multimodal, fast |
| `google/gemma-3-27b-it:free` | 27B | 131K | Google's largest Gemma 3 |
| `nousresearch/hermes-3-llama-3.1-405b:free` | 405B | 131K | Large, agentic tasks |

Full list: [openrouter.ai/models?q=free](https://openrouter.ai/models?q=free)

## How it works

```text
VS Code (your laptop)
    └── Remote SSH → localhost:2223
            └── Docker container  (johannesfoulds/claude-code-free)
                    ├── Claude Code CLI
                    ├── Python 3
                    ├── w3m / curl  ← web access for the model
                    └── /workspace  ← your files live here
                    └── OpenRouter API → your chosen model
```

Claude Code is built to work with any OpenAI-compatible API. This project points it at OpenRouter, which provides access to dozens of free and low-cost models through a single API key.

## What's inside the container

| Component | Version |
| --- | --- |
| OS | Alpine Linux (node:22-alpine) |
| Claude Code | latest |
| Node.js | 22 LTS |
| Python | 3 (system) |
| Web access | w3m, curl, markdownify |

## Known limitations

- **`/model` command does not work** — Claude Code's model picker is designed for Anthropic's own model roster and is not compatible with OpenRouter model IDs. Change models via `.env` as described above.
- **Free tier rate limits** — OpenRouter's free models have rate limits. If you hit them, wait a few minutes or switch to a different free model.
- **Model availability** — free models can occasionally go offline on OpenRouter's side. If a model stops responding, try a different one from the list above.

## A note on the free tier

OpenRouter's free models are community-supported and subject to change. Rate limits, availability, and which models are offered at no cost can shift without notice.

If you find yourself using this setup regularly, consider [adding credits to your OpenRouter account](https://openrouter.ai/settings/credits). Even a small balance unlocks higher rate limits and access to a much wider range of models — including stronger options that may suit your workflow better than any free-tier model currently available. OpenRouter's pricing is pay-as-you-go with no subscription required, and most models cost a fraction of a cent per request under normal coding use.

The free tier is a good way to evaluate whether the setup works for you. Paid access is how you get reliable, production-quality results.

## Uninstall

### Uninstall on Mac / Linux

```bash
docker compose -f ~/.claude-code-free/docker-compose.yml down --volumes
rm -rf ~/.claude-code-free
# Remove the 'claude-code-free' entry from ~/.ssh/config
```

### Uninstall on Windows (PowerShell)

```powershell
docker compose -f "$env:USERPROFILE\.claude-code-free\docker-compose.yml" down --volumes
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude-code-free"
# Remove the 'claude-code-free' entry from %USERPROFILE%\.ssh\config
```

## Contributing

Bug reports and pull requests are welcome. Please open an issue first for significant changes.

## License

MIT © Johannes Foulds
