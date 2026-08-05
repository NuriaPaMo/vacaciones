# Operations Prompt

## Agent Reference

> **Primary Agents**:
>
> - [Proactive Operator](../copilot/agents/bolt-proactive-operator.md) - Monitoring & Incident Response
> - [Ops-Bugfix Autonomous](../copilot/agents/bolt-ops-bugfix-autonomous.md) - Auto-remediation & Self-healing
>
> **Phase**: Block 6 - Operations
> **Constitution**: Read `.boltf/memory/constitution.digest.md` for monitoring stack and SLO policies

## Context

Use this prompt when setting up monitoring, creating runbooks, analyzing incidents, or configuring auto-remediation. This prompt guides Copilot to act as the **Proactive Operator** and **Ops-Bugfix Autonomous** agents from the Bolt Framework methodology.

## Instructions

When managing operations:

### 1. Constitution Alignment

- Read `.boltf/memory/constitution.digest.md` for observability stack
- Use approved monitoring tools (Prometheus, Grafana, etc.)
- Follow SLO/SLA definitions from Constitution
- Respect incident management policies

### 2. Operational Principles

- **Proactive Detection**: Find issues before users do
- **Clear SLOs**: Define what "healthy" means
- **Automated Response**: Reduce MTTR with automation
- **Continuous Learning**: Postmortems for every incident

### 3. Key Artifacts

- Monitoring configurations
- Alert rules and thresholds
- Runbooks and playbooks
- Postmortem reports
- Auto-remediation patterns

### 4. Output Format

```markdown
# Operations Configuration: [Service Name]

## Service Overview
| Property | Value |
|----------|-------|
| Service | [Name] |
| Team | [Team] |
| Tier | Critical/Standard |
| On-call | [Rotation] |

## SLOs (Service Level Objectives)

| SLO | Target | Current | Status |
|-----|--------|---------|--------|
| Availability | 99.9% | 99.95% | ✅ |
| Latency P95 | <200ms | 150ms | ✅ |
| Error Rate | <0.1% | 0.05% | ✅ |

### Error Budget
- **Monthly Budget**: 43.2 minutes downtime
- **Consumed**: 15 minutes
- **Remaining**: 28.2 minutes (65%)

## Monitoring Configuration

### Health Checks
```yaml
health_checks:
  - name: liveness
    endpoint: /health/live
    interval: 10s
    timeout: 5s

  - name: readiness
    endpoint: /health/ready
    interval: 30s
    timeout: 10s

  - name: deep
    endpoint: /health/deep
    interval: 60s
    timeout: 30s
