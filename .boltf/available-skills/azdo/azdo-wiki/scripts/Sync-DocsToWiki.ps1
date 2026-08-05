<#
.SYNOPSIS
  Sync docs/ folder to Azure DevOps wiki with Mermaid conversion
  
.EXAMPLE
  .\Sync-DocsToWiki.ps1 -SourcePath "docs/architecture-overview.md"
  .\Sync-DocsToWiki.ps1 -SourcePath "docs/" -Recursive
#>
param(
    [Parameter(Mandatory)]
    [string]$SourcePath,
    
    [string]$WikiIdentifier = "Registro-Horario.wiki",
    [string]$Project = "Registro Horario",
    [switch]$Recursive,
    [switch]$DryRun
)

# Get markdown files
$mdFiles = if ((Get-Item $SourcePath).PSIsContainer) {
    Get-ChildItem -Path $SourcePath -Filter "*.md" -Recurse:$Recursive
} else {
    @(Get-Item $SourcePath)
}

Write-Host "Found $($mdFiles.Count) file(s)" -ForegroundColor Cyan

foreach ($file in $mdFiles) {
    Write-Host "`nProcessing: $($file.Name)" -ForegroundColor Yellow
    
    # Read content
    $content = Get-Content $file.FullName -Raw
    
    # Convert Mermaid diagrams
    $tempDir = Join-Path $env:TEMP "wiki-sync-$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        # Use conversion script
        $scriptPath = Join-Path $PSScriptRoot "Convert-MermaidToSvg.ps1"
        $result = & $scriptPath -Content $content -BaseName $file.BaseName -OutputPath $tempDir
        
        # Determine wiki path
        $basePath = if ((Get-Item $SourcePath).PSIsContainer) { $SourcePath } else { Split-Path $SourcePath }
        $relativePath = $file.FullName.Replace((Resolve-Path $basePath).Path, "")
        $wikiPath = "/Documentation" + ($relativePath -replace '\\', '/' -replace '\.md$', '')
        
        if (-not $DryRun) {
            # Upload SVGs if any
            if ($result.SvgFiles.Count -gt 0) {
                $uploadScript = Join-Path $PSScriptRoot "Upload-WikiAttachments.ps1"
                & $uploadScript -SvgFiles ($result.SvgFiles | ForEach-Object { $_.Path })
            }
            
            # Update wiki page
            $tempContent = Join-Path $tempDir "content.md"
            $result.Content | Out-File -FilePath $tempContent -Encoding UTF8
            
            az devops wiki page create-or-update `
                --wiki $WikiIdentifier `
                --project $Project `
                --path $wikiPath `
                --file-path $tempContent `
                --encoding utf-8 | Out-Null
            
            Write-Host "✓ Page updated: $wikiPath" -ForegroundColor Green
        } else {
            Write-Host "[DRY RUN] Would update: $wikiPath" -ForegroundColor Magenta
        }
    }
    finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }
}
