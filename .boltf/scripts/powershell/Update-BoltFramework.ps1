# Bolt Framework — consumer repo updater
# Syncs .github/agents/, .claude/agents/, and .claude/skills/ from the Bolt Framework
# source repo into a consumer repo, with classification, conflict resolution, AI merge
# assistance, backup, and sync-state tracking.
#
# Companion to Sync-McpConfig.ps1 — same code style.
#
# See: .boltf/bolt-manifest.yaml for framework versioning.

[CmdletBinding()]
param(
    # Path to bolt-framework source repo.
    # Auto-detected from bolt-upstream git remote (local paths only) if omitted.
    [string]$SourceDir,
    # Consumer repo root to update. Defaults to current directory.
    [string]$DestDir = (Get-Location).Path,
    # AI client for merge decisions: claude, copilot, auto (detect).
    [ValidateSet('claude', 'copilot', 'auto')]
    [string]$AiClient = 'auto',
    # Preview what would change without modifying anything.
    [switch]$DryRun,
    # Skip interactive menus; accept framework version for all conflicts (CI-friendly).
    [switch]$Force,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: Update-BoltFramework.ps1 [-SourceDir <path>] [-DestDir <path>] [-AiClient claude|copilot|auto] [-DryRun] [-Force]"
    Write-Host ""
    Write-Host "  Syncs .github/agents/, .claude/agents/, and .claude/skills/ from the"
    Write-Host "  Bolt Framework source repo into a consumer repo."
    Write-Host ""
    Write-Host "  -SourceDir   Path to bolt-framework source repo."
    Write-Host "               Auto-detected from 'bolt-upstream' git remote if omitted."
    Write-Host "  -DestDir     Consumer repo root to update. Defaults to current directory."
    Write-Host "  -AiClient    AI client for merge decisions: claude, copilot, auto."
    Write-Host "  -DryRun      Preview what would change without modifying anything."
    Write-Host "  -Force       Skip interactive menus; accept framework version for all conflicts."
    exit 0
}

$ErrorActionPreference = "Stop"

