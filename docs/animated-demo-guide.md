# Animated Demo Guide — Fully Scripted Terminal Recording

How to produce the README hero animation for claude-code-free, and how to
apply the same technique to any project.

---

## What this produces

An animated GIF embedded in the README that plays automatically on GitHub,
showing the complete install-to-running flow:

1. User types `curl ... | bash`
2. Installer runs, prompts are answered automatically
3. Container starts, SSH connects
4. Claude Code loads and responds to a coding prompt

No human typing required. One command produces a perfect take every time.

---

## How it works

Four tools form the pipeline:

```
kitty remote control  →  drives a real TTY terminal (keystrokes sent via unix socket)
    ↓
asciinema             →  records every character and its timing inside that terminal
    ↓
cast-v3-to-v2.py      →  converts asciinema v3 format to v2 (required by agg)
    ↓
agg                   →  renders the cast as an animated GIF
```

### Why kitty remote control

The fundamental problem with every other approach is **headless timing collapse**.
When `asciinema rec --command "..."` runs without a real TTY, all timing information
is lost — the entire recording plays back at machine speed regardless of any `sleep`
or `after` delays in the script. A 3-minute install collapses to 10 seconds.

kitty solves this because:

- asciinema runs inside a real kitty window with a real TTY
- the recording script sends keystrokes via `kitty @ send-text` from outside
- all `sleep` delays are honoured — the recording has natural timing
- no human needs to touch the keyboard

### Why agg instead of svg-term

`svg-term` was the obvious first choice but has two fatal problems:

- It bakes every frame into an inline SVG — runs out of memory (JavaScript heap OOM)
  on recordings with more than ~1000 events. A real install recording has 8000+ events.
- It produces blurry text because SVG scales inline text elements rather than rendering
  at native resolution.

`agg` is asciinema's own Rust-based renderer. It produces proper animated GIFs at
native resolution with no OOM risk regardless of recording length.

---

## One-time setup

### 1. Install tools

```bash
brew install asciinema agg
```

Versions confirmed working on macOS (Apple Silicon):

| Tool | Version |
| --- | --- |
| kitty | 0.46.1 |
| asciinema | 3.2.0 |
| agg | 1.7.0 |

`kitty` ships with macOS app bundle at `/Applications/kitty.app`. No brew install needed.

**Do not install svg-term-cli** — it is the wrong tool and will OOM on real recordings.

### 2. Enable kitty remote control

Edit `~/.config/kitty/kitty.conf` and add these two lines at the top:

```ini
allow_remote_control yes
listen_on unix:/tmp/kitty.sock
```

**Important:** `listen_on` only takes effect on startup — a config reload (`Ctrl+Shift+F5`)
does nothing. You must fully quit and restart kitty.

**Important:** kitty appends its PID to the socket path, so the actual socket will be
`/tmp/kitty.sock-<PID>`, not `/tmp/kitty.sock`. The recording script discovers it
automatically with `ls /tmp/kitty.sock-*`.

### 3. Verify remote control works

After restarting kitty, run this from any other terminal (including inside Claude Code):

```bash
SOCK=$(ls /tmp/kitty.sock-* | head -1)
kitty @ --to "unix:${SOCK}" send-text "echo hello from outside\r"
```

You should see `echo hello from outside` appear and execute in the kitty window.

If you see `Error: Remote control is disabled` — kitty did not fully restart.
Use `pkill -x kitty` to force-kill it, then reopen from the Dock or Spotlight.

If you see `Error: Failed to connect ... no such file or directory` — the socket path
is wrong. Run `ls /tmp/kitty.sock-*` to find the actual path.

---

## Usage