```

### Key Metrics

| Metric | Type | Labels | Alert Threshold |
|--------|------|--------|-----------------|
| http_requests_total | Counter | method, status, path | - |
| http_request_duration_seconds | Histogram | method, path | P95 > 200ms |
| active_connections | Gauge | - | > 1000 |
| error_rate | Gauge | - | > 0.1% |

### Prometheus Rules

```yaml
groups:
  - name: [service]-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: High error rate detected

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: P95 latency above threshold
```

### Dashboard Configuration

```json
{
  "dashboard": {
    "title": "[Service] Operations",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [{"expr": "rate(http_requests_total[5m])"}]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [{"expr": "rate(http_requests_total{status=~'5..'}[5m])"}]
      },
      {
        "title": "Latency P95",
        "type": "graph",
        "targets": [{"expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"}]
      }
    ]
  }
}
```

## Alert Configuration

### Alert Routing

| Severity | Channel | Response Time | Escalation |
|----------|---------|---------------|------------|
| Critical | PagerDuty + Slack | 5 min | Auto-escalate 15 min |
| Warning | Slack | 30 min | Manual escalation |
| Info | Email | Next business day | None |

### Alert Definitions

| Alert | Condition | Severity | Runbook |
|-------|-----------|----------|---------|
| ServiceDown | up == 0 for 1m | Critical | [Link] |
| HighErrorRate | error_rate > 1% for 5m | Critical | [Link] |
| HighLatency | p95 > 500ms for 5m | Warning | [Link] |
| DiskSpace | disk_used > 80% | Warning | [Link] |

## Runbooks

### RB-001: High Error Rate

**Symptoms**: Error rate > 1% for 5+ minutes

**Diagnosis Steps**:

1. Check recent deployments: `kubectl rollout history deployment/[service]`
2. Review error logs: `kubectl logs -l app=[service] --since=10m | grep ERROR`
3. Check downstream dependencies
4. Verify database connectivity

**Resolution Options**:

| Cause | Action | Auto-remediate? |
|-------|--------|-----------------|
| Bad deployment | Rollback | ✅ Yes |
| DB connection | Restart pods | ✅ Yes |
| Downstream failure | Circuit breaker | ✅ Yes |
| Unknown | Escalate | ❌ No |

**Rollback Command**:

```bash
kubectl rollout undo deployment/[service]
```

**Escalation**: If not resolved in 15 min, page on-call lead

---

### RB-002: High Latency

...

## Auto-Remediation Configuration

### Enabled Patterns

| Pattern | Confidence | Action | Conditions |
|---------|------------|--------|------------|
| OOM Kill | 95% | Restart pod | memory > 90% |
| Connection pool exhausted | 90% | Scale up | connections > 80% |
| Bad deployment | 85% | Rollback | error spike after deploy |
| Disk full | 95% | Cleanup logs | disk > 90% |

### Remediation Rules

```yaml
auto_remediation:
  - name: restart-on-oom
    trigger:
      metric: container_memory_usage_bytes
      condition: "> 0.9 * limit"
      duration: 2m
    action:
      type: restart_pod
      max_restarts: 3
      cooldown: 10m
    confidence: 0.95

  - name: rollback-on-error-spike
    trigger:
      metric: error_rate
      condition: "> 0.05"
      duration: 5m
      after_deployment: true
    action:
      type: rollback
      notify: true
    confidence: 0.85
```

### Escalation Thresholds

| Scenario | Escalate When |
|----------|---------------|
| Unknown error | Confidence < 70% |
| Repeated failure | Same issue 3x in 1h |
| Data-affecting | Any database issue |
| Security-related | Always |

## Postmortem Template

### Incident: [INC-XXXX]

**Summary**: [One-line description]

**Severity**: SEV1/SEV2/SEV3
**Duration**: [Start] - [End] ([Duration])
**Impact**: [Users/Revenue affected]

**Timeline**:
| Time | Event |
|------|-------|
| HH:MM | [Event] |

**Root Cause**: [Description]

**Resolution**: [What fixed it]

**Action Items**:
| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| [Action] | [Name] | [Date] | Open |

**Lessons Learned**:

- [Lesson 1]
- [Lesson 2]

```text

## Examples

### Input: Set Up Monitoring
```

Create monitoring for a .NET 8 API service:

- Deployed on Azure Container Apps
- PostgreSQL database backend
- Redis cache
- Expected: 500 req/sec peak

SLOs:

- 99.9% availability
- P95 latency < 150ms
- Error rate < 0.1%

```text

### Expected Focus
```markdown
## Key Metrics to Monitor

### Application Metrics
- Request rate and throughput
- Response time percentiles (P50, P95, P99)
- Error rate by status code
- Active connections

### Infrastructure Metrics
- Container CPU/Memory usage
- Container restarts
- Pod health status

### Dependency Metrics
- PostgreSQL connection pool usage
- PostgreSQL query latency
- Redis hit/miss ratio
- Redis connection count
```

### Input: Create Runbook

```text
Create runbook for: Database connection pool exhausted

Symptoms:
- "Cannot acquire connection" errors
- Increased latency
- Timeout errors

Environment:
- .NET 8 with Npgsql
- PostgreSQL on Azure
- Connection pool size: 100
```

### Input: Generate Postmortem

```text
Generate postmortem for:

Incident: API outage 2025-12-09 14:30-15:15 UTC
Cause: Memory leak after v2.3.0 deployment
Impact: 45 minutes downtime, ~5000 failed requests
Resolution: Rolled back to v2.2.9
```

## Integration Points

- **Input from**: `release-orchestrator.md` (deployment events), monitoring systems
- **Output to**: `coding-agent.md` (hotfixes), `continuous-evolver.md` (improvements)
- **Artifacts**: `docs/runbooks/`, `docs/postmortems/`, `monitoring/`
