# Screenshot Guide — claude-code-free README hero image

## Goal

One screenshot that shows Claude Code running inside VS Code Remote SSH, actively solving a real coding problem. Goes directly below the badges in README.md.

---

## Setup (5 minutes)

1. Open VS Code on your Mac
2. `Cmd+Shift+P` → `Remote-SSH: Connect to Host` → `claude-code-free`
3. Once connected, open the Explorer panel (`Cmd+Shift+E`)
4. Open a terminal inside VS Code (`Ctrl+\``)

---

## Create the sample project

In the VS Code terminal (inside the container):

```bash
mkdir -p /workspace/demo && cd /workspace/demo
```

Create this file — `buggy.py`:

```python
def find_duplicates(items):
    seen = []
    dupes = []
    for item in items:
        if item in seen:
            dupes.append(item)
        seen.append(item)
    return dupes

def merge_sorted(a, b):
    result = []
    while a and b:
        if a[0] < b[0]:
            result.append(a.pop(0))
        else:
            result.append(b.pop(0))
    result += a
    result += b
    return result

def flatten(nested):
    flat = []
    for item in nested:
        if type(item) == list:
            flat.extend(flatten(item))
        else:
            flat.append(item)
    return flat
```

Open `buggy.py` in the VS Code editor (click it in the Explorer). This gives you code visible on the left side.

---

## Trigger the money shot

In the terminal, run:

```bash
cd /workspace/demo && claude
```

Wait for Claude Code to load, then paste this prompt:

```
Review buggy.py and fix any performance issues, add proper type hints, and write pytest tests for all three functions. Show me the plan first.
```

This prompt is chosen because:
- It produces a multi-step plan first (visually rich output)
- Then writes real code with syntax highlighting
- Long enough response that you can screenshot mid-stream

---

## The screenshot moment

**Screenshot while Claude is actively streaming the response** — not before, not after. You want to catch it mid-output, ideally while it's writing the test code. The streaming cursor and partial output make it look alive.

**VS Code layout before screenshotting:**
- Left panel: Explorer showing `demo/buggy.py`, file open in editor showing the Python code
- Right panel: terminal with Claude Code streaming its response
- Hide the left activity bar icons if they look cluttered: `View → Appearance → Hide Activity Bar`
- Use a dark theme (Cmd+K Cmd+T → pick One Dark Pro or default Dark+)
- Make VS Code full screen (`Ctrl+Cmd+F`)

---

## Taking the screenshot

```
Cmd+Shift+4
```

Drag to capture the full VS Code window. Save as `docs/screenshot.png`.

---

## Add to README

Edit `README.md` — add this line directly below the badges, before the first paragraph:

```markdown
![Claude Code running in VS Code via Remote SSH](docs/screenshot.png)
```

Then commit:

```bash
git add docs/screenshot.png README.md
git commit -m "docs: add hero screenshot"
git push origin main
```

---

## What good looks like

- Dark background, code visible on left, Claude mid-response on right
- The `Claude Code` header visible at top of terminal panel
- At least 10-15 lines of Claude output visible — catch it while writing the test functions
- No personal info visible (check terminal prompt doesn't show your username/hostname if you care)
