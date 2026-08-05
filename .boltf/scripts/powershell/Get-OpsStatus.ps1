<#
.SYNOPSIS
    Generates operational status and runbook documentation.

.DESCRIPTION
    This script collects system health information and generates/updates
    operational runbooks following the AI-DLC methodology.

.PARAMETER Environment
    Target environment (development, staging, production).

.PARAMETER GenerateRunbook
    If specified, generates or updates the ops_runbook.md file.

.PARAMETER HealthCheckOnly
    If specified, only performs health checks without generating documentation.

.EXAMPLE
    .\Get-OpsStatus.ps1 -Environment production
    .\Get-OpsStatus.ps1 -GenerateRunbook
    .\Get-OpsStatus.ps1 -HealthCheckOnly

.NOTES
    Part of Bolt Framework / AI-DLC methodology
    Phase: Block 6 - Operations
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment = "development",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateRunbook,

    [Parameter(Mandatory = $false)]
    [switch]$HealthCheckOnly
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n📋 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ℹ️  $Message" -ForegroundColor Blue
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "  ❌ $Message" -ForegroundColor Red
}

function Get-HealthStatus {
    param([string]$Status)
    switch ($Status) {
        "healthy" { return "🟢" }
        "degraded" { return "🟡" }
        "unhealthy" { return "🔴" }
        default { return "⚪" }
    }
}

# ============================================================================
# HEALTH CHECKS
# ============================================================================

function Test-LocalServices {
    Write-Step "Checking local services..."

    $services = @()

    # Check if common development services are running
    $ports = @(
        @{ Port = 5000; Name = "API (5000)" },
        @{ Port = 5001; Name = "API HTTPS (5001)" },
        @{ Port = 3000; Name = "Frontend (3000)" },
        @{ Port = 5432; Name = "PostgreSQL (5432)" },
        @{ Port = 6379; Name = "Redis (6379)" },
        @{ Port = 8080; Name = "Proxy (8080)" }
    )

    foreach ($p in $ports) {
        $connection = Test-NetConnection -ComputerName localhost -Port $p.Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

        $status = if ($connection.TcpTestSucceeded) { "healthy" } else { "stopped" }

        $services += @{
            Name = $p.Name
            Port = $p.Port
            Status = $status
            StatusIcon = Get-HealthStatus $status
        }
    }

    return $services
}

function Get-SystemResources {
    Write-Step "Checking system resources..."

    $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $memory = Get-CimInstance Win32_OperatingSystem
    $memUsed = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize * 100, 1)

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskUsed = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)

    return @{
        CPU = @{ Value = $cpu; Status = if ($cpu -gt 85) { "degraded" } elseif ($cpu -gt 95) { "unhealthy" } else { "healthy" } }
        Memory = @{ Value = $memUsed; Status = if ($memUsed -gt 85) { "degraded" } elseif ($memUsed -gt 95) { "unhealthy" } else { "healthy" } }
        Disk = @{ Value = $diskUsed; Status = if ($diskUsed -gt 80) { "degraded" } elseif ($diskUsed -gt 90) { "unhealthy" } else { "healthy" } }
    }
}

function Test-DockerContainers {
    Write-Step "Checking Docker containers..."

    $containers = @()

    try {
        $dockerPs = docker ps --format "{{.Names}}|{{.Status}}|{{.Ports}}" 2>$null
        if ($dockerPs) {
            foreach ($line in ($dockerPs -split "`n")) {
                if (-not $line) { continue }
                $parts = $line -split "\|"
                $status = if ($parts[1] -match "Up") { "healthy" } else { "unhealthy" }
                $containers += @{
                    Name = $parts[0]
                    Status = $status
                    StatusIcon = Get-HealthStatus $status
                    Details = $parts[1]
                }
            }
        }
    } catch {
        Write-Warn "Docker not available or not running"
    }

    return $containers
}

# ============================================================================
# RUNBOOK GENERATION
# ============================================================================

