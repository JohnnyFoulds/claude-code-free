# Recording Script — claude-code-free animated SVG

Complete step-by-step script for recording the README hero animation.
Follow this exactly and you will get a clean take on the first try.

---

## Before you start — one-time setup

Install the recording tools:

```bash
brew install asciinema
npm install -g svg-term-cli
```

Make sure the container is **not** running (clean state for the demo):

```bash
docker stop claude-code-free 2>/dev/null; docker rm claude-code-free 2>/dev/null
rm -rf ~/.claude-code-free
```

Remove the SSH config entry if it exists:

```bash
# Open ~/.ssh/config and delete the Host claude-code-free block
```

Remove the known_hosts entry for the container:

```bash
ssh-keygen -R "[localhost]:2223" 2>/dev/null
```

---

## Terminal setup

Open a fresh terminal window — **not** a tab, a full window.

Set the terminal size to exactly 110 columns × 30 rows:

```bash
printf '\e[8;30;110t'
```

Simplify the prompt so it looks clean on screen:

```bash
export PS1='$ '
export TERM=xterm-256color
clear
```

Use a dark theme. If you are on the default macOS Terminal: Preferences → Profiles → Pro. If you use iTerm2: any dark profile works.

---

## The Claude prompt to use

You will paste this when Claude Code asks for input. Choose one — both work well on screen:

**Option 1 — shows planning + code generation (recommended):**
```
write a python function that reads a csv file and returns the top 5 rows sorted by a given column. include type hints and a docstring.
```

**Option 2 — shows code review + fixes:**
```
write a small python web scraper that fetches the title and first paragraph from any url. keep it simple.
```

Both produce 20-30 lines of streaming output — enough to look impressive, short enough to stay in frame.

---

## The recording — follow this exactly

### Step 1: Start recording

```bash
asciinema rec /tmp/claude-code-free.cast --cols 110 --rows 30 --title "claude-code-free"
```

You are now recording. Everything you type is captured with timing.

---

### Step 2: Pause 1 second, then type the curl command SLOWLY

Type each word deliberately — pause half a second between words so the viewer can read it:

```
$ curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash
```

Press Enter. The installer will run.

---

### Step 3: Walk through the installer

The installer will show the welcome screen and prompts. Respond as follows:

| Prompt | What to do |
| --- | --- |
| Press Enter to continue | Press Enter (pause 1 second first so it reads naturally) |
| Install Docker? | Not shown — Docker is already running |
| Paste your OpenRouter API key | Paste your real key — type it deliberately, not fast |
| Model ID (or Enter for default) | Press Enter — accept the default |
| Choose workspace [1/2/3] | Press `1` then Enter |
| Try Claude Code right now? | Press `y` then Enter |

The installer will pull the container (first run — this takes 1-2 minutes, that is fine, the animation can be trimmed later) and then connect via SSH automatically.

---

### Step 4: Inside the container — type the Claude prompt SLOWLY

You are now inside the container. The installer dropped you straight into Claude Code.

Pause 2 seconds so the viewer sees the Claude Code header clearly.

Then type the prompt slowly, one word at a time:

```
write a python function that reads a csv file and returns the top 5 rows sorted by a given column. include type hints and a docstring.
```

Press Enter.

---

### Step 5: Let Claude respond — do nothing

Watch Claude stream its response. Do not touch the keyboard.

Wait until the response is fully complete and the Claude Code prompt returns.

---

### Step 6: Exit

```
exit
```

This exits the SSH session and drops you back to your local terminal.

---

### Step 7: Stop recording

Press `Ctrl+D` to stop the asciinema recording.

It will print something like:
```
asciinema: recording finished
asciinema: press <enter> to upload to asciinema.org, or <ctrl-c> to save locally
```

Press `Ctrl+C` to save locally (do not upload).

---

## Convert to SVG

```bash
svg-term --cast /tmp/claude-code-free.cast \
  --out docs/screenshot-examples/demo.svg \
  --window \
  --width 110 \
  --height 30 \
  --term iterm2
```

Open the SVG in a browser to check it:

```bash
open docs/screenshot-examples/demo.svg
```

It should autoplay in the browser. Watch the full thing — check that:

- The curl command is readable
- The installer prompts are visible
- The Claude Code header is clearly visible after SSH connects
- The Claude response streams visibly
- Nothing looks rushed or cut off

---

## Trim if needed

If the container pull (step 3) creates a long boring wait, trim it with:

