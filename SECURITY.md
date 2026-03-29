# Security Policy

## Reporting a vulnerability

Please do not report security vulnerabilities via public GitHub issues.

Email **hfoulds@gmail.com** with:
- A description of the vulnerability
- Steps to reproduce
- Potential impact

You will receive a response within 72 hours. If the issue is confirmed, a fix will be prioritised and you will be credited in the release notes.

## Threat model

This project runs an SSH server on `localhost:2223` inside a Docker container. Key points:

- The SSH server is bound to `localhost` only — it is not exposed to your network by default.
- Credentials (OpenRouter API key) are stored in `~/.claude-code-free/.env` on your machine and injected into the container at runtime. They are never transmitted anywhere other than the OpenRouter API.
- The container runs as a non-root user (`coder`). `sudo` is available inside the container without a password — do not expose the container port beyond localhost.
- `StrictHostKeyChecking no` is set for `localhost:2223` in your SSH config. This is intentional and scoped to localhost only.

## What this project does NOT protect against

- A malicious actor with local access to your machine.
- Exposure of the container SSH port to a network (do not change the port binding to `0.0.0.0`).
