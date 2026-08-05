#Requires -Version 7.0
<#
.SYNOPSIS
    Módulo PowerShell para gestión del Bolt Framework — distribución bidireccional
    mediante git subtree.

.DESCRIPTION
    Proporciona comandos semánticos para actualizar el framework desde upstream,
    contribuir cambios de vuelta, y verificar el estado de versiones.

.NOTES
    Repositorio canónico: https://github.com/ava-group-iberiademos/bolt-framework
    Mecanismo: git subtree con --squash
#>

$script:BoltPrefix = '.boltf'
$script:BoltRemoteName = 'bolt-upstream'
$script:BoltRemoteUrl = 'https://github.com/ava-group-iberiademos/bolt-framework.git'
$script:ManifestFile = 'bolt-manifest.yaml'

function Get-BoltManifest {
    [CmdletBinding()]
    param()

    $manifestPath = Join-Path (Get-Location) $script:BoltPrefix $script:ManifestFile
    if (-not (Test-Path $manifestPath)) {
        Write-Error "No se encuentra $manifestPath. ¿Estás en la raíz del proyecto?"
        return $null
    }

    $content = Get-Content $manifestPath -Raw
    $version = if ($content -match 'version:\s*(\d+\.\d+\.\d+)') { $Matches[1] } else { 'unknown' }
    $released = if ($content -match 'released:\s*(\S+)') { $Matches[1] } else { 'unknown' }

    return @{
        Path     = $manifestPath
        Version  = $version
        Released = $released
        Content  = $content
    }
}

function Ensure-BoltRemote {
    [CmdletBinding()]
    param()

    $remotes = git remote
    if ($remotes -notcontains $script:BoltRemoteName) {
        Write-Host "[Bolt] Añadiendo remote '$script:BoltRemoteName' -> $script:BoltRemoteUrl" -ForegroundColor Cyan
        git remote add $script:BoltRemoteName $script:BoltRemoteUrl
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Error al añadir remote '$script:BoltRemoteName'."
            return $false
        }
    }
    git fetch $script:BoltRemoteName --tags 2>$null
    return $true
}

function Get-BoltStatus {
    <#
    .SYNOPSIS
        Compara la versión local del Bolt Framework con la última release en GitHub.

    .EXAMPLE
        Get-BoltStatus
    #>
    [CmdletBinding()]
    param()

    $manifest = Get-BoltManifest
    if (-not $manifest) { return }

    Write-Host "`n[Bolt Framework - Estado]" -ForegroundColor Cyan
    Write-Host "  Versión local:  v$($manifest.Version)" -ForegroundColor White
    Write-Host "  Fecha release:  $($manifest.Released)" -ForegroundColor White

    if (-not (Ensure-BoltRemote)) { return }

    $latestTag = git tag -l 'v*' --sort=-v:refname | Select-Object -First 1
    if ($latestTag) {
        $latestVersion = $latestTag -replace '^v', ''
        if ($latestVersion -eq $manifest.Version) {
            Write-Host "  Estado:         ✓ ACTUALIZADO" -ForegroundColor Green
        }
        else {
            Write-Host "  Última versión: $latestTag" -ForegroundColor Yellow
            Write-Host "  Estado:         ⚠ ACTUALIZACIÓN DISPONIBLE" -ForegroundColor Yellow
            Write-Host "`n  Ejecuta: Update-BoltFramework -Version $latestTag" -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "  Estado:         No se encontraron tags de versión en upstream" -ForegroundColor DarkGray
    }

    Write-Host ""
}

function Update-BoltFramework {
    <#
    .SYNOPSIS
        Actualiza el Bolt Framework a una versión específica desde upstream.

    .PARAMETER Version
        Tag de versión a la que actualizar (ej: v1.1.0). Si no se especifica,
        usa la última versión disponible.

    .EXAMPLE
        Update-BoltFramework -Version v1.1.0
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$Version
    )

    if (-not (Ensure-BoltRemote)) { return }

    if (-not $Version) {
        $Version = git tag -l 'v*' --sort=-v:refname | Select-Object -First 1
        if (-not $Version) {
            Write-Error "No se encontraron tags de versión en upstream."
            return
        }
        Write-Host "[Bolt] Usando última versión disponible: $Version" -ForegroundColor Cyan
    }

    $manifest = Get-BoltManifest
    if ($manifest) {
        Write-Host "[Bolt] Versión actual: v$($manifest.Version)" -ForegroundColor White
    }

    if ($PSCmdlet.ShouldProcess("$script:BoltPrefix", "git subtree pull de $Version")) {
        Write-Host "[Bolt] Actualizando .boltf/ a $Version..." -ForegroundColor Cyan

        git subtree pull --prefix=$script:BoltPrefix $script:BoltRemoteName $Version --squash -m "chore(bolt): update framework to $Version"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[Bolt] ✓ Actualización completada a $Version" -ForegroundColor Green
            Write-Host "[Bolt] Ejecuta 'Invoke-BoltSetupConstitution -Provision' para desplegar nuevos items." -ForegroundColor DarkGray
        }
        else {
            Write-Warning "[Bolt] El pull produjo conflictos. Resuélvelos manualmente y haz commit."
            Write-Host "  Archivos en conflicto:" -ForegroundColor Yellow
            git diff --name-only --diff-filter=U
        }
    }
}

