# install.ps1 - Set up Claude Code (free AI coding assistant) on Windows.
#
# One-liner usage (run in PowerShell as your normal user):
#   irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 | iex
#
# Or with your API key pre-supplied:
#   $env:OPENROUTER_API_KEY="sk-or-v1-your-key-here"
#   irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$GITHUB_RAW   = "https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main"
$INSTALL_DIR  = "$env:USERPROFILE\.claude-code-free"
$SSH_PORT     = 2222
$SSH_CONFIG_HOST = "claude-code"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Info    { param($msg) Write-Host "  [*] $msg" -ForegroundColor Cyan }
function Ok      { param($msg) Write-Host "  [+] $msg" -ForegroundColor Green }
function Warn    { param($msg) Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Heading { param($msg) Write-Host "`n--- $msg ---`n" -ForegroundColor Cyan }

function Download {
    param($file)
    Info "Downloading $file..."
    Invoke-WebRequest -Uri "$GITHUB_RAW/$file" -OutFile "$INSTALL_DIR\$file" -UseBasicParsing
}

# ---------------------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  Claude Code - Free AI Coding Assistant" -ForegroundColor Cyan
Write-Host "  Powered by Step-3.5-Flash via OpenRouter (free tier)"
Write-Host ""
Write-Host "  This script will:"
Write-Host "    1. Check that Docker Desktop is running"
Write-Host "    2. Ask for your free OpenRouter API key (if not provided)"
Write-Host "    3. Download and start the Claude Code container"
Write-Host "    4. Configure VS Code Remote SSH"
Write-Host ""
Write-Host "  Takes about 5 minutes on first run."
Write-Host ""
Read-Host "  Press Enter to continue, or Ctrl-C to cancel"

# ---------------------------------------------------------------------------
# Step 1: Docker
# ---------------------------------------------------------------------------
Heading "Step 1: Docker Desktop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "  Docker is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    Write-Host "  Then re-run this script."
    exit 1
}

try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host ""
    Write-Host "  Docker Desktop is not running." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please start Docker Desktop and wait for it to fully load,"
    Write-Host "  then re-run this script."
    exit 1
}

$dockerVersion = (docker --version) -replace "Docker version ([0-9.]+).*", '$1'
Ok "Docker Desktop is running ($dockerVersion)"

# ---------------------------------------------------------------------------
# Step 2: OpenRouter API key
# ---------------------------------------------------------------------------
Heading "Step 2: OpenRouter API key"

$apiKey = $env:OPENROUTER_API_KEY

if (-not $apiKey) {
    Write-Host "  You need a free OpenRouter API key to use Claude Code."
    Write-Host ""
    Write-Host "  To get one (takes 1 minute):"
    Write-Host "    1. Go to https://openrouter.ai"
    Write-Host "    2. Sign up with Google or GitHub"
    Write-Host "    3. Go to https://openrouter.ai/keys"
    Write-Host "    4. Click 'Create key' and copy it"
    Write-Host ""
    Write-Host "  The key looks like: sk-or-v1-abc123..."
    Write-Host ""

    while ($true) {
        $apiKey = Read-Host "  Paste your OpenRouter API key"
        if ($apiKey -match "^sk-or-v1-") {
            break
        }
        Warn "That doesn't look right - it should start with 'sk-or-v1-'. Try again."
    }
}

Ok "API key accepted."

# ---------------------------------------------------------------------------
# Step 3: SSH public key (optional, silent)
# ---------------------------------------------------------------------------
$sshPubKey = ""
$sshKeyPaths = @(
    "$env:USERPROFILE\.ssh\id_ed25519.pub",
    "$env:USERPROFILE\.ssh\id_rsa.pub"
)
foreach ($keyPath in $sshKeyPaths) {
    if (Test-Path $keyPath) {
        $sshPubKey = Get-Content $keyPath -Raw
        $sshPubKey = $sshPubKey.Trim()
        break
    }
}

# ---------------------------------------------------------------------------
# Step 4: Download files
# ---------------------------------------------------------------------------
Heading "Step 4: Downloading container files"

New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

foreach ($file in @("Dockerfile", "entrypoint.sh", "set-env.sh", "docker-compose.yml")) {
    Download $file
}

Ok "Files downloaded to $INSTALL_DIR"

# ---------------------------------------------------------------------------
# Step 5: Write .env and start container
# ---------------------------------------------------------------------------
Heading "Step 5: Starting container"

$envContent = "OPENROUTER_API_KEY=$apiKey`nSSH_AUTHORIZED_KEY=$sshPubKey"
Set-Content -Path "$INSTALL_DIR\.env" -Value $envContent

# Stop existing container if running
$existing = docker ps -aq --filter "name=^claude-code$" 2>$null
if ($existing) {
    Info "Removing existing container..."
    docker compose -f "$INSTALL_DIR\docker-compose.yml" down 2>$null
}

Info "Building and starting Claude Code container..."
Info "(First run downloads ~500 MB and takes a few minutes)"
Write-Host ""
docker compose --env-file "$INSTALL_DIR\.env" -f "$INSTALL_DIR\docker-compose.yml" up -d --build
Write-Host ""
Ok "Container started."

# ---------------------------------------------------------------------------
# Step 6: VS Code SSH config
# ---------------------------------------------------------------------------
Heading "Step 6: VS Code SSH config"

$sshDir    = "$env:USERPROFILE\.ssh"
$sshConfig = "$sshDir\config"

New-Item -ItemType Directory -Force -Path $sshDir | Out-Null

$entry = @"

Host $SSH_CONFIG_HOST
    HostName localhost
    Port $SSH_PORT
    User coder
    StrictHostKeyChecking no
"@

if (Test-Path $sshConfig) {
    $existing = Get-Content $sshConfig -Raw
    if ($existing -match "Host $SSH_CONFIG_HOST") {
        Ok "SSH config entry already exists."
    } else {
        Add-Content -Path $sshConfig -Value $entry
        Ok "SSH config entry added."
    }
} else {
    Set-Content -Path $sshConfig -Value $entry.TrimStart()
    Ok "SSH config file created."
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Heading "All done"

Write-Host "  Claude Code is running and ready."
Write-Host ""
Write-Host "  Connect from VS Code:"
Write-Host "    1. Install the 'Remote - SSH' extension (if not already installed)"
Write-Host "    2. Press Ctrl+Shift+P"
Write-Host "    3. Type:   Remote-SSH: Connect to Host"
Write-Host "    4. Select: $SSH_CONFIG_HOST"
if (-not $sshPubKey) {
    Write-Host "    5. Password: coder"
}
Write-Host ""
Write-Host "  Once connected, open a VS Code terminal and run:"
Write-Host "    cd /workspace"
Write-Host "    claude"
Write-Host ""
Write-Host "  To stop:    docker compose -f $INSTALL_DIR\docker-compose.yml down"
Write-Host "  To restart: docker compose -f $INSTALL_DIR\docker-compose.yml up -d"
Write-Host ""
