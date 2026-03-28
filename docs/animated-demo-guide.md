# Animated Demo Guide — Fully Scripted Terminal Recording

How to produce the README hero animation for claude-code-free, and how to
apply the same technique to any project.

---

## What this produces

An animated SVG embedded in the README that plays automatically on GitHub,
showing the complete install-to-running flow:

1. User types `curl ... | bash`
2. Installer runs, prompts are answered automatically
3. Container starts, SSH connects
4. Claude Code loads and responds to a coding prompt

No human typing required. One command produces a perfect take every time.

---

## How it works

Three tools form the pipeline:

```
expect  →  drives the terminal session (types, waits, responds)
    ↓
asciinema  →  records every character and its timing
    ↓
svg-term  →  renders the recording as an animated SVG
```

### expect

`expect` is a scripting tool (Tcl-based, ships with macOS) designed to drive
interactive terminal programs. You write a script that:

- `spawn`s a process (a shell, an SSH session, any interactive program)
- `expect`s specific output to appear before continuing
- `send`s keystrokes in response

The `type_slowly` helper in `record.exp` sends one character at a time with
a configurable delay, producing realistic human-looking typing in the recording.

### asciinema

Records a terminal session to a `.cast` file (JSON lines, one per output event,
with timestamps). The `--command` flag runs a specific command instead of an
interactive shell — here, it runs the `expect` script.

**Important:** asciinema 3.x records in v3 format. `svg-term` only supports v2.
Always convert: `asciinema convert -f asciicast-v2 input.cast output.cast`

**Important:** asciinema in headless mode (no TTY) collapses all timing — every
`after` delay in the expect script is ignored and the recording plays out at
machine speed (~10 seconds for a 3-minute install). The fix is to run the
recording in a real terminal session, not via a non-interactive shell.
See "Known issues" below.

### svg-term

Converts an asciicast v2 file to an animated SVG using CSS keyframe animations.
The SVG plays inline on GitHub, is crisp at any resolution, and has no
JavaScript dependency. The `--window` flag adds the macOS traffic-light chrome.

---

## Prerequisites

Install once:

```bash
brew install expect asciinema
npm install -g svg-term-cli
```

Versions confirmed working:

| Tool | Version |
| --- | --- |
| expect | 5.45 (ships with macOS) |
| asciinema | 3.2.0 |
| svg-term-cli | 2.1.1 |
| Node.js | 25.x (svg-term requirement) |

---

## Files in this directory

| File | Purpose |
| --- | --- |
| `record.sh` | One-command wrapper: reset → record → convert → render → open |
| `record.exp` | The expect script that drives the full session |
| `demo.svg` | Output — the animated SVG for the README (generated, not hand-edited) |

---

## Usage

```bash
OPENROUTER_KEY=sk-or-v1-your-key bash docs/record.sh
```

The script:

1. Stops and removes any existing `claude-code-free` container
2. Deletes `~/.claude-code-free` (install config)
3. Clears the `[localhost]:2223` known_hosts entry
4. Records the session via `expect` into `/tmp/claude-code-free-demo.cast`
5. Converts to asciicast v2
6. Renders to `docs/demo.svg`
7. Opens the SVG in your browser

Review the SVG. If it looks good, add it to the README:

```bash
git add docs/demo.svg README.md
git commit -m "docs: add animated demo"
git push origin main
```

---

## Tuning the recording

All timing is controlled by constants at the top of `record.exp`:

| Constant | Default | Effect |
| --- | --- | --- |
| `CHAR_DELAY` | 80ms | Delay between each character typed |
| `WORD_PAUSE` | 120ms | Extra pause after each space (between words) |
| `PROMPT_PAUSE` | 1200ms | Pause before responding to a prompt (looks like the user is reading) |

To make typing faster: lower `CHAR_DELAY`. To make it slower: raise it.
To shorten pauses at prompts: lower `PROMPT_PAUSE`.

After changing `record.exp`, re-run `record.sh` to get a new take.

---

## The API key problem

The expect script types the OpenRouter API key character by character.
This means the real key appears in the SVG recording — visible to anyone who
views it on GitHub.

Options:

