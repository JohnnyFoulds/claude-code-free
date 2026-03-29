# Contributing

Bug reports and pull requests are welcome.

## Before you open a PR

- Open an issue first for significant changes so we can discuss the approach.
- Keep PRs focused — one change per PR.

## How to build the image locally

```bash
git clone https://github.com/JohnnyFoulds/claude-code-free.git
cd claude-code-free
docker build -t claude-code-free:local docker/
```

## How to test install script changes

Test in a clean environment (VM or fresh Docker container) to avoid side effects on your own SSH config and Docker setup:

```bash
# Mac / Linux — pipe to bash as a user would
curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash

# Or run the local version directly
bash install.sh
```

## Reporting bugs

Please include:
- OS and version
- Docker Desktop version
- The full output of the failing command
- Whether you are on Apple Silicon (ARM64) or Intel/AMD (amd64)

## Code style

- Shell scripts: `set -euo pipefail`, no bashisms beyond what is already used
- Keep the installer idempotent — re-running should always produce a clean state
