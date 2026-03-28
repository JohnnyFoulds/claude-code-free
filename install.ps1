# install.ps1 - Set up Claude Code (free AI coding assistant) on Windows.
#
# One-liner usage (run in PowerShell as your normal user):
#   irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 | iex
#
# Or with your API key pre-supplied:
#   $env:OPENROUTER_API_KEY="sk-or-v1-your-key-here"
#   irm https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$GITHUB_RAW      = "https://raw.githubusercontent.com/JohnnyFoulds/claude-code-free/main"
$INSTALL_DIR     = "$env:USERPROFILE\.claude-code-free"
$CONTAINER_NAME  = "claude-code-free"
$SSH_PORT        = 2223
$SSH_CONFIG_HOST = "claude-code-free"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Info    { param($msg) Write-Host "  [*] $msg" -ForegroundColor Cyan }
function Ok      { param($msg) Write-Host "  [+] $msg" -ForegroundColor Green }
function Warn    { param($msg) Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Err     { param($msg) Write-Host "  [x] $msg" -ForegroundColor Red }
function Heading { param($msg) Write-Host "`n--- $msg ---`n" -ForegroundColor Cyan }

function WaitForDocker {
    Info "Waiting for Docker to be ready..."
    $elapsed = 0
    while ($true) {
        try {
            docker info 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { break }
        } catch {}
        Start-Sleep -Seconds 3
        $elapsed += 3
        Write-Host -NoNewline "."
        if ($elapsed -ge 120) {
            Write-Host ""
            Err "Docker did not start within 2 minutes."
            Write-Host "  Please open Docker Desktop manually and re-run this script."
            exit 1
        }
    }
    Write-Host ""
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
Write-Host "    1. Install Docker if needed, or start it if not running"
Write-Host "    2. Ask for your free OpenRouter API key"
Write-Host "    3. Ask where to store your workspace files"
Write-Host "    4. Download and start the Claude Code container"
Write-Host "    5. Configure VS Code Remote SSH"
Write-Host ""
Write-Host "  Takes about 2-5 minutes on first run."
Write-Host ""
Read-Host "  Press Enter to continue, or Ctrl-C to cancel"

# ---------------------------------------------------------------------------
# Step 1: Docker
# ---------------------------------------------------------------------------
Heading "Step 1: Docker Desktop"

$dockerInstalled = $null -ne (Get-Command docker -ErrorAction SilentlyContinue)

if (-not $dockerInstalled) {
    Warn "Docker Desktop is not installed."
    Write-Host ""
    $answer = Read-Host "  Install Docker Desktop now? [Y/n]"
    if ($answer -match "^[Nn]") {
        Write-Host ""
        Write-Host "  Install it from: https://www.docker.com/products/docker-desktop/"
        Write-Host "  Then re-run this script."
        exit 0
    }
    Write-Host ""
    Info "Downloading Docker Desktop installer..."

    $arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
    if ($arch -match "ARM") {
        $dockerUrl = "https://desktop.docker.com/win/main/arm64/Docker%20Desktop%20Installer.exe"
    } else {
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    }

    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"
    Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath -UseBasicParsing
    Info "Running Docker Desktop installer (you may see a UAC prompt — click Yes)..."
    Write-Host ""
    Warn "NOTE: The Docker Desktop installer may close this terminal when it finishes."
    Warn "If that happens, simply re-run this script — Docker will already be installed."
    Write-Host ""
    Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet", "--accept-license" -Wait
    Remove-Item $installerPath -Force

    Ok "Docker Desktop installed."
    Info "Starting Docker Desktop..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    WaitForDocker

} else {
    # Installed — check if running
    $isRunning = $false
    try {
        docker info 2>&1 | Out-Null
        $isRunning = ($LASTEXITCODE -eq 0)
    } catch {}

    if (-not $isRunning) {
        Warn "Docker Desktop is installed but not running."
        $answer = Read-Host "  Start Docker Desktop now? [Y/n]"
        if ($answer -match "^[Nn]") {
            Write-Host "  Please start Docker Desktop manually and re-run this script."
            exit 0
        }
        Info "Starting Docker Desktop..."

        $dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerExe) {
            Start-Process $dockerExe
        } else {
            $found = Get-ChildItem "C:\Program Files\Docker" -Recurse -Filter "Docker Desktop.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                Start-Process $found.FullName
            } else {
                Err "Could not find Docker Desktop executable."
                Write-Host "  Please start Docker Desktop manually and re-run this script."
                exit 1
            }
        }
        WaitForDocker
    }
}