Open kitty. Then from any terminal (including Claude Code's shell):

```bash
OPENROUTER_KEY=sk-or-v1-your-key bash docs/record-kitty.sh
```

The script:

1. Finds the kitty socket automatically (`/tmp/kitty.sock-<PID>`)
2. Stops and removes any existing `claude-code-free` container
3. Deletes `~/.claude-code-free` (install config)
4. Clears the `[localhost]:2223` known_hosts entry
5. Sets a clean `$` prompt and clears the screen inside kitty
6. Starts `asciinema rec` inside the kitty window
7. Types the curl command, responds to every prompt, types the demo question
8. Waits for Claude's response, then exits cleanly
9. Converts the cast from asciinema v3 to v2 format
10. Renders `docs/demo.gif` with `agg`
11. Opens the GIF for review

---

## Files

| File | Purpose |
| --- | --- |
| `record-kitty.sh` | Main script — does everything from reset to rendered GIF |
| `cast-v3-to-v2.py` | Converts asciinema v3 cast to v2 format |
| `demo-reset.sh` | Standalone reset — clean docker + clean shell, for manual recording |
| `record.exp` | Legacy expect script (kept for reference — headless timing problem applies) |
| `record.sh` | Legacy shell wrapper for expect (kept for reference) |
| `demo.gif` | Output — the animated GIF for the README |

---

## Tuning

All timing is controlled by env vars:

| Variable | Default | Effect |
| --- | --- | --- |
| `CHAR_DELAY_MS` | 80 | Milliseconds between each typed character |
| `WORD_PAUSE_MS` | 120 | Extra milliseconds after each space |
| `PROMPT_PAUSE_MS` | 2000 | Pause before responding to a prompt |

```bash
OPENROUTER_KEY=sk-or-v1-... CHAR_DELAY_MS=50 PROMPT_PAUSE_MS=1500 bash docs/record-kitty.sh
```

agg rendering options (edit the `agg` call in `record-kitty.sh`):

| Flag | Effect |
| --- | --- |
| `--speed 1.5` | Play back 50% faster |
| `--idle-time-limit 3` | Cap any gap between events at 3s (default) — prevents long pauses |
| `--font-size 14` | Font size in the output GIF |

---

## The API key problem

The script types the OpenRouter API key character by character. The real key will
appear in the GIF — visible to anyone who views it on GitHub.

Options:

1. **Use a throwaway key** — create a free OpenRouter key just for the recording,
   revoke it afterwards. The GIF shows a real-looking key that no longer works.

2. **Speed through the key** — set `CHAR_DELAY_MS=5` so it types too fast to read.
   The rest of the demo runs at normal speed.

---

## Known issues and hard-won lessons

### `listen_on` requires a full restart

`kitty --reload-config` and `Ctrl+Shift+F5` do **not** apply `listen_on` changes.
The socket is only created when the kitty process starts. You must `pkill -x kitty`
and reopen the app.

### Socket has PID suffix

The configured path `unix:/tmp/kitty.sock` becomes `unix:/tmp/kitty.sock-<PID>` at
runtime. This is by design (allows multiple kitty instances). The recording script
handles this automatically — do not hardcode the socket path.

### svg-term OOM

`svg-term-cli` is not suitable for recordings longer than ~30 seconds. It will crash
with `FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory`
on any real install recording. Use `agg`.

### asciinema v3 vs v2

asciinema 3.x records in v3 format where event timestamps are **relative** (offset
from previous event). Both `agg` and `svg-term` require v2 format where timestamps
are **absolute** (seconds since start). Always run `cast-v3-to-v2.py` before rendering.

### Fancy zsh prompt in the recording

If your zsh uses Powerlevel10k or oh-my-zsh with Nerd Font glyphs, those glyphs render
as broken boxes in the output GIF because the renderer does not have the font. The
recording script works around this by switching to a clean bash shell before starting
asciinema:

```bash
exec env -i HOME="$HOME" TERM=xterm-256color PATH="$PATH" bash --norc --noprofile
PS1='$ '
```

This replaces the current shell with a clean bash that has no rc files, no conda prefix,
no Powerlevel10k, and no fancy prompt — just `$`.

### GIF file size

`agg` GIFs can be 5–20 MB for a 3-minute recording. GitHub supports animated GIFs
up to 25 MB in READMEs. If the file is too large:

- Increase `--speed` to reduce duration
- Use `--idle-time-limit 2` to compress pauses
- Run through `gifsicle -O3 input.gif -o output.gif` (brew install gifsicle)

---

## Applying this to other projects

The same pipeline works for any project with an interactive terminal installer or CLI.
The only project-specific parts are:

1. The `wait_for` patterns — what text to wait for before sending input
2. The demo interaction — what to type once the tool is running
3. API keys / credentials — pass via env vars, never hardcode

Key principles:

- Use `wait_for` (polls `kitty @ get-text`) instead of fixed sleeps — timing varies
  by network speed and machine
- Pass secrets via env vars
- The kitty window must already be open before running the script
- Run from any terminal that can reach the kitty socket (including Claude Code's shell)
