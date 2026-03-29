# demo.tape — claude-code-free README hero animation
#
# This file is both the automation script and the storyboard.
# Every beat of the demo is documented here as a comment.
#
# Usage:
#   bash docs/record.sh
#
# Requirements:
#   brew install vhs
#   OPENROUTER_API_KEY must be set in docker/.env.local
#
# To re-record after install.sh changes:
#   1. Update the Wait patterns below to match any new prompt text
#   2. Run: bash docs/record.sh
#
# Timing notes:
#   - TypingSpeed: 50ms/char feels like a confident human typist
#   - Sleep 1s after each Wait: gives the viewer time to read the prompt
#     before the answer appears
#   - Sleep 2s before the demo question: viewer reads the Claude Code UI
#   - Sleep 35s for Claude's response: model typically responds in 20-30s

Output docs/demo.gif

Set Shell bash
Set WindowBar Colorful
Set Width 1200
Set Height 600
Set FontSize 22
Set Theme "Dracula"
Set TypingSpeed 50ms
Set WaitTimeout 300s

# ---------------------------------------------------------------------------
# ACT 1: Install
# Viewer sees the curl command being typed, then the installer running.
# ---------------------------------------------------------------------------

Type "curl -fsSL https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.sh | bash"
Enter

# Welcome screen — pause so viewer can read it before we press Enter
Wait /Press Enter to continue/
Sleep 1s
Enter

# API key prompt — pause, then type the key
Wait /Paste your OpenRouter API key/
Sleep 1s
Type "OPENROUTER_API_KEY_PLACEHOLDER"
Enter

# Model selection — accept the default (Step-3.5-Flash)
Wait /Model ID/
Sleep 1s
Enter

# Workspace selection — choose option 1 (home directory)
Wait /Choose/
Sleep 1s
Type "1"
Enter

# ---------------------------------------------------------------------------
# ACT 2: Container start
# Docker pull is cached so it runs fast — viewer sees it flash past.
# First-time users will see a real download (~2 min). See README note.
# ---------------------------------------------------------------------------

Wait /Try Claude Code right now/
Sleep 1s
Type "y"
Enter

# ---------------------------------------------------------------------------
# ACT 3: Claude Code
# SSH connects, Claude Code loads. Pause so viewer can take in the UI
# before we type the demo question.
# ---------------------------------------------------------------------------

Wait /❯/
Sleep 2s

Type "write a python function to read a csv and return the top 5 rows sorted by a column"
Enter

# Wait for Claude to finish responding.
# Step-3.5-Flash typically responds in 20-30s on free tier.
# Increase this if the response gets cut off.
Sleep 35s

# ---------------------------------------------------------------------------
# Exit
# ---------------------------------------------------------------------------

Type "exit"
Enter

Sleep 1s