function Compare-BoltVersions {
    <#
    .SYNOPSIS
        Muestra el changelog entre dos versiones del framework.

    .PARAMETER From
        Versión de origen (por defecto: la versión local actual).

    .PARAMETER To
        Versión destino (por defecto: la última disponible).

    .EXAMPLE
        Compare-BoltVersions -From v1.0.0 -To v1.1.0
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$From,

        [Parameter()]
        [string]$To
    )

    if (-not (Ensure-BoltRemote)) { return }

    if (-not $From) {
        $manifest = Get-BoltManifest
        if ($manifest) { $From = "v$($manifest.Version)" }
        else { Write-Error "No se puede determinar la versión actual."; return }
    }

    if (-not $To) {
        $To = git tag -l 'v*' --sort=-v:refname | Select-Object -First 1
        if (-not $To) { Write-Error "No se encontraron tags en upstream."; return }
    }

    Write-Host "`n[Bolt] Cambios entre $From y ${To}:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────" -ForegroundColor DarkGray

    git log --oneline "$From..$To" -- . 2>$null
    if ($LASTEXITCODE -ne 0) {
        git log --oneline "$script:BoltRemoteName/$From..$script:BoltRemoteName/$To" 2>$null
    }

    Write-Host "`n[Bolt] Archivos modificados:" -ForegroundColor Cyan
    git diff --stat "$From..$To" -- . 2>$null
    if ($LASTEXITCODE -ne 0) {
        git diff --stat "$script:BoltRemoteName/$From..$script:BoltRemoteName/$To" 2>$null
    }

    Write-Host ""
}

