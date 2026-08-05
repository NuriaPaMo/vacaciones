# Bolt Framework — Penpot self-hosted bootstrap (Podman by default)
# Idempotent, opt-in. Not invoked automatically — Init.ps1 only offers to run it at
# the end with explicit user confirmation. Otherwise run manually (or via the
# `bolt-penpot` agent in `setup` mode) when decisions.frontend.design-tool = penpot-local.
#
# Penpot is a MULTI-CONTAINER stack (frontend, backend, exporter, postgres, redis)
# brought up via the official compose file. This is NOT a single `podman run` image.
#
# See: docs/integrations/penpot-integration-plan.md

[CmdletBinding()]
param(
    # Container runtime. Podman is the Bolt default; override to docker only if requested.
    [ValidateSet("podman", "docker")]
    [string]$Runtime = "podman",

    # Host port for the Penpot web UI (official default is 9001).
    [int]$Port = 9001,

    # Lifecycle actions (mutually exclusive with default "up").
    [switch]$Stop,
    [switch]$Down,
    [switch]$Status,

    # Force re-download of the official compose file even if it already exists.
    [switch]$RefreshCompose,

    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: Install-Penpot.ps1 [OPTIONS]"
    Write-Host "Options:"
    Write-Host "  -Runtime <podman|docker>  Container runtime (default: podman)"
    Write-Host "  -Port <int>               Host port for the web UI (default: 9001)"
    Write-Host "  -Stop                     Stop the Penpot stack (keeps data)"
    Write-Host "  -Down                     Stop and remove containers (keeps named volumes)"
    Write-Host "  -Status                   Show stack status"
    Write-Host "  -RefreshCompose           Re-download the official compose file"
    Write-Host "  -Help                     Show this help message"
    exit 0
}

$ErrorActionPreference = "Stop"

# ── Paths ────────────────────────────────────────────────────────────────────
# Script lives at .boltf/scripts/powershell/Install-Penpot.ps1 → repo root is 3 up.
$repoRoot   = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$penpotDir  = Join-Path $repoRoot ".boltf\penpot"
$composeFile = Join-Path $penpotDir "docker-compose.yaml"
$composeUrl = "https://raw.githubusercontent.com/penpot/penpot/main/docker/images/docker-compose.yaml"
$projectName = "penpot"

