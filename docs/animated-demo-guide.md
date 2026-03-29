# Animated Demo Guide

How to produce the README hero animation for claude-code-free, and how to
apply the same technique to any CLI project.

---

## What this produces

An animated GIF embedded in the README that plays automatically on GitHub,
showing the complete install-to-running flow:

1. User types `curl ... | bash`
2. Installer runs, prompts are answered automatically
3. Container starts, SSH connects
4. Claude Code loads and responds to a coding prompt

No human typing required. One command produces a repeatable take every time.

---

## Pipeline

```text
demo.tape  →  vhs  →  docs/demo.gif
```

VHS reads the tape file, drives a virtual terminal internally, and produces
the GIF. One tool, one file, one command.

---

## Re-recording this demo (claude-code-free specific)

### Prerequisites (one-time)

```bash
brew install vhs
```

`docker/.env.local` must contain `OPENROUTER_API_KEY=sk-or-v1-...`

### Run

```bash
bash docs/record.sh
```

That's it. The script:

1. Reads the API key from `docker/.env.local`
2. Resets the environment (stops container, removes `~/.claude-code-free`, clears known_hosts)
3. Runs VHS with the key injected
4. Opens `docs/demo.gif` in Safari for review

### When to re-record

- `install.sh` prompts change — update the `Wait` patterns in `demo.tape`
- Default model changes — update the comment in `demo.tape`
- Claude Code UI changes — update the `Wait /❯/` pattern if the prompt symbol changes
- The demo question should be updated — edit the `Type` line near the bottom of `demo.tape`

### Files

| File | Purpose |
| --- | --- |
| `demo.tape` | The storyboard and automation script — edit this to change the demo |
| `record.sh` | Wrapper: resets env, injects API key, runs VHS, opens output |
| `demo.gif` | Output — committed to the repo, embedded in README |

---

## How demo.tape works

`demo.tape` is a VHS tape file. Every line is either a setting or an action.
The comments explain every beat — it reads like a storyboard.

Key commands used:

| Command | What it does |
| --- | --- |
| `Type "text"` | Types text at `TypingSpeed` ms per character |
| `Enter` | Presses Enter |
| `Wait /regex/` | Waits for matching text to appear on screen before continuing |
| `Sleep Ns` | Pauses for N seconds (used for dramatic effect after prompts) |
| `Set TypingSpeed Xms` | How fast characters are typed |
| `Set WaitTimeout Xs` | How long to wait before a `Wait` times out |
| `Set Theme "name"` | Terminal colour theme |
| `Set WindowBar Colorful` | macOS-style traffic light window chrome |

### The Wait + Sleep pattern

Every prompt follows this pattern:

```text
Wait /prompt text/    # wait for it to actually appear on screen
Sleep 1s              # deliberate pause so viewer can read it
Type "response"       # respond
Enter
```

`Wait` is what makes the script robust — it never moves on until the prompt
is actually visible. `Sleep` after `Wait` is purely for the viewer's benefit.
Never use `Sleep` as a substitute for `Wait`.

### The Claude response problem

`Wait+Screen /❯/` (wait for screen change + prompt) does not work reliably
when the session involves SSH into a container — VHS's internal shell exits
when the SSH session ends and restarts, losing context. Use `Sleep` instead:

```text
Sleep 35s    # Step-3.5-Flash typically responds in 20-30s on free tier
```

Adjust this value if the response gets cut off or the GIF ends too early.

---

## Applying this to other projects

The same pipeline works for any project with an interactive terminal installer
or CLI tool. The only project-specific parts are:

1. The `Wait` patterns — what text to wait for before sending input
2. The demo interaction — what to type once the tool is running
3. API keys / credentials — injected at run time, never in the tape file

### Template tape file

```text
# demo.tape — <your project> README hero animation
# Edit this to change the demo. Run: bash docs/record.sh

Output docs/demo.gif

Set Shell bash
Set WindowBar Colorful
Set Width 1200
Set Height 600
Set FontSize 22
Set Theme "Dracula"
Set TypingSpeed 50ms
Set WaitTimeout 120s

# === Install ===
Type "curl -fsSL https://your-project/install.sh | bash"
Enter

Wait /your first prompt/
Sleep 1s
Type "your response"
Enter

# Add one Wait + Sleep + Type block per prompt

# === Demo ===
Wait /ready prompt/
Sleep 2s
Type "your demo command"
Enter

Sleep 10s    # adjust to match how long your tool takes to respond

Type "exit"
Enter
Sleep 1s
```

### Template record.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read credentials from .env.local (never hardcode in tape file)
API_KEY=$(grep '^YOUR_API_KEY=' "${SCRIPT_DIR}/../.env.local" | cut -d= -f2-)

# Reset environment
# (add project-specific reset commands here)

# Inject credentials and run
sed "s|API_KEY_PLACEHOLDER|${API_KEY}|g" "${SCRIPT_DIR}/demo.tape" \
    > /tmp/demo-with-key.tape
vhs /tmp/demo-with-key.tape
rm /tmp/demo-with-key.tape

open -a Safari "${SCRIPT_DIR}/demo.gif"
```

### Key principles

- `Wait /regex/` instead of `Sleep` for synchronisation — robust, not timing-based
- `Sleep` only for deliberate viewer pauses after prompts
- Credentials injected via `sed` at run time — never stored in the tape file
- The tape file IS the storyboard — comments explain every beat
- `Set WaitTimeout` must be long enough for slow operations (docker pull, AI responses)
- `Set WindowBar Colorful` + `Set Theme "Dracula"` is the production-quality baseline

### Production style settings (from literature review)

| Setting | Value | Why |
| --- | --- | --- |
| `Set Width` | 1200 | GitHub renders READMEs at ~800px; 1200 is crisp at that size |
| `Set Height` | 600 | Fits most install flows without too much empty space |
| `Set FontSize` | 22 | Readable at display size |
| `Set Theme` | Dracula | High contrast, widely recognised, looks professional |
| `Set WindowBar` | Colorful | Immediately signals "this is a terminal" to viewers |
| `Set TypingSpeed` | 50ms | Confident typist; not so fast it looks automated |

---

## Known issues and hard-won lessons

### Wait+Screen does not work with SSH sessions

`Wait+Screen /regex/` waits for the screen content to change and then match.
It fails when the session involves SSHing into a container: VHS's internal
shell exits when the SSH session ends and VHS restarts it, losing all context.
Use `Sleep` with a generous timeout for steps that involve SSH.

### VHS output path cannot start with /tmp/

VHS parses the `Output` path and treats `/` as a command separator.
Use relative paths: `Output docs/demo.gif`, not `Output /tmp/demo.gif`.

### Set PlaybackSpeed is not a mid-tape command

`Set PlaybackSpeed` can only be set once at the top of the tape — it applies
to the entire recording. It cannot be used to speed up a specific section
(e.g. a docker pull). For per-section speed control, use the dual-recording
approach: record with asciinema, post-process the `.cast` timestamps, render
with `agg`. See `docs/demo-recording-best-practices.md` for details.

### Exec is not a valid VHS command

Environment reset (stopping containers, clearing config) must happen in the
`record.sh` wrapper before VHS runs — not inside the tape file.