function New-OpsRunbook {
    param(
        [string]$ProjectName,
        [string]$Environment
    )

    $runbookDir = "docs/runbooks"
    if (-not (Test-Path $runbookDir)) {
        New-Item -ItemType Directory -Path $runbookDir -Force | Out-Null
    }

    $runbookPath = "$runbookDir/ops_runbook.md"
    $date = Get-Date -Format "yyyy-MM-dd"

    # Try to get project name from various sources
    if (-not $ProjectName) {
        if (Test-Path "package.json") {
            $pkg = Get-Content "package.json" | ConvertFrom-Json
            $ProjectName = $pkg.name
        } elseif (Test-Path "*.csproj") {
            $ProjectName = (Get-ChildItem "*.csproj" | Select-Object -First 1).BaseName
        } else {
            $ProjectName = Split-Path -Leaf (Get-Location)
        }
    }

    $content = @"
# Operations Runbook: $ProjectName

## Document Info

| Property | Value |
|----------|-------|
| Last Updated | $date |
| Version | 1.0 |
| Owner | [Team Name] |
| Review Cycle | Monthly |

---

## Service Overview

### Architecture Summary

[Add high-level architecture description here]

### Service Inventory

| Service | Purpose | Tech Stack | Critical |
|---------|---------|------------|----------|
| API | Backend services | [Stack] | Yes |
| Frontend | User interface | [Stack] | Yes |
| Database | Data persistence | [Stack] | Yes |

### Dependencies

| Dependency | Type | SLA | Fallback |
|------------|------|-----|----------|
| [Service] | Internal/External | [%] | [Strategy] |

---

## Health Endpoints

| Service | Endpoint | Expected | Timeout | Frequency |
|---------|----------|----------|---------|-----------|
| API | /health | 200 OK | 5s | 30s |
| API | /health/ready | 200 OK | 10s | 60s |
| API | /health/live | 200 OK | 5s | 10s |

### Health Check Commands

``````bash
# Quick health check
curl -f http://localhost:5000/health || echo "UNHEALTHY"

# Detailed health check
curl -s http://localhost:5000/health/ready | jq
``````

---

## SLOs (Service Level Objectives)

| SLO | Target | Window | Budget |
|-----|--------|--------|--------|
| Availability | 99.9% | 30 days | 43.2 min |
| Latency P95 | <200ms | 30 days | N/A |
| Error Rate | <0.1% | 30 days | N/A |

---

## Key Metrics

| Metric | Type | Normal Range | Alert Threshold |
|--------|------|--------------|-----------------|
| CPU Usage | Gauge | <70% | >85% |
| Memory Usage | Gauge | <80% | >90% |
| Request Rate | Counter | Variable | Spike >200% |
| Error Rate | Gauge | <0.1% | >1% |
| P95 Latency | Histogram | <200ms | >500ms |

---

## Common Issues & Remediation

### Issue: Service Not Responding

**Symptoms**:
- Health check failures
- 502/503 errors
- Timeout errors

**Diagnosis**:
``````bash
# Check service status
docker ps | grep [service]
# or for systemd
systemctl status [service]

# Check logs
docker logs [container] --tail=100
# or
journalctl -u [service] -n 100
``````

**Remediation**:
1. Check resource utilization
2. Review recent deployments
3. Restart service if needed

**Escalation**: 15 minutes without resolution → Escalate to on-call lead

---

### Issue: High Latency

**Symptoms**:
- P95 > 500ms
- User complaints
- Timeout increases

**Diagnosis**:
``````bash
# Check database connections
# Check slow queries
# Review APM traces
``````

**Remediation**:
1. Check database load
2. Review recent code changes
3. Scale horizontally if load-related

---

### Issue: High Error Rate

**Symptoms**:
- Error rate > 1%
- 5xx responses increasing
- Failed requests in logs

**Diagnosis**:
``````bash
# Check error logs
grep -i error /var/log/[service]/*.log | tail -50

# Check application metrics
``````

**Remediation**:
1. Identify error type from logs
2. Check dependent services
3. Roll back if deployment-related

---

## Scaling Procedures

### Horizontal Scaling

**When to scale**:
- CPU > 70% sustained (5+ min)
- Request queue growing
- Response times degrading

**How to scale**:
``````bash
# Docker Compose
docker-compose up -d --scale api=3

# Kubernetes
kubectl scale deployment/api --replicas=3
``````

---

## Backup & Recovery

### Backup Schedule

| Resource | Frequency | Retention | Location |
|----------|-----------|-----------|----------|
| Database | Daily | 30 days | [Location] |
| Configs | On change | 90 days | Git |
| Logs | Continuous | 14 days | [Location] |

### Database Recovery

``````bash
# List backups
[backup list command]

# Restore from backup
[restore command]
``````

---

## Emergency Contacts

| Role | Contact | Escalation Time |
|------|---------|-----------------|
| Primary On-Call | [Contact] | Immediate |
| Secondary On-Call | [Contact] | 15 min |
| Engineering Manager | [Contact] | 30 min |

---

## Maintenance Windows

| Type | Schedule | Duration | Notification |
|------|----------|----------|--------------|
| Routine | Sunday 2-4 AM | 2 hours | 48h advance |
| Emergency | As needed | Variable | ASAP |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | $date | Bolt Framework | Initial version |

---

*Generated by Bolt Framework Ops Command*
"@

    Set-Content -Path $runbookPath -Value $content
    return $runbookPath
}

# ============================================================================
# STATUS REPORT GENERATION
# ============================================================================

function New-StatusReport {
    param(
        [array]$Services,
        [hashtable]$Resources,
        [array]$Containers
    )

    $date = Get-Date -Format "yyyy-MM-dd HH:mm"

    # Determine overall health
    $overallHealth = "🟢 Healthy"
    if ($Resources.CPU.Status -eq "unhealthy" -or $Resources.Memory.Status -eq "unhealthy") {
        $overallHealth = "🔴 Critical"
    } elseif ($Resources.CPU.Status -eq "degraded" -or $Resources.Memory.Status -eq "degraded") {
        $overallHealth = "🟡 Degraded"
    }

    $report = @"

═══════════════════════════════════════════════════════════════
  OPERATIONAL STATUS REPORT
  Generated: $date
  Environment: $Environment
  Overall Health: $overallHealth
═══════════════════════════════════════════════════════════════

📊 SYSTEM RESOURCES
───────────────────────────────────────────────────────────────
  $(Get-HealthStatus $Resources.CPU.Status) CPU:     $($Resources.CPU.Value)%
  $(Get-HealthStatus $Resources.Memory.Status) Memory:  $($Resources.Memory.Value)%
  $(Get-HealthStatus $Resources.Disk.Status) Disk:    $($Resources.Disk.Value)%

"@

    if ($Services.Count -gt 0) {
        $report += @"
🔌 LOCAL SERVICES
───────────────────────────────────────────────────────────────
"@
        foreach ($svc in $Services) {
            $report += "  $($svc.StatusIcon) $($svc.Name): $($svc.Status)`n"
        }
    }

    if ($Containers.Count -gt 0) {
        $report += @"

🐳 DOCKER CONTAINERS
───────────────────────────────────────────────────────────────
"@
        foreach ($c in $Containers) {
            $report += "  $($c.StatusIcon) $($c.Name): $($c.Details)`n"
        }
    }

    $report += @"

═══════════════════════════════════════════════════════════════
"@

    return $report
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "`n🔍 Bolt Framework Operations Status" -ForegroundColor Magenta
Write-Host "====================================`n" -ForegroundColor Magenta

# Collect health data
$services = Test-LocalServices
$resources = Get-SystemResources
$containers = Test-DockerContainers

# Generate status report
$report = New-StatusReport -Services $services -Resources $resources -Containers $containers
Write-Host $report

if ($HealthCheckOnly) {
    exit 0
}

# Generate runbook if requested or if it doesn't exist
$runbookPath = "docs/runbooks/ops_runbook.md"
if ($GenerateRunbook -or -not (Test-Path $runbookPath)) {
    Write-Step "Generating Operations Runbook..."
    $path = New-OpsRunbook -Environment $Environment
    Write-Success "Runbook created: $path"
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review runbook: docs/runbooks/ops_runbook.md"
Write-Host "  2. Update service-specific procedures"
Write-Host "  3. Add emergency contacts"
Write-Host "  4. Run @Bolt Postmortem if incident occurred`n"