# ── Helpers ──────────────────────────────────────────────────────────────────
function Write-Info    { param([string]$m) Write-Host "ℹ️  $m" -ForegroundColor Cyan }
function Write-Ok      { param([string]$m) Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn    { param([string]$m) Write-Host "⚠️  $m" -ForegroundColor Yellow }
function Write-Err     { param([string]$m) Write-Host "❌ $m" -ForegroundColor Red }

# Resolve the compose invocation for the chosen runtime.
# Prefers the integrated subcommand (`podman compose` / `docker compose`), falls
# back to the standalone (`podman-compose`).
function Get-ComposeCommand {
    param([string]$Runtime)

    if (-not (Get-Command $Runtime -ErrorAction SilentlyContinue)) {
        Write-Err "$Runtime is not installed or not on PATH."
        if ($Runtime -eq "podman") {
            Write-Host "   Install Podman: https://podman.io/docs/installation" -ForegroundColor DarkGray
        } else {
            Write-Host "   Install Docker: https://docs.docker.com/get-docker/" -ForegroundColor DarkGray
        }
        exit 1
    }

    # Try integrated subcommand: `<runtime> compose version`
    $integrated = $false
    try {
        & $Runtime compose version *> $null
        if ($LASTEXITCODE -eq 0) { $integrated = $true }
    } catch { $integrated = $false }

    if ($integrated) {
        return @{ Exe = $Runtime; Pre = @("compose") }
    }

    # Fall back to standalone podman-compose / docker-compose
    $standalone = "$Runtime-compose"
    if (Get-Command $standalone -ErrorAction SilentlyContinue) {
        return @{ Exe = $standalone; Pre = @() }
    }

    Write-Err "Neither '$Runtime compose' nor '$standalone' is available."
    if ($Runtime -eq "podman") {
        Write-Host "   Install podman-compose: pip install podman-compose" -ForegroundColor DarkGray
    }
    exit 1
}

# ── Compose file management ────────────────────────────────────────────────────
function Get-ComposeFile {
    if (-not (Test-Path $penpotDir)) {
        New-Item -ItemType Directory -Path $penpotDir -Force | Out-Null
    }
    if ((Test-Path $composeFile) -and -not $RefreshCompose) {
        Write-Info "Using existing compose file: $composeFile"
        return
    }
    Write-Info "Downloading official Penpot compose file..."
    try {
        Invoke-WebRequest -Uri $composeUrl -OutFile $composeFile -UseBasicParsing
        Write-Ok "Compose file saved to $composeFile"
    } catch {
        Write-Err "Failed to download compose file from $composeUrl"
        Write-Host "   $($_.Exception.Message)" -ForegroundColor DarkGray
        exit 1
    }
}

# ── Main ───────────────────────────────────────────────────────────────────────
$compose = Get-ComposeCommand -Runtime $Runtime
$composeArgs = @($compose.Pre + @("-p", $projectName, "-f", $composeFile))

if ($Status) {
    if (-not (Test-Path $composeFile)) { Write-Warn "No compose file yet — Penpot has not been installed."; exit 0 }
    & $compose.Exe @composeArgs ps
    exit $LASTEXITCODE
}

if ($Stop) {
    if (-not (Test-Path $composeFile)) { Write-Warn "Nothing to stop — no compose file."; exit 0 }
    Write-Info "Stopping Penpot stack (data preserved)..."
    & $compose.Exe @composeArgs stop
    Write-Ok "Penpot stopped."
    exit $LASTEXITCODE
}

if ($Down) {
    if (-not (Test-Path $composeFile)) { Write-Warn "Nothing to remove — no compose file."; exit 0 }
    Write-Info "Removing Penpot containers (named volumes kept)..."
    & $compose.Exe @composeArgs down
    Write-Ok "Penpot containers removed. Data volumes preserved."
    exit $LASTEXITCODE
}

# Default action: bring the stack up.
Write-Info "Bootstrapping Penpot via $($compose.Exe) (runtime: $Runtime)..."
Get-ComposeFile

& $compose.Exe @composeArgs up -d
if ($LASTEXITCODE -ne 0) {
    Write-Err "Failed to start Penpot stack. Inspect logs: $($compose.Exe) -p $projectName logs"
    exit 1
}

# ── Health check ────────────────────────────────────────────────────────────────
if ($Port -ne 9001) {
    Write-Warn "-Port is not currently supported because the official compose file is not patched by this script. Using 9001."
    $Port = 9001
}
$uiUrl = "http://localhost:$Port"
Write-Info "Waiting for Penpot UI at $uiUrl (up to 120s)..."
$ready = $false
for ($i = 0; $i -lt 24; $i++) {
    Start-Sleep -Seconds 5
    try {
        $resp = Invoke-WebRequest -Uri $uiUrl -UseBasicParsing -TimeoutSec 5
        if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { $ready = $true; break }
    } catch { }
}

if ($ready) {
    Write-Ok "Penpot is up at $uiUrl"
} else {
    Write-Warn "Penpot did not respond within 120s. It may still be initializing."
    Write-Host "   Check status: Install-Penpot.ps1 -Status" -ForegroundColor DarkGray
    Write-Host "   Check logs:   $($compose.Exe) -p $projectName logs" -ForegroundColor DarkGray
}

# ── Next steps ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Next steps ──────────────────────────────────────────────" -ForegroundColor Magenta
Write-Host "  1. Open $uiUrl and create your account (first registration)."
Write-Host "  2. Generate an MCP key: Account → Integrations → MCP Server."
Write-Host "  3. Wire the MCP into both clients (.mcp.json + .vscode/mcp.json)."
Write-Host "     RECOMMENDED — keep the token in your environment, never in git:" -ForegroundColor DarkGray
Write-Host "       `$env:PENPOT_MCP_URL = '$uiUrl/mcp/stream?userToken=<MCP_KEY>'" -ForegroundColor DarkGray
Write-Host "       .boltf/scripts/powershell/Sync-McpConfig.ps1   # writes `${PENPOT_MCP_URL} (no secret in .mcp.json)" -ForegroundColor DarkGray
Write-Host "     (-PenpotMcpUrl bakes the literal token into .mcp.json — only for untracked local use.)" -ForegroundColor DarkGray
Write-Host "  4. Invoke the bolt-penpot agent (read/validate/handoff modes)."
Write-Host ""
Write-Host "  NOTE: Podman rootless networking and the official compose file may need" -ForegroundColor DarkGray
Write-Host "  manual adjustment on first run. Verify the stack with -Status." -ForegroundColor DarkGray