# Final check
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Err "Docker is still not running."
    Write-Host "  Please start Docker Desktop manually and re-run this script."
    exit 1
}

$dockerVersion = (docker --version) -replace "Docker version ([0-9.]+).*", '$1'
Ok "Docker is ready ($dockerVersion)"

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
# Step 2b: Model selection (optional)
# ---------------------------------------------------------------------------
$defaultModel = "stepfun/step-3.5-flash:free"
$model = $env:OPENROUTER_MODEL

if (-not $model) {
    Write-Host ""
    Write-Host "  Default model: $defaultModel"
    Write-Host "  To use a different OpenRouter model, enter its ID below."
    Write-Host "  Press Enter to keep the default."
    Write-Host ""
    $model = Read-Host "  Model ID (or Enter for default)"
}

if (-not $model) {
    $model = $defaultModel
}

Ok "Model: $model"

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
        $sshPubKey = (Get-Content $keyPath -Raw).Trim()
        break
    }
}

# ---------------------------------------------------------------------------
# Step 4: Workspace location
# ---------------------------------------------------------------------------
Heading "Step 4: Workspace location"

$defaultWorkspace = "$env:USERPROFILE\claude-workspace"

Write-Host "  Where should your workspace files be stored?"
Write-Host ""
Write-Host "  [1] $defaultWorkspace  (recommended)"
Write-Host "      Files saved here are visible in File Explorer and easy to back up."
Write-Host ""
Write-Host "  [2] Docker volume  (managed by Docker, not directly visible)"
Write-Host "      Use this if you only access files via VS Code Remote SSH."
Write-Host ""
Write-Host "  [3] Custom path"
Write-Host "      Enter any directory on this machine."
Write-Host ""

$workspaceType = ""
while ($true) {
    $workspaceType = Read-Host "  Choose [1/2/3] (default: 1)"
    if (-not $workspaceType) { $workspaceType = "1" }
    if ($workspaceType -in @("1","2","3")) { break }
    Warn "Please enter 1, 2, or 3."
}

$workspaceVolumeLine = ""    # the volumes: entry in compose
$workspaceVolumesBlock = ""  # top-level volumes: block (named volume only)
$workspaceDisplay = ""       # shown to user in summary

switch ($workspaceType) {
    "1" {
        $workspacePath = $defaultWorkspace
        New-Item -ItemType Directory -Force -Path $workspacePath | Out-Null
        # Docker on Windows needs forward slashes or the Windows path with drive letter
        $workspaceVolumeLine = "      - ${workspacePath}:/workspace"
        $workspaceDisplay = $workspacePath
        Ok "Workspace: $workspacePath"
    }
    "2" {
        $workspaceVolumeLine = "      - workspace:/workspace"
        $workspaceVolumesBlock = "`nvolumes:`n  workspace:"
        $workspaceDisplay = "Docker volume (run 'docker volume inspect workspace' to locate)"
        Ok "Workspace: Docker named volume"
    }
    "3" {
        while ($true) {
            $workspacePath = Read-Host "  Enter full path (e.g. C:\Users\you\projects)"
            if (-not $workspacePath) {
                Warn "Path cannot be empty."
            } elseif (Test-Path $workspacePath) {
                break
            } else {
                $createIt = Read-Host "  Directory does not exist. Create it? [Y/n]"
                if ($createIt -notmatch "^[Nn]") {
                    New-Item -ItemType Directory -Force -Path $workspacePath | Out-Null
                    break
                }
            }
        }
        $workspaceVolumeLine = "      - ${workspacePath}:/workspace"
        $workspaceDisplay = $workspacePath
        Ok "Workspace: $workspacePath"
    }
}

# ---------------------------------------------------------------------------
# Step 5: Write docker-compose.yml and .env, start container
# ---------------------------------------------------------------------------
Heading "Step 5: Starting container"

