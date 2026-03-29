const fs = require('fs');
// Path differs by base image: node:*-slim uses /usr/local/lib, ubuntu uses /usr/lib
const modulePaths = [
    '/usr/local/lib/node_modules/@anthropic-ai/claude-code/package.json',
    '/usr/lib/node_modules/@anthropic-ai/claude-code/package.json'
];
const pkgPath = modulePaths.find(p => { try { require.resolve(p); return true; } catch { return false; } });
if (!pkgPath) throw new Error('Could not find @anthropic-ai/claude-code package.json in known paths');
const v = require(pkgPath).version;

// ~/.claude.json — user state (onboarding, trust)
const userState = {
    numStartups: 1,
    hasCompletedOnboarding: true,
    lastOnboardingVersion: v,
    lastReleaseNotesSeen: v,
    projects: {
        '/workspace': {
            hasTrustDialogAccepted: true
        }
    }
};
fs.writeFileSync('/home/coder/.claude.json', JSON.stringify(userState));

// ~/.claude/settings.json — Claude Code settings
const settings = {
    permissions: {
        defaultMode: 'bypassPermissions',
        deny: ['WebSearch', 'WebFetch']
    },
    skipDangerousModePermissionPrompt: true,
    appendSystemPrompt: [
        'You have full internet access via the Bash tool. w3m and curl are installed.',
        'To search the web: use Bash to run `w3m -dump \'https://lite.duckduckgo.com/lite/?q=QUERY\' 2>/dev/null | head -c 50000` (URL-encode spaces as +).',
        'To fetch a URL: use Bash to run `w3m -dump \'URL\' 2>/dev/null | head -c 50000`.',
        'If w3m fails for a URL, fall back to:',
        '`curl -fsSL --max-time 15 -A \'Mozilla/5.0\' \'URL\' 2>/dev/null | /usr/bin/python3 -c \'import sys,markdownify; print(markdownify.markdownify(sys.stdin.read(), heading_style="ATX"))\' 2>/dev/null | head -c 50000`.',
        'Do NOT use the Agent tool for web fetching or searching — use Bash directly.',
        'WebFetch and WebSearch built-in tools are disabled; Bash is the correct method.'
    ].join(' ')
};
fs.writeFileSync('/home/coder/.claude/settings.json', JSON.stringify(settings));

// CLAUDE.md content — written to two locations:
//   ~/.claude/CLAUDE.md  — User memory, loaded globally regardless of working directory
//   /workspace/CLAUDE.md — Project memory for /workspace (written by entrypoint.sh at
//                          runtime since /workspace is a volume that shadows the image layer)
const claudeMd = `# Web access

You have internet access via the Bash tool. \`w3m\` and \`curl\` are installed.

**To search the web**, use Bash:
\`\`\`
w3m -dump 'https://lite.duckduckgo.com/lite/?q=QUERY' 2>/dev/null | head -c 50000
\`\`\`
(replace spaces in QUERY with +)

**To fetch a URL**, use Bash:
\`\`\`
w3m -dump 'URL' 2>/dev/null | head -c 50000
\`\`\`

**If w3m fails**, fall back to curl:
\`\`\`
curl -fsSL --max-time 15 -A 'Mozilla/5.0' 'URL' 2>/dev/null \\
  | python3 -c 'import sys,markdownify; print(markdownify.markdownify(sys.stdin.read(), heading_style="ATX"))' \\
  2>/dev/null | head -c 50000
\`\`\`

Do NOT use the Agent tool or WebFetch/WebSearch for web access — both are disabled. Use Bash directly.
`;
// Write to ~/.claude/CLAUDE.md — global User memory, always loaded regardless of cwd
fs.writeFileSync('/home/coder/.claude/CLAUDE.md', claudeMd);

// /workspace/CLAUDE.md is written by entrypoint.sh at runtime (volume mount shadows image layer)
