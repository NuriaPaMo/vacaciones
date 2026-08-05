<#
.SYNOPSIS
    Get Next ADR Number - PowerShell Script

.DESCRIPTION
    Finds the next available ADR number by scanning existing ADR files.

.PARAMETER AdrDirectory
    Path to ADR directory (default: docs/adr)

.OUTPUTS
    String - Next ADR number in format NNNN (4 digits with leading zeros)

.EXAMPLE
    .\Get-NextAdrNumber.ps1

.EXAMPLE
    .\Get-NextAdrNumber.ps1 -AdrDirectory "docs/architecture/decisions"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$AdrDirectory = "docs/adr"
)

# Find existing ADR files
$ExistingADRs = Get-ChildItem -Path $AdrDirectory -Filter "ADR-*.md" -ErrorAction SilentlyContinue

# Find the highest number
$LastNum = 0
foreach ($adr in $ExistingADRs) {
    if ($adr.Name -match "ADR-(\d+)") {
        $num = [int]$Matches[1]
        if ($num -gt $LastNum) {
            $LastNum = $num
        }
    }
}

# Calculate next number
$NextNum = $LastNum + 1

# Format with leading zeros (4 digits)
$FormattedNum = "{0:D4}" -f $NextNum

# Output the number
Write-Output $FormattedNum
