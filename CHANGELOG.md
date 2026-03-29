# Changelog

All notable changes to this project will be documented here.

## [Unreleased]

## [1.0.0] — 2026-03-29

### Added
- One-command installer for Mac/Linux (`install.sh`) and Windows (`install.ps1`)
- Docker image based on `node:22-slim` with Claude Code, SSH server, Python, w3m, lynx
- Multi-platform Docker image: `linux/amd64` and `linux/arm64` (Apple Silicon)
- GitHub Actions CI: automated Docker build and push to Docker Hub on every push to `main`
- OpenRouter model selection during install with sensible default (`stepfun/step-3.5-flash:free`)
- VS Code Remote SSH integration configured automatically by installer
- Workspace volume persisted across container restarts
- Web access inside container via `w3m`, `curl`, and `markdownify`
