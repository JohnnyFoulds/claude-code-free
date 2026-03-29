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

- The SSH server listens on port 2223. By default Docker binds this to `0.0.0.0:2223`, which is reachable by other devices on your local network. If you want to restrict it to localhost only, change the port binding in `~/.claude-code-free/docker-compose.yml` from `"2223:22"` to `"127.0.0.1:2223:22"`.
- Credentials (OpenRouter API key) are stored in `~/.claude-code-free/.env` on your machine and injected into the container at runtime. They are never transmitted anywhere other than the OpenRouter API.
- The container runs as a non-root user (`coder`), but `sudo` is available without a password. Any code running inside the container — including Claude Code in `bypassPermissions` mode — can escalate to root within the container.
- `StrictHostKeyChecking no` is set for `localhost:2223` in your SSH config. This is intentional and scoped to that host entry only.

## What this project does NOT protect against

- A malicious actor with local access to your machine.
- Other devices on your local network reaching port 2223 unless you restrict the binding to `127.0.0.1` as described above.
