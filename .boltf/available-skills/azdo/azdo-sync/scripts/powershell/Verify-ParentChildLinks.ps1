<#
.SYNOPSIS
    Verificación rápida del estado de relaciones Parent-Child

.DESCRIPTION
    Verifica cuántas tasks tienen parent links configurados
#>

# Load shared environment (reads .env, builds $script:Config, validates PAT)
. "$PSScriptRoot\_EnvLoader.ps1"

Write-Host "Verificando estado de relaciones Parent-Child...`n" -ForegroundColor Cyan

# Contar tasks con parent
$tasksWithParent = 0
$tasksWithoutParent = 0

31534..31604 | ForEach-Object {
    $wi = az boards work-item show --id $_ --output json 2>&1 | ConvertFrom-Json
    $hasParent = $wi.relations -and ($wi.relations | Where-Object { $_.rel -eq 'System.LinkTypes.Hierarchy-Reverse' })
    
    if ($hasParent) {
        $tasksWithParent++
    } else {
        $tasksWithoutParent++
        Write-Host "Task #$_ sin parent" -ForegroundColor Yellow
    }
}

Write-Host "`n📊 Resumen:" -ForegroundColor Cyan
Write-Host "  ✅ Tasks con parent: $tasksWithParent/71" -ForegroundColor Green
Write-Host "  ❌ Tasks sin parent: $tasksWithoutParent/71" -ForegroundColor $(if ($tasksWithoutParent -eq 0) { "Green" } else { "Yellow" })
