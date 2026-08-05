<#
.SYNOPSIS
  Convert Mermaid diagrams in markdown to SVG files
  
.PARAMETER Content
  Markdown content with mermaid blocks
  
.PARAMETER BaseName
  Base name for output SVG files
  
.PARAMETER OutputPath
  Directory for SVG output
  
.EXAMPLE
  $result = .\Convert-MermaidToSvg.ps1 -Content $md -BaseName "doc" -OutputPath "."
#>
param(
    [Parameter(Mandatory)]
    [string]$Content,
    
    [Parameter(Mandatory)]
    [string]$BaseName,
    
    [Parameter(Mandatory)]
    [string]$OutputPath
)

$pattern = '(?s)```mermaid\s+(.*?)```'
$matches = [regex]::Matches($Content, $pattern)

if ($matches.Count -eq 0) {
    return @{ Content = $Content; SvgFiles = @() }
}

$svgFiles = @()
$diagramCounter = 1
$updatedContent = $Content

foreach ($match in $matches) {
    $mermaidCode = $match.Groups[1].Value
    $tempMmd = Join-Path $OutputPath "temp-$BaseName-$diagramCounter.mmd"
    $outputSvg = "$BaseName-diagram-$diagramCounter.svg"
    $outputSvgPath = Join-Path $OutputPath $outputSvg
    
    try {
        # Save and convert
        $mermaidCode | Out-File -FilePath $tempMmd -Encoding UTF8
        & mmdc -i $tempMmd -o $outputSvgPath -t dark -b transparent -s 2 --quiet
        
        if ($LASTEXITCODE -eq 0) {
            $svgFiles += @{ FileName = $outputSvg; Path = $outputSvgPath }
            $replacement = "![Diagram $diagramCounter](/.attachments/$outputSvg)"
            $updatedContent = $updatedContent -replace [regex]::Escape($match.Value), $replacement
        }
    }
    finally {
        if (Test-Path $tempMmd) { Remove-Item $tempMmd -Force }
    }
    
    $diagramCounter++
}

@{ Content = $updatedContent; SvgFiles = $svgFiles }