1. **Use a throwaway key** — create a free OpenRouter key just for the recording,
   revoke it after. The recording will show a real-looking key that no longer works.

2. **Use a fake key** — change `set API_KEY $env(OPENROUTER_KEY)` in `record.exp`
   to `set API_KEY "sk-or-v1-xxxxxxxxxxxxxxxxxxxx"` and type that instead.
   The install will fail at the API call, but for a recording that only needs to
   show the install flow up to the container starting, this is sufficient.
   Claude Code's actual response requires a real key.

3. **Speed through the key** — set `CHAR_DELAY 5` only for the key line so it
   types too fast to read, then restore normal speed. Less clean but functional.

---

## Known issues

### Headless mode collapses timing

When `asciinema rec --command "expect ..."` runs without a real TTY (e.g. from
Claude Code's shell, a CI environment, or any non-interactive context),
asciinema records in "headless mode". In this mode, all `after` delays in the
expect script are ignored — the session completes in ~10 seconds regardless of
what delays are set.

**Symptom:** The cast file shows `Total duration: 10.0s` for a session that
should take 3-4 minutes. The SVG plays back at machine speed.

**Root cause:** In headless mode, asciinema connects its own pseudo-TTY to the
command. The expect script's `after` calls still run, but asciinema timestamps
events relative to real wall-clock time — and without a human on the other end,
the shell processes output instantly.

**Fix:** Record from a real interactive terminal session. Open a terminal
window (iTerm2, Terminal.app), set `OPENROUTER_KEY`, and run:

```bash
asciinema rec /tmp/demo.cast --cols 110 --rows 30 --command "expect docs/record.exp"
```

In an interactive terminal, `expect` runs with a real TTY attached and all
`after` delays are honoured. The recording will have natural timing.

**Workaround (post-processing):** If you already have a fast recording, the
timing can be artificially stretched using the trim script in `recording-script.md`.
This inflates gaps but does not add natural per-character timing — it looks less
convincing than a real recording.

### Platform warning in container output

The install output shows:
```
! The requested image's platform (linux/amd64) does not match the detected
  host platform (linux/arm64/v8)
```

This is a real warning (running an x86 image on Apple Silicon via Rosetta).
It is harmless — the container starts and runs correctly — but it looks messy
in the recording. Fix: build and publish an `arm64` image variant.

---

## POC results (2026-03-29)

First end-to-end test on this repo confirmed:

- `expect` drives the install successfully — all prompts answered, container starts
- `asciinema` captures the full session including Claude Code's response
- `svg-term` renders a working animated SVG with macOS window chrome
- Full flow captured in plain text: welcome → API key → model → workspace → container pull → SSH → Claude Code → real code output → exit

The recording ran in headless mode (from Claude Code's shell), so timing was
collapsed to 10 seconds. The pipeline is proven. The remaining work is running
the recording from a real terminal to get natural timing.

---

## Applying this to other projects

The same three-tool pipeline works for any project with an interactive terminal
installer or CLI tool. The only project-specific parts are:

1. **The `expect` prompts** — what text to wait for before sending input
2. **The demo interaction** — what to type once the tool is running
3. **The API key / credentials** — handled via env vars, never hard-coded

Template for a new project:

```tcl
#!/usr/bin/expect -f
set CHAR_DELAY 80

proc type_slowly {text} {
    global CHAR_DELAY
    foreach char [split $text ""] {
        send -- $char
        after $CHAR_DELAY
    }
}

spawn env TERM=xterm-256color PS1="$ " bash --norc --noprofile
expect "$ " { after 500 }

# Type your install command
type_slowly "curl -fsSL https://your-project/install.sh | bash"
send "\r"

# Wait for your first prompt and respond
expect "Your first prompt text"
after 1200
send "your response\r"

# ... continue for each prompt ...

expect eof
```

Key principles:

- Always `spawn` with `TERM=xterm-256color` and a simple `PS1` for clean output
- Use `expect -timeout N` for steps that take variable time (downloads, AI responses)
- Use `after` for deliberate pauses that make the recording feel human
- Pass secrets via env vars, never hard-code them in the script
- Run the final recording from a real terminal, not a non-interactive shell
