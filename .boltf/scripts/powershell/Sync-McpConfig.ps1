# Bolt Framework — MCP config sync (dual-client)
# Generates BOTH MCP targets from the active scopes' mcp-tools definitions:
#   - .vscode/mcp.json   → GitHub Copilot (VS Code) format: { servers, inputs }
#   - .mcp.json          → Claude Code format: { mcpServers }
#
# This closes a pre-existing framework gap: scope mcp-tools only fed Copilot
# (.vscode/) and nothing generated Claude's .mcp.json. It is NOT Penpot-specific,
# but is what makes the Penpot MCP (and every scope MCP) reach BOTH clients.
#
# Idempotent: merges server entries into existing files instead of clobbering.
#
# See: docs/integrations/penpot-integration-plan.md

[CmdletBinding()]
param(
    # Repo/project root. Defaults to the resolved root relative to this script.
    [string]$ProjectRoot,

    # Concrete Penpot MCP URL to bake into Claude's .mcp.json (no input prompts there).
    # e.g. http://localhost:9001/mcp/stream?userToken=<MCP_KEY>
    # If omitted, the Claude entry falls back to the ${PENPOT_MCP_URL} env var.
    [string]$PenpotMcpUrl,

    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: Sync-McpConfig.ps1 [-ProjectRoot <path>] [-PenpotMcpUrl <url>]"
    Write-Host "  Generates .vscode/mcp.json (Copilot) and .mcp.json (Claude) from active scopes."
    exit 0
}

$ErrorActionPreference = "Stop"

if (-not $ProjectRoot) {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
}

function Write-Info { param([string]$m) Write-Host "ℹ️  $m" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "⚠️  $m" -ForegroundColor Yellow }

# ── Resolve active scopes ────────────────────────────────────────────────────
$scopesYaml = Join-Path $ProjectRoot ".boltf\scopes.yaml"
$activeScopes = @()
if (Test-Path $scopesYaml) {
    $inActive = $false
    foreach ($line in Get-Content $scopesYaml) {
        if ($line -match '^active-scopes:\s*$') { $inActive = $true; continue }
        if ($inActive) {
            if ($line -match '^\s*-\s*(\S+)\s*$') { $activeScopes += $Matches[1] }
            elseif ($line -match '^\S') { $inActive = $false }   # left the block
        }
    }
    # work-management is transversal (always active)
    if ($activeScopes -notcontains "work-management") { $activeScopes += "work-management" }
} else {
    Write-Warn "scopes.yaml not found — scanning all scope folders with mcp-tools."
    $activeScopes = Get-ChildItem (Join-Path $ProjectRoot ".boltf\scopes") -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "mcp-tools\default.mcp.servers.json") } |
        ForEach-Object { $_.Name }
}

Write-Info "Active scopes: $($activeScopes -join ', ')"

# ── Aggregate servers + inputs across scopes ──────────────────────────────────
$servers = [ordered]@{}
$inputsById = [ordered]@{}

foreach ($scope in $activeScopes) {
    $serversFile = Join-Path $ProjectRoot ".boltf\scopes\$scope\mcp-tools\default.mcp.servers.json"
    if (-not (Test-Path $serversFile)) { continue }
    $json = Get-Content $serversFile -Raw | ConvertFrom-Json
    if ($json.servers) {
        foreach ($p in $json.servers.PSObject.Properties) { $servers[$p.Name] = $p.Value }
    }
    if ($json.inputs) {
        foreach ($inp in $json.inputs) { $inputsById[$inp.id] = $inp }
    }
}

if ($servers.Count -eq 0) { Write-Warn "No MCP servers found across active scopes. Nothing to sync."; exit 0 }

# ── Helper: deep-clone a PSCustomObject via JSON round-trip ────────────────────
function Copy-Json { param($o) if ($null -eq $o) { return $null } ($o | ConvertTo-Json -Depth 20) | ConvertFrom-Json }