function New-BoltContribution {
    <#
    .SYNOPSIS
        Prepara una contribución local para enviar como PR al repositorio canónico.

    .DESCRIPTION
        Copia los cambios realizados en un skill/agent/script desplegado de vuelta
        a .boltf/available-skills/ y crea un branch de contribución.

    .PARAMETER Type
        Tipo de contribución: skill, agent, scope, script, docs.

    .PARAMETER Name
        Nombre del artefacto modificado (ej: "browser-testing").

    .PARAMETER Description
        Descripción breve del cambio para el mensaje de commit.

    .EXAMPLE
        New-BoltContribution -Type skill -Name "browser-testing" -Description "Añadir patrón de health check"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('skill', 'agent', 'scope', 'script', 'docs')]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$Description = "Mejora de $Type/$Name"
    )

    $branchName = "contrib/$Type-$Name"

    Write-Host "[Bolt] Preparando contribución: $Type/$Name" -ForegroundColor Cyan
    Write-Host "[Bolt] Branch: $branchName" -ForegroundColor White

    # Crear branch de contribución
    git checkout -b $branchName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error al crear branch '$branchName'. ¿Ya existe?"
        return
    }

    switch ($Type) {
        'skill' {
            $sourcePath = Join-Path '.claude' 'skills' $Name 'SKILL.md'
            if (-not (Test-Path $sourcePath)) {
                Write-Warning "No se encontró '$sourcePath'. Verifica el nombre del skill."
                git checkout -
                git branch -D $branchName
                return
            }

            # Buscar destino en available-skills
            $destCandidates = Get-ChildItem -Path (Join-Path $script:BoltPrefix 'available-skills') -Recurse -Directory -Filter $Name
            if ($destCandidates.Count -eq 0) {
                Write-Host "[Bolt] Skill '$Name' no existe en available-skills/. Creando en available-skills/contributed/" -ForegroundColor Yellow
                $destDir = Join-Path $script:BoltPrefix 'available-skills' 'contributed' $Name
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            else {
                $destDir = $destCandidates[0].FullName
            }

            # Copiar el skill actualizado
            Copy-Item -Path (Join-Path '.claude' 'skills' $Name '*') -Destination $destDir -Recurse -Force
            Write-Host "[Bolt] ✓ Copiado .claude/skills/$Name/ -> $destDir" -ForegroundColor Green
        }

        'agent' {
            $copilotAgent = Join-Path '.github' 'agents' "$Name.agent.md"
            $claudeAgent = Join-Path '.claude' 'agents' "$Name.md"

            if ((Test-Path $copilotAgent)) {
                $destDir = Join-Path $script:BoltPrefix 'available-skills' 'contributed' $Name
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                Copy-Item $copilotAgent -Destination $destDir -Force
                Write-Host "[Bolt] ✓ Copiado $copilotAgent -> $destDir" -ForegroundColor Green
            }
            if ((Test-Path $claudeAgent)) {
                $destDir = Join-Path $script:BoltPrefix 'available-skills' 'contributed' $Name
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                Copy-Item $claudeAgent -Destination $destDir -Force
                Write-Host "[Bolt] ✓ Copiado $claudeAgent -> $destDir" -ForegroundColor Green
            }
        }

        default {
            Write-Host "[Bolt] Para tipo '$Type', edita los ficheros dentro de .boltf/ directamente y haz commit." -ForegroundColor Yellow
        }
    }

    # Stage y commit
    git add "$script:BoltPrefix/"
    $commitMsg = "feat($Type): $Description"
    git commit -m $commitMsg

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[Bolt] ✓ Contribución preparada en branch '$branchName'" -ForegroundColor Green
        Write-Host "[Bolt] Siguiente paso: Push-BoltContribution -Branch '$branchName'" -ForegroundColor DarkGray
    }
    else {
        Write-Warning "[Bolt] No hay cambios que commitear o hubo un error."
    }
}

function Push-BoltContribution {
    <#
    .SYNOPSIS
        Envía una contribución preparada al repositorio upstream de Bolt Framework.

    .DESCRIPTION
        Ejecuta git subtree push para enviar los cambios de .boltf/ al repositorio
        canónico como un branch de contribución. Después, se abre un PR manualmente.

    .PARAMETER Branch
        Nombre del branch en upstream (ej: "contrib/skill-browser-testing").

    .EXAMPLE
        Push-BoltContribution -Branch "contrib/skill-browser-testing"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Branch
    )

    if (-not (Ensure-BoltRemote)) { return }

    if ($PSCmdlet.ShouldProcess($Branch, "git subtree push a $script:BoltRemoteName")) {
        Write-Host "[Bolt] Enviando contribución a upstream..." -ForegroundColor Cyan
        Write-Host "[Bolt] Branch destino: $Branch" -ForegroundColor White

        git subtree push --prefix=$script:BoltPrefix $script:BoltRemoteName $Branch

        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[Bolt] ✓ Push completado." -ForegroundColor Green
            Write-Host "[Bolt] Abre un PR en: https://github.com/ava-group-iberiademos/bolt-framework/compare/$Branch" -ForegroundColor Cyan
            Write-Host "[Bolt] Branch: $Branch -> main" -ForegroundColor DarkGray
        }
        else {
            Write-Error "[Bolt] Error al hacer push. Verifica que el remote es accesible y tienes permisos."
        }
    }
}