function Write-Info { param([string]$m) Write-Host "ℹ️  $m" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "⚠️  $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "❌ $m" -ForegroundColor Red }

# ── Normalize path separators to forward slashes (for cross-platform key consistency) ──
function Normalize-Path { param([string]$p) $p -replace '\\', '/' }

# ── Compute SHA-256 hash (lowercase hex, no prefix) ──────────────────────────────
function Get-Sha256 {
    param([string]$FilePath)
    (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
}

# ── Read framework version from bolt-manifest.yaml ───────────────────────────────
function Get-FrameworkVersion {
    param([string]$ManifestPath)
    if (-not (Test-Path $ManifestPath)) { return "unknown" }
    foreach ($line in Get-Content $ManifestPath) {
        if ($line -match '^\s*version:\s*(.+)\s*$') {
            return $Matches[1].Trim()
        }
    }
    return "unknown"
}

# ── Load sync-state JSON, return ordered hashtable ───────────────────────────────
function Load-SyncState {
    param([string]$StatePath)
    $state = [ordered]@{
        framework_version = "unknown"
        synced_at         = ""
        source            = ""
        files             = [ordered]@{}
    }
    if (-not (Test-Path $StatePath)) { return $state }
    try {
        $json = Get-Content $StatePath -Raw | ConvertFrom-Json
        if ($json.framework_version) { $state.framework_version = $json.framework_version }
        if ($json.synced_at)         { $state.synced_at         = $json.synced_at }
        if ($json.source)            { $state.source            = $json.source }
        if ($json.files) {
            foreach ($p in $json.files.PSObject.Properties) {
                $state.files[(Normalize-Path $p.Name)] = $p.Value.ToLower()
            }
        }
    } catch {
        Write-Warn "Could not parse sync-state file — treating as first run."
    }
    return $state
}

# ── Save sync-state JSON ──────────────────────────────────────────────────────────
function Save-SyncState {
    param([string]$StatePath, [System.Collections.IDictionary]$State)
    $dir = Split-Path $StatePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    # Rebuild files as a plain PSCustomObject for JSON serialization
    $filesObj = [ordered]@{}
    foreach ($k in $State.files.Keys) { $filesObj[$k] = $State.files[$k] }
    $out = [ordered]@{
        framework_version = $State.framework_version
        synced_at         = $State.synced_at
        source            = $State.source
        files             = $filesObj
    }
    # Write UTF-8 WITHOUT BOM so the bash updater's jq can parse it (Windows
    # PowerShell's -Encoding UTF8 emits a BOM that breaks cross-shell interop).
    [System.IO.File]::WriteAllText($StatePath, ($out | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
}

# ── Ensure backup directory exists (created once per run, lazily) ─────────────────
$script:BackupDir = $null
function Get-BackupDir {
    if ($script:BackupDir) { return $script:BackupDir }
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
    $dir = Join-Path $DestDir ".boltf\.update-backup\$timestamp"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $script:BackupDir = $dir
    return $dir
}

# ── Backup a file before overwriting ─────────────────────────────────────────────
function Backup-File {
    param([string]$FilePath)
    if ($DryRun) { return }
    $backupDir = Get-BackupDir
    # Mirror directory structure inside backup
    $rel = Normalize-Path ($FilePath.Substring($DestDir.Length).TrimStart('/\'))
    $dest = Join-Path $backupDir $rel
    $destParent = Split-Path $dest -Parent
    if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
    Copy-Item -Path $FilePath -Destination $dest -Force
}

# ── Copy source file to dest (with optional backup of existing) ───────────────────
function Copy-ToDestination {
    param([string]$SrcFile, [string]$DestFile)
    $destParent = Split-Path $DestFile -Parent
    if (-not $DryRun) {
        if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
        if (Test-Path $DestFile) { Backup-File $DestFile }
        Copy-Item -Path $SrcFile -Destination $DestFile -Force
    }
}

# ── Show unified diff between dest and source ────────────────────────────────────
function Show-Diff {
    param([string]$DestFile, [string]$SrcFile)
    Write-Host ""
    Write-Host "─── diff: $DestFile ───" -ForegroundColor DarkGray
    # git diff --no-index exits 1 when files differ — that is the normal case here, not an error
    & git diff --no-index --unified=3 -- $DestFile $SrcFile 2>&1 | ForEach-Object { Write-Host $_ }
    Write-Host ""
}

# ── Detect available AI client ────────────────────────────────────────────────────
function Get-AiClient {
    param([string]$Preference)
    if ($Preference -eq 'claude') {
        if (Get-Command claude -ErrorAction SilentlyContinue) { return 'claude' }
        Write-Warn "claude CLI not found. Falling back to copilot."
        $Preference = 'copilot'
    }
    if ($Preference -eq 'copilot') {
        if (Get-Command gh -ErrorAction SilentlyContinue) { return 'copilot' }
        Write-Warn "gh CLI not found. AI merge unavailable."
        return $null
    }
    # auto
    if (Get-Command claude -ErrorAction SilentlyContinue) { return 'claude' }
    if (Get-Command gh -ErrorAction SilentlyContinue) { return 'copilot' }
    return $null
}

# ── Run AI merge analysis ─────────────────────────────────────────────────────────
function Invoke-AiMerge {
    param([string]$RelPath, [string]$DestFile, [string]$SrcFile, [string]$FrameworkVersion)

    $client = Get-AiClient $AiClient
    if (-not $client) {
        Write-Warn "No AI client available. Install 'claude' or 'gh' CLI to use this option."
        return
    }

    $localContent  = if (Test-Path $DestFile)  { Get-Content $DestFile  -Raw } else { "(file not found)" }
    $sourceContent = if (Test-Path $SrcFile)   { Get-Content $SrcFile   -Raw } else { "(file not found)" }

    # Build unified diff text inline (suppress exit code)
    $diffText = (& git diff --no-index --unified=3 -- $DestFile $SrcFile 2>&1) -join "`n"

    $prompt = @"
You are reviewing a Bolt Framework file update conflict.

File: $RelPath
Framework version: $FrameworkVersion

--- LOCAL VERSION (consumer repo) ---
$localContent

--- FRAMEWORK VERSION (source) ---
$sourceContent

--- UNIFIED DIFF (dest vs source) ---
$diffText

Please analyze:
1. What has changed in the framework version?
2. What customizations exist in the local version?
3. Are there conflicts that would break local functionality if replaced?
4. Recommendation: REPLACE (accept framework), SKIP (keep local), or MANUAL (needs hand-editing)?

Provide a concise analysis with a clear recommendation.
"@

    Write-Info "Running AI analysis with $client..."
    Write-Host ""

    if ($client -eq 'claude') {
        # Pipe via stdin — avoids Windows CreateProcess 32K argument-length limit
        $aiOutput = ($prompt | & claude -p) 2>&1
    } else {
        # gh copilot explain is designed for shell commands and may not handle large content well.
        # If it hangs or errors, press Ctrl+C and use VS Code Copilot Chat manually
        # with the diff shown above (option [D] opens VS Code diff view).
        Write-Warn "GitHub Copilot CLI has limited support for file analysis."
        Write-Info "If it hangs, press Ctrl+C and use VS Code Copilot Chat with the diff [D] option."
        $aiOutput = ($prompt | & gh copilot explain) 2>&1
    }

    Write-Host "─── AI Analysis ───────────────────────────────────────" -ForegroundColor DarkCyan
    $aiOutput | ForEach-Object { Write-Host $_ }
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host ""
}

# ── Interactive menu for MODIFIED files ──────────────────────────────────────────
# Returns: 'skip', 'replace', or 'quit'
function Show-ConflictMenu {
    param([string]$RelPath, [string]$DestFile, [string]$SrcFile, [string]$FrameworkVersion)

    Show-Diff $DestFile $SrcFile

    while ($true) {
        Write-Host "  File: $RelPath" -ForegroundColor Yellow
        Write-Host "  [S] Skip   — conservar versión local"
        Write-Host "  [R] Replace — aceptar versión del framework"
        Write-Host "  [A] AI     — analizar con AI antes de decidir"
        Write-Host "  [D] Diff   — abrir en VS Code (code --diff)"
        Write-Host "  [Q] Quit   — detener el proceso"
        Write-Host ""
        $choice = (Read-Host "  Choice").Trim().ToUpper()

        switch ($choice) {
            'S' { return 'skip' }
            'R' { return 'replace' }
            'Q' { return 'quit' }
            'D' {
                if (Get-Command code -ErrorAction SilentlyContinue) {
                    & code --diff $DestFile $SrcFile
                } else {
                    Write-Warn "'code' not found in PATH. Cannot open VS Code diff."
                }
                # Stay in loop after opening diff
            }
            'A' {
                Invoke-AiMerge -RelPath $RelPath -DestFile $DestFile -SrcFile $SrcFile -FrameworkVersion $FrameworkVersion
                # After AI output, simplified menu
                while ($true) {
                    Write-Host "  [S] Skip — conservar versión local"
                    Write-Host "  [R] Replace — aceptar versión del framework"
                    $choice2 = (Read-Host "  Choice").Trim().ToUpper()
                    if ($choice2 -eq 'S') { return 'skip' }
                    if ($choice2 -eq 'R') { return 'replace' }
                    Write-Warn "Please enter S or R."
                }
            }
            default { Write-Warn "Invalid choice. Enter S, R, A, D, or Q." }
        }
    }
}

# ── Auto-detect SourceDir from git remote ────────────────────────────────────────
function Resolve-SourceDir {
    param([string]$FromDir)
    try {
        $remoteUrl = & git -C $FromDir remote get-url bolt-upstream 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteUrl)) {
            return $null
        }
        $remoteUrl = $remoteUrl.Trim()
        # Only accept local paths (no :// and no github.com)
        if ($remoteUrl -match '://' -or $remoteUrl -match 'github\.com') {
            return $null
        }
        return $remoteUrl
    } catch {
        return $null
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "  Bolt Framework Updater" -ForegroundColor Cyan
if ($DryRun) { Write-Host "  [DRY RUN — no changes will be made]" -ForegroundColor Yellow }
Write-Host "═══════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

# ── Resolve DestDir ───────────────────────────────────────────────────────────────
$DestDir = (Resolve-Path $DestDir).Path

# ── Resolve SourceDir ────────────────────────────────────────────────────────────
if (-not $SourceDir) {
    Write-Info "Auto-detecting source from bolt-upstream git remote..."
    $SourceDir = Resolve-SourceDir $DestDir
    if (-not $SourceDir) {
        Write-Err "Could not auto-detect source directory."
        Write-Host "  Either add a git remote named 'bolt-upstream' pointing to a local path:"
        Write-Host "    git remote add bolt-upstream C:\path\to\bolt-framework"
        Write-Host "  Or pass -SourceDir explicitly:"
        Write-Host "    Update-BoltFramework.ps1 -SourceDir C:\path\to\bolt-framework"
        exit 1
    }
    Write-Ok "Source detected: $SourceDir"
}

if (-not (Test-Path $SourceDir)) {
    Write-Err "Source directory not found: $SourceDir"
    exit 1
}

$SourceDir = (Resolve-Path $SourceDir).Path

# ── Read framework version ────────────────────────────────────────────────────────
$manifestPath   = Join-Path $SourceDir ".boltf\bolt-manifest.yaml"
$frameworkVersion = Get-FrameworkVersion $manifestPath
Write-Info "Framework version: $frameworkVersion"

# ── Load sync-state ───────────────────────────────────────────────────────────────
$statePath = Join-Path $DestDir ".boltf\bolt-sync-state.json"
$syncState = Load-SyncState $statePath
$isFirstRun = (-not (Test-Path $statePath))
if ($isFirstRun) { Write-Warn "No sync-state found — treating as first run (UNKNOWN classification)." }

# ── Counters ──────────────────────────────────────────────────────────────────────
$cNew       = 0
$cPristine  = 0
$cModRepl   = 0
$cModSkip   = 0
$cSupport   = 0
$cOrphan    = 0

# ── New sync-state files map (built during this run) ─────────────────────────────
$newStateFiles = [ordered]@{}
# Carry forward all existing state entries; we'll overwrite selectively below
foreach ($k in $syncState.files.Keys) { $newStateFiles[$k] = $syncState.files[$k] }

# ── Collect primary source files ──────────────────────────────────────────────────
# Primary file patterns (relative to SourceDir):
#   .github/agents/*.agent.md
#   .claude/agents/*.md
#   .claude/skills/*/SKILL.md

$primaryPatterns = @(
    @{ Glob = ".github\agents\*.agent.md";    Base = "" }
    @{ Glob = ".claude\agents\*.md";          Base = "" }
    @{ Glob = ".claude\skills\*\SKILL.md";    Base = "" }
)

$primarySourceFiles = [System.Collections.Generic.List[string]]::new()

foreach ($pat in $primaryPatterns) {
    $searchPath = Join-Path $SourceDir $pat.Glob
    $found = @(Get-ChildItem -Path $searchPath -ErrorAction SilentlyContinue)
    foreach ($f in $found) { $primarySourceFiles.Add($f.FullName) }
}

# ── Collect support source files (all other files under .claude/skills/*/) ────────
# Support = any file under .claude/skills/*/ that is NOT a SKILL.md
$supportSourceFiles = [System.Collections.Generic.List[string]]::new()
$skillsSourceRoot = Join-Path $SourceDir ".claude\skills"
if (Test-Path $skillsSourceRoot) {
    $allSkillFiles = @(Get-ChildItem -Path $skillsSourceRoot -Recurse -File -ErrorAction SilentlyContinue)
    foreach ($f in $allSkillFiles) {
        $relNorm = Normalize-Path ($f.FullName.Substring($SourceDir.Length).TrimStart('/\'))
        # Exclude SKILL.md files (already in primary)
        if ($relNorm -notmatch '/SKILL\.md$') {
            $supportSourceFiles.Add($f.FullName)
        }
    }
}

Write-Info "Primary files found in source: $($primarySourceFiles.Count)"
Write-Info "Support files found in source:  $($supportSourceFiles.Count)"
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESS PRIMARY FILES
# ═══════════════════════════════════════════════════════════════════════════════

$quit = $false

foreach ($srcFile in $primarySourceFiles) {
    if ($quit) { break }

    $relPath  = Normalize-Path ($srcFile.Substring($SourceDir.Length).TrimStart('/\'))
    $destFile = Join-Path $DestDir ($relPath -replace '/', '\')
    $srcHash  = Get-Sha256 $srcFile

    # ── Classify ────────────────────────────────────────────────────────────────
    if (-not (Test-Path $destFile)) {
        # NEW — file does not exist in destination
        $class = "NEW"
    } else {
        $destHash   = Get-Sha256 $destFile
        $stateHash  = if ($syncState.files.Contains($relPath)) { $syncState.files[$relPath] } else { $null }

        if ($null -ne $stateHash) {
            # Have a state entry: compare dest vs stored
            if ($destHash -eq $stateHash) {
                $class = "PRISTINE"   # dest matches what we last wrote — safe to update
            } else {
                $class = "MODIFIED"   # dest has changed since last sync
            }
        } else {
            # No state entry (first run or new primary file added to framework)
            if ($destHash -eq $srcHash) {
                $class = "PRISTINE"   # dest already matches source
            } else {
                $class = "MODIFIED"   # dest differs from source, no baseline
            }
        }
    }

    # ── Act on classification ────────────────────────────────────────────────────
    switch ($class) {
        "NEW" {
            Write-Ok "NEW      $relPath"
            if (-not $DryRun) {
                Copy-ToDestination $srcFile $destFile
            }
            $newStateFiles[$relPath] = $srcHash
            $cNew++
        }
        "PRISTINE" {
            Write-Info "PRISTINE $relPath"
            if (-not $DryRun) {
                Copy-ToDestination $srcFile $destFile
            }
            $newStateFiles[$relPath] = $srcHash
            $cPristine++
        }
        "MODIFIED" {
            if ($Force) {
                Write-Warn "MODIFIED $relPath (force-replacing)"
                if (-not $DryRun) {
                    Copy-ToDestination $srcFile $destFile
                }
                $newStateFiles[$relPath] = $srcHash
                $cModRepl++
            } elseif ($DryRun) {
                Write-Warn "MODIFIED $relPath [would show conflict menu]"
                $cModSkip++  # In dry-run, count as "would need decision"
            } else {
                Write-Warn "MODIFIED $relPath"
                $decision = Show-ConflictMenu -RelPath $relPath -DestFile $destFile -SrcFile $srcFile -FrameworkVersion $frameworkVersion

                switch ($decision) {
                    'replace' {
                        Copy-ToDestination $srcFile $destFile
                        $newStateFiles[$relPath] = $srcHash
                        $cModRepl++
                        Write-Ok "Replaced: $relPath"
                    }
                    'skip' {
                        # Do NOT update state entry — preserves MODIFIED classification on next run
                        $cModSkip++
                        Write-Info "Skipped:  $relPath"
                    }
                    'quit' {
                        # Exit immediately (matches the bash updater): do NOT continue to
                        # support files / orphan checks / sync-state write after a quit.
                        Write-Warn "Process stopped by user. No sync-state written."
                        exit 0
                    }
                }
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESS SUPPORT FILES (copy-if-missing only, never overwrite)
# ═══════════════════════════════════════════════════════════════════════════════

foreach ($srcFile in $supportSourceFiles) {
    $relPath  = Normalize-Path ($srcFile.Substring($SourceDir.Length).TrimStart('/\'))
    $destFile = Join-Path $DestDir ($relPath -replace '/', '\')

    if (-not (Test-Path $destFile)) {
        Write-Info "SUPPORT  $relPath (copy-if-missing)"
        if (-not $DryRun) {
            $destParent = Split-Path $destFile -Parent
            if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
            Copy-Item -Path $srcFile -Destination $destFile -Force
        }
        $cSupport++
    }
    # If it already exists: silently skip — support files are never overwritten
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORPHAN CHECK — primary files in dest that no longer exist in source
# ═══════════════════════════════════════════════════════════════════════════════

$primaryDestGlobs = @(
    ".github\agents\*.agent.md"
    ".claude\agents\*.md"
    ".claude\skills\*\SKILL.md"
)

foreach ($glob in $primaryDestGlobs) {
    $searchPath = Join-Path $DestDir $glob
    $destFound = @(Get-ChildItem -Path $searchPath -ErrorAction SilentlyContinue)
    foreach ($df in $destFound) {
        $relPath = Normalize-Path ($df.FullName.Substring($DestDir.Length).TrimStart('/\'))
        # Check if this file exists in source
        $correspondingSrc = Join-Path $SourceDir ($relPath -replace '/', '\')
        if (-not (Test-Path $correspondingSrc)) {
            Write-Warn "ORPHAN   $relPath (exists locally, not in framework source)"
            $cOrphan++
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UPDATE SYNC-STATE
# ═══════════════════════════════════════════════════════════════════════════════

if (-not $DryRun) {
    $newState = [ordered]@{
        framework_version = $frameworkVersion
        synced_at         = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        source            = $SourceDir
        files             = $newStateFiles
    }
    Save-SyncState $statePath $newState
    Write-Ok "Sync-state updated: $statePath"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "  Bolt Framework Update Complete" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ("  NEW (auto-copied):        {0,3} files" -f $cNew)     -ForegroundColor Green
Write-Host ("  PRISTINE (auto-updated):  {0,3} files" -f $cPristine) -ForegroundColor Green
Write-Host ("  MODIFIED — replaced:      {0,3} files" -f $cModRepl)  -ForegroundColor Yellow
Write-Host ("  MODIFIED — skipped:       {0,3} files" -f $cModSkip)  -ForegroundColor Yellow
Write-Host ("  SUPPORT (auto-copied):    {0,3} files" -f $cSupport)  -ForegroundColor Cyan
Write-Host ("  ORPHAN (warnings):        {0,3} files" -f $cOrphan)   -ForegroundColor $(if ($cOrphan -gt 0) { "Yellow" } else { "Gray" })
if ($DryRun) {
    Write-Host "  DryRun: no changes made" -ForegroundColor Yellow
}
Write-Host "═══════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""