# ── Helper: translate ${input:foo-bar} → ${FOO_BAR} (env var form for Claude) ──
function Convert-InputTokens {
    param([string]$Text)
    [regex]::Replace($Text, '\$\{input:([a-zA-Z0-9_-]+)\}', {
        param($m) '${' + ($m.Groups[1].Value -replace '-', '_').ToUpper() + '}'
    })
}

# ── Merge helper: load existing target JSON or start fresh ─────────────────────
function Get-ExistingJson { param([string]$Path) if (Test-Path $Path) { return (Get-Content $Path -Raw | ConvertFrom-Json) } return $null }

# ── 1) Copilot target: .vscode/mcp.json (verbatim servers + inputs) ────────────
$vscodeDir = Join-Path $ProjectRoot ".vscode"
if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null }
$vscodePath = Join-Path $vscodeDir "mcp.json"

$existingVscode = Get-ExistingJson $vscodePath
$vscodeServers = [ordered]@{}
if ($existingVscode -and $existingVscode.servers) {
    foreach ($p in $existingVscode.servers.PSObject.Properties) { $vscodeServers[$p.Name] = $p.Value }
}
foreach ($k in $servers.Keys) { $vscodeServers[$k] = $servers[$k] }   # scope servers win

$vscodeInputs = @()
$seenInputs = @{}
if ($existingVscode -and $existingVscode.inputs) {
    foreach ($i in $existingVscode.inputs) { if (-not $seenInputs.ContainsKey($i.id)) { $vscodeInputs += $i; $seenInputs[$i.id] = $true } }
}
foreach ($id in $inputsById.Keys) { if (-not $seenInputs.ContainsKey($id)) { $vscodeInputs += $inputsById[$id]; $seenInputs[$id] = $true } }

$vscodeOut = [ordered]@{ servers = $vscodeServers }
if ($vscodeInputs.Count -gt 0) { $vscodeOut.inputs = $vscodeInputs }
$vscodeOut | ConvertTo-Json -Depth 20 | Set-Content -Path $vscodePath -Encoding UTF8
Write-Ok "Wrote $vscodePath (Copilot) — $($vscodeServers.Count) servers"

# ── 2) Claude target: .mcp.json (mcpServers, env-var token translation) ────────
$mcpPath = Join-Path $ProjectRoot ".mcp.json"
$existingMcp = Get-ExistingJson $mcpPath
$mcpServers = [ordered]@{}
if ($existingMcp -and $existingMcp.mcpServers) {
    foreach ($p in $existingMcp.mcpServers.PSObject.Properties) { $mcpServers[$p.Name] = $p.Value }
}

foreach ($name in $servers.Keys) {
    $entry = Copy-Json $servers[$name]
    # Translate VS Code ${input:...} placeholders → ${ENV_VAR} that Claude expands.
    $serialized = Convert-InputTokens ($entry | ConvertTo-Json -Depth 20)
    $entry = $serialized | ConvertFrom-Json
    # Bake the concrete Penpot URL if provided. WARNING: this writes the literal token
    # into .mcp.json, which is tracked by git — use only for untracked local setups.
    if ($name -eq "penpot" -and $PenpotMcpUrl) {
        $entry.url = $PenpotMcpUrl
        Write-Warn 'Baking a literal Penpot URL into .mcp.json (tracked file). Do NOT commit the token. Prefer the ${PENPOT_MCP_URL} env var instead.'
    }
    $mcpServers[$name] = $entry
}

$mcpOut = [ordered]@{ mcpServers = $mcpServers }
$mcpOut | ConvertTo-Json -Depth 20 | Set-Content -Path $mcpPath -Encoding UTF8
Write-Ok "Wrote $mcpPath (Claude) — $($mcpServers.Count) servers"

if ($mcpServers.Contains("penpot") -and -not $PenpotMcpUrl) {
    Write-Warn ('Claude .mcp.json penpot URL uses ${PENPOT_MCP_URL}. Set that env var, or re-run with -PenpotMcpUrl.')
}
Write-Info "MCP sync complete. Restart Claude Code / VS Code to pick up changes."