New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

# Write a tailored docker-compose.yml based on workspace choice
$composeContent = @"
services:
  claude-code:
    image: johannesfoulds/claude-code-free:latest
    container_name: $CONTAINER_NAME
    ports:
      - "${SSH_PORT}:22"
    volumes:
$workspaceVolumeLine
    environment:
      - ANTHROPIC_BASE_URL=https://openrouter.ai/api
      - ANTHROPIC_AUTH_TOKEN=`${OPENROUTER_API_KEY}
      - ANTHROPIC_API_KEY=
      - ANTHROPIC_MODEL=`${OPENROUTER_MODEL:-stepfun/step-3.5-flash:free}
      - SSH_AUTHORIZED_KEY=`${SSH_AUTHORIZED_KEY:-}
    restart: unless-stopped
$workspaceVolumesBlock
"@

Set-Content -Path "$INSTALL_DIR\docker-compose.yml" -Value $composeContent

$envContent = "OPENROUTER_API_KEY=$apiKey`nOPENROUTER_MODEL=$model`nSSH_AUTHORIZED_KEY=$sshPubKey"
Set-Content -Path "$INSTALL_DIR\.env" -Value $envContent

# Stop existing container if running
$existing = docker ps -aq --filter "name=^${CONTAINER_NAME}$" 2>$null
if ($existing) {
    Info "Removing existing container..."
    docker compose -f "$INSTALL_DIR\docker-compose.yml" down 2>$null
}

Info "Pulling and starting Claude Code container..."
Info "(First run downloads ~140 MB — takes about 1-2 minutes)"
Write-Host ""
docker compose --env-file "$INSTALL_DIR\.env" -f "$INSTALL_DIR\docker-compose.yml" up -d --pull always
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
Write-Host "  ── Workspace ───────────────────────────────────────────────────"
Write-Host "  Your files are stored at:"
Write-Host "    $workspaceDisplay"
Write-Host "  Inside the container this is /workspace."
Write-Host ""
Write-Host "  ── SSH access ──────────────────────────────────────────────────"
Write-Host "  Direct SSH:"
Write-Host "    ssh -p $SSH_PORT coder@localhost"
if (-not $sshPubKey) {
    Write-Host "    Password: coder"
}
Write-Host ""
Write-Host "  ── VS Code Remote SSH ──────────────────────────────────────────"
Write-Host "  1. Install the 'Remote - SSH' extension (if not already installed)"
Write-Host "  2. Press Ctrl+Shift+P"
Write-Host "  3. Type:   Remote-SSH: Connect to Host"
Write-Host "  4. Select: $SSH_CONFIG_HOST"
if (-not $sshPubKey) {
    Write-Host "  5. Password: coder"
}
Write-Host ""
Write-Host "  ── Once inside the container ───────────────────────────────────"
Write-Host "    cd /workspace"
Write-Host "    claude"
Write-Host ""
Write-Host "  ── Daily commands ──────────────────────────────────────────────"
Write-Host "  Stop:    docker compose -f $INSTALL_DIR\docker-compose.yml down"
Write-Host "  Start:   docker compose -f $INSTALL_DIR\docker-compose.yml up -d"
Write-Host ""

$tryNow = Read-Host "  Try Claude Code right now? [Y/n]"
if ($tryNow -notmatch "^[Nn]") {
    Write-Host ""
    Info "Waiting for SSH to be ready..."
    $sshReady = $false
    for ($i = 0; $i -lt 20; $i++) {
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            $tcp.Connect("localhost", $SSH_PORT)
            $sshReady = $true
            $tcp.Close()
            break
        } catch {}
        Start-Sleep -Seconds 3
    }
    if (-not $sshReady) {
        Warn "SSH not ready after 60s. Connect manually with:"
        Write-Host "  ssh -p $SSH_PORT coder@localhost"
    } else {
        Write-Host "  Connecting... (type 'exit' to leave the container)"
        Write-Host ""
        ssh -t -o StrictHostKeyChecking=no -p $SSH_PORT coder@localhost "bash -l -c 'cd /workspace && exec claude'"
    }
}
