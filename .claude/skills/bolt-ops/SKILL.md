---
name: bolt-ops
description: "Manage operations, deployments, monitoring and incident response for Bolt Framework projects in PRODUCTION. Covers env config, deploy flow with pre/post checks and rollback, alert configuration. Triggers: 'operations', 'deploy to environment', 'production health', 'incident response', 'rollback', 'PRODUCTION phase', '/bolt-ops'."
---

# Bolt Ops — Methodology

Manage deployments, monitoring, and operational health of Bolt Framework
projects.

**Bolt Framework Stage**: PRODUCTION
**Responsible Agent**: Operations Manager

## Operational lifecycle

```text
DEPLOY → MONITOR → RESPOND → IMPROVE → DEPLOY
```

## Available scripts

- Bash: `scripts/bash/ops-status.sh`
- PowerShell: `scripts/powershell/Get-OpsStatus.ps1`

## Environment configuration

| Environment | Purpose | Auto-deploy |
|-------------|---------|-------------|
| `development` | Feature testing | On PR |
| `staging` | Integration testing | On merge to main |
| `production` | Live users | Manual trigger |

## Deploy command

```bash
# Deploy to environment
@bolt-ops deploy [environment] [version]

# Examples
@bolt-ops deploy staging latest
@bolt-ops deploy production v1.2.3
```

## Deployment process

```yaml
deploy:
  pre-checks:
    - Verify version exists
    - Check environment health
    - Validate configuration
  steps:
    - Backup current state
    - Pull artifacts
    - Run database migrations
    - Deploy application
    - Run smoke tests
    - Update load balancer
  post-checks:
    - Verify health endpoints
    - Check error rates
    - Validate metrics
  rollback:
    - Auto-rollback if checks fail
    - Preserve logs
    - Alert team
```

## Monitoring & alerting

### Health status template

```markdown
## System Health

| Service | Status | Latency | Error Rate |
|---------|--------|---------|------------|
| API Gateway | ✅ Healthy | 45ms | 0.01 % |
| User Service | ✅ Healthy | 23ms | 0.02 % |
| Payment Service | ⚠️ Degraded | 150ms | 0.5 % |
| Database | ✅ Healthy | 12ms | 0 % |
| Cache | ✅ Healthy | 2ms | 0 % |
```

### Performance metrics template

```markdown
## Performance Metrics (Last 24h)

| Metric | Current | Avg | P95 | P99 |
|--------|---------|-----|-----|-----|
| Response Time | 45ms | 52ms | 120ms | 250ms |
| Requests/sec | 1,234 | 1,100 | 2,500 | 3,000 |
| Error Rate | 0.02 % | 0.05 % | 0.1 % | 0.5 % |
| CPU Usage | 45 % | 40 % | 70 % | 85 % |
| Memory | 60 % | 55 % | 75 % | 85 % |
```

### Alert configuration

```yaml
alerts:
  critical:
    - name: High Error Rate
      condition: error_rate > 1%
      duration: 5m
      action: page_oncall

    - name: Service Down
      condition: health_check == failed
      duration: 1m
      action: page_oncall

  warning:
    - name: Elevated Latency
      condition: latency_p95 > 500ms
      duration: 10m
      action: slack_alert

    - name: Disk Space
      condition: disk_usage > 80%
      duration: 15m
      action: email_team
```

## Runbooks

Maintain runbooks under `docs/ops/runbooks/`. Each runbook covers:

- **When triggered**: alert name / observable symptom.
- **First response**: 5-minute mitigation steps.
- **Investigation**: where to look (dashboards, logs, traces).
- **Resolution**: full fix path.
- **Postmortem trigger**: when to file via `bolt-postmortem`.

## Quality gates

- Every alert has a runbook.
- Rollback automated and tested.
- Smoke tests pass post-deploy.
- Health endpoints return < 200 within 1 s.

## Related agents (next steps)

- → `bolt-monitoring`: tune dashboards and alert rules.
- → `bolt-postmortem`: file blameless postmortem after incidents.
- → `bolt-improve`: feed operational data into improvements.
- → `bolt-release`: create next release.
