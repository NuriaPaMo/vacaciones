<#
.SYNOPSIS
  Upload SVG files to Azure DevOps wiki attachments folder
  
.PARAMETER SvgFiles
  Array of SVG file paths to upload
  
.PARAMETER WikiRepo
  Wiki repository name (default: Registro-Horario.wiki)
  
.EXAMPLE
  .\Upload-WikiAttachments.ps1 -SvgFiles @("diagram1.svg", "diagram2.svg")
#>
param(
    [Parameter(Mandatory)]
    [string[]]$SvgFiles,
    
    [string]$WikiRepo = "Registro-Horario.wiki"
)

# Clone wiki if not exists
if (-not (Test-Path $WikiRepo)) {
    git clone "https://dev.azure.com/jdmveira/Registro%20Horario/_git/$WikiRepo"
}

# Create attachments folder
$attachmentsPath = Join-Path $WikiRepo ".attachments"
New-Item -ItemType Directory -Force -Path $attachmentsPath | Out-Null

# Copy SVG files
foreach ($svg in $SvgFiles) {
    Copy-Item $svg $attachmentsPath -Force
    Write-Host "✓ Uploaded: $(Split-Path $svg -Leaf)" -ForegroundColor Green
}

# Commit and push
Push-Location $WikiRepo
try {
    git add .attachments/
    git commit -m "docs: Add diagram attachments"
    git push origin wikiMaster
    Write-Host "✓ Changes pushed to wiki" -ForegroundColor Green
}
finally {
    Pop-Location
}