```bash
# Install if needed: pip install asciinema
python3 -c "
import json, sys

with open('/tmp/claude-code-free.cast') as f:
    lines = f.readlines()

header = json.loads(lines[0])
events = [json.loads(l) for l in lines[1:] if l.strip()]

# Find gaps longer than 3 seconds and compress them to 1.5 seconds
trimmed = []
prev_time = 0
adjustment = 0
for event in events:
    t = event[0]
    gap = t - prev_time
    if gap > 3.0:
        adjustment += gap - 1.5
    event[0] = round(t - adjustment, 6)
    prev_time = t
    trimmed.append(event)

with open('/tmp/claude-code-free-trimmed.cast', 'w') as f:
    f.write(json.dumps(header) + '\n')
    for e in trimmed:
        f.write(json.dumps(e) + '\n')

print('Done. Trimmed cast saved to /tmp/claude-code-free-trimmed.cast')
"
```

Then re-run svg-term with `/tmp/claude-code-free-trimmed.cast` instead.

---

## Add to README

Once you are happy with the SVG:

```bash
cp docs/screenshot-examples/demo.svg docs/demo.svg
```

Edit `README.md` — add this line directly below the badges, before the first paragraph:

```markdown
![claude-code-free in action](docs/demo.svg)
```

Commit:

```bash
git add docs/demo.svg README.md
git commit -m "docs: add animated demo to README"
git push origin main
```

---

## If the take is bad — reset and retry

```bash
docker stop claude-code-free; docker rm claude-code-free
rm -rf ~/.claude-code-free
ssh-keygen -R "[localhost]:2223"
clear
```

Then start again from **The recording** section. The container image is already cached so the pull step will be instant on the second take.

---

## Better approach: fully scripted recording with expect

The manual approach above relies on a human typing without mistakes, at consistent speed, responding to prompts at the right moment. One typo or hesitation ruins the take.

The better approach is to script the entire session using `expect` — a tool designed to drive interactive terminal programs automatically. The `expect` script plays the role of the human: it types each character at a controlled speed, waits for specific output before continuing, and responds to every prompt automatically. The result is a perfectly repeatable, mistake-free recording every time.

### How it works

```text
asciinema rec  →  runs a shell  →  expect script drives that shell
                                    ├── types curl command (char by char, human speed)
                                    ├── waits for "Press Enter" prompt → sends Enter
                                    ├── waits for "API key" prompt → sends key
                                    ├── waits for model/workspace prompts → sends defaults
                                    ├── waits for SSH to connect
                                    ├── waits for Claude Code header
                                    ├── types the demo prompt (char by char, slow)
                                    ├── waits for Claude to finish responding
                                    └── types exit
```

`asciinema` captures every character and its exact timing. The SVG plays back exactly what `expect` produced — indistinguishable from a human typing it live.

### What you need to decide before writing the script

**1. The demo prompt** — what Claude is asked to do. Needs to:

- Produce visually rich streaming output (20-40 lines)
- Complete in under 30 seconds (viewer attention)
- Show something a developer immediately recognises as useful

Current best candidate:

```text
write a python function that reads a csv file and returns the top 5
rows sorted by a given column. include type hints and a docstring.
```

**2. The OpenRouter API key** — the script needs a real key to get a real Claude response. Options:

- Hard-code it in the script (keep the script out of git, or use a throwaway key)
- Pass it as an environment variable: `OPENROUTER_KEY=sk-or-v1-... bash record.sh`

**3. Typing speeds** — tunable constants at the top of the script:

- `CHAR_DELAY` — milliseconds between each character (default: 80ms, human typing ~12 chars/sec)
- `PROMPT_PAUSE` — seconds to pause before responding to a prompt (default: 1.0s, looks natural)
- `POST_RESPONSE_PAUSE` — seconds to wait after Claude finishes before typing exit (default: 2.0s)

### Tools required

```bash
brew install expect asciinema
npm install -g svg-term-cli
```

### The two scripts

The implementation is split into two files:

**`docs/record.exp`** — the `expect` script that drives the session. Contains all the
prompts to wait for, all the responses to send, and the typing speed logic. This is the
file you edit to change what gets typed or how fast.

**`docs/record.sh`** — a thin shell wrapper that:

1. Resets the environment to a clean state
2. Sets terminal dimensions (110×30)
3. Launches `asciinema rec` with `record.exp` as the command
4. Converts the resulting `.cast` file to SVG via `svg-term`
5. Opens the SVG in the browser for review

To produce a new recording:

```bash
OPENROUTER_KEY=sk-or-v1-your-key-here bash docs/record.sh
```

That is the entire workflow. One command, clean take every time.

### Re-recording after a script change

Because the session is fully scripted, you can iterate on what Claude is asked, how fast
things type, or what prompts are used — then re-record instantly with the same command.
No human involvement required between takes.

### Status

**Not yet implemented.** The `record.exp` and `record.sh` scripts need to be written.
All design decisions above need to be confirmed before writing them:

- [ ] Confirm demo prompt
- [ ] Confirm API key handling approach (env var recommended)
- [ ] Confirm desired total animation length (target: 60-90 seconds)
- [ ] Write `docs/record.exp`
- [ ] Write `docs/record.sh`
- [ ] Test full pipeline: record → convert → review SVG
- [ ] Add `docs/demo.svg` to README