function Initialize-BoltSubtree {
    <#
    .SYNOPSIS
        Migra un proyecto existente (creado via template o Init.ps1) al modelo
        de distribución bidireccional con git subtree.

    .DESCRIPTION
        Para proyectos que ya tienen .boltf/ copiado (via Init.ps1 o GitHub template),
        este comando establece la relación subtree con el repositorio canónico
        para habilitar pull de updates y push de contribuciones.

        IMPORTANTE: Ejecutar una sola vez por proyecto. Si el proyecto ya tiene
        el remote configurado, el comando lo detecta y aborta.

    .PARAMETER Version
        Tag de versión con la que se creó el proyecto (por defecto: lee de bolt-manifest.yaml).

    .EXAMPLE
        Initialize-BoltSubtree
        Initialize-BoltSubtree -Version v1.0.0
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$Version
    )

    # Verificar que .boltf/ existe (proyecto creado via template/Init.ps1)
    if (-not (Test-Path $script:BoltPrefix)) {
        Write-Error "No se encuentra .boltf/. Este comando es para proyectos existentes creados via template o Init.ps1."
        return
    }

    # Verificar que no está ya configurado
    $remotes = git remote
    if ($remotes -contains $script:BoltRemoteName) {
        Write-Warning "[Bolt] El remote '$script:BoltRemoteName' ya existe. El proyecto ya está configurado para subtree."
        Write-Host "[Bolt] Usa Get-BoltStatus para ver el estado actual." -ForegroundColor DarkGray
        return
    }

    # Determinar versión
    if (-not $Version) {
        $manifest = Get-BoltManifest
        if ($manifest) {
            $Version = "v$($manifest.Version)"
        }
        else {
            $Version = "v0.1.0"
            Write-Host "[Bolt] No se encontró bolt-manifest.yaml. Asumiendo $Version" -ForegroundColor Yellow
        }
    }

    if ($PSCmdlet.ShouldProcess($script:BoltPrefix, "Establecer relación subtree con $script:BoltRemoteUrl ($Version)")) {
        Write-Host "[Bolt] Migrando a modelo subtree bidireccional..." -ForegroundColor Cyan
        Write-Host "[Bolt] Repositorio: $script:BoltRemoteUrl" -ForegroundColor White
        Write-Host "[Bolt] Versión base: $Version" -ForegroundColor White

        # Paso 1: Añadir remote
        git remote add $script:BoltRemoteName $script:BoltRemoteUrl
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Error al añadir remote."
            return
        }
        Write-Host "[Bolt] ✓ Remote '$script:BoltRemoteName' añadido" -ForegroundColor Green

        # Paso 2: Fetch tags
        git fetch $script:BoltRemoteName --tags 2>$null
        Write-Host "[Bolt] ✓ Tags descargados" -ForegroundColor Green

        # Paso 3: Registrar el merge base para que futuros subtree pull funcionen.
        # Git subtree necesita un "synthetic merge" que establezca la relación.
        # Usamos un merge strategy=ours para registrar la conexión sin cambiar ficheros.
        $upstreamRef = git rev-parse "$script:BoltRemoteName/$Version" 2>$null
        if (-not $upstreamRef) {
            # Intentar como tag directo
            $upstreamRef = git rev-parse "$Version" 2>$null
        }

        if ($upstreamRef) {
            # Crear merge commit sintético que establece la base del subtree
            git merge -s ours --no-commit --allow-unrelated-histories "$script:BoltRemoteName/$Version" 2>$null
            if ($LASTEXITCODE -eq 0) {
                git commit --allow-empty -m "chore(bolt): establish subtree tracking for .boltf/ at $Version"
                Write-Host "[Bolt] ✓ Relación subtree establecida" -ForegroundColor Green
            }
            else {
                # Si merge falla (common en repos sin historia compartida), registrar via nota
                git notes add -m "bolt-subtree-base: $Version" HEAD 2>$null
                Write-Host "[Bolt] ✓ Base de subtree registrada (sin merge commit)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "[Bolt] ⚠ No se encontró ref '$Version' en upstream. El primer Update-BoltFramework establecerá la relación." -ForegroundColor Yellow
        }

        Write-Host "`n[Bolt] ✓ Migración completada." -ForegroundColor Green
        Write-Host @"

  Comandos disponibles:
    Get-BoltStatus              — Ver versión actual vs última disponible
    Update-BoltFramework        — Descargar actualizaciones
    New-BoltContribution        — Preparar cambio para enviar upstream
    Push-BoltContribution       — Enviar contribución al repo central
    Compare-BoltVersions        — Ver changelog entre versiones

"@ -ForegroundColor DarkGray
    }
}

# Exportar funciones públicas
Export-ModuleMember -Function @(
    'Get-BoltStatus'
    'Update-BoltFramework'
    'Compare-BoltVersions'
    'New-BoltContribution'
    'Push-BoltContribution'
    'Initialize-BoltSubtree'
)
