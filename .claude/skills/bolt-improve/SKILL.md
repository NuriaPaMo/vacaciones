---
name: bolt-improve
description: "Continuous improvement (Kaizen) analysis for Bolt Framework projects in PRODUCTION — code quality, performance, reliability, security, DevEx and documentation. Uses MEASURE → ANALYZE → IMPROVE → CONTROL loop. Triggers: 'continuous improvement', 'kaizen', 'tech debt analysis', 'performance improvement', 'improvement opportunities', 'PRODUCTION phase', '/bolt-improve'."
---

# Bolt Improve — Methodology

Analyze project for continuous improvement opportunities across code,
architecture, and operations.

**Bolt Framework Stage**: PRODUCTION (Continuous Improvement)
**Responsible Agent**: Continuous Improvement Analyst

## Improvement philosophy

```text
MEASURE → ANALYZE → IMPROVE → CONTROL → (loop)
Collect    Find       Implement  Maintain
data       root       solutions  gains
           causes
```

> "Small improvements every day lead to stunning results."

## Available scripts

- Bash: `scripts/bash/analyze-improvements.sh`
- PowerShell: `scripts/powershell/Get-Improvements.ps1`

## Improvement categories

| Category | Focus areas | Tools / Metrics |
|----------|-------------|-----------------|
| **Code Quality** | Complexity, duplication, debt | SonarQube, CodeClimate |
| **Performance** | Response time, throughput | APM, profilers |
| **Reliability** | Uptime, error rates | Monitoring, logs |
| **Security** | Vulnerabilities, compliance | SAST, DAST, audit |
| **Developer Experience** | Build time, test time | CI/CD metrics |
| **Documentation** | Coverage, freshness | Doc tools |

## Process

### 1. Collect metrics

```yaml
metrics:
  code:
    - cyclomatic_complexity
    - code_duplication
    - technical_debt_ratio
    - test_coverage
    - mutation_score
  performance:
    - p50_latency
    - p95_latency
    - p99_latency
    - throughput_rps
    - error_rate
  reliability:
    - uptime
    - MTBF
    - MTTR
  devex:
    - build_time
    - test_time
    - lead_time_for_change
```

### 2. Analyze (root cause)

Use 5-whys / fishbone / Pareto to find root causes per category.

### 3. Prioritize improvements

Impact × Effort matrix. Pick top N for the next iteration.

### 4. Implement

Delegate to `bolt-implement` with specific improvement spec; add ADR for
significant changes via `bolt-adr`.

### 5. Control / measure again

Re-run metrics after deployment; compare against baseline.

## Output — Improvement plan

```markdown
## Improvement Plan

### Top opportunities (Impact × Effort)
| Opportunity | Category | Impact | Effort | Priority |

### Action items
1. [P1] ...
2. [P2] ...

### Baseline metrics
| Metric | Current | Target |
```

## Related agents (next steps)

- → `bolt-analyze`: technical consistency for selected improvements.
- → `bolt-implement`: implement the change.
- → `bolt-alignment`: verify improvements align with business goals.
- → `bolt-adr`: document significant decisions.
