---
name: bolt-alignment
description: "Analyze business-technical alignment across the Alignment Triangle (Business Goals ↔ Requirements ↔ Implementation). Cross-phase continuous validation using OKRs, KPIs, metrics, user feedback. Triggers: 'business alignment', 'goals vs implementation', 'OKR check', 'KPI tracking', 'strategic alignment', '/bolt-alignment'."
---

# Bolt Alignment — Methodology

Ensure continuous alignment between business objectives and technical
implementation.

**Bolt Framework Stage**: CROSS-PHASE (Continuous validation)
**Responsible Agent**: Business-Technical Alignment Analyst

## Alignment triangle

```text
            BUSINESS GOALS
                /\
               /  \
              /    \
             /      \
            /  ✓     \
           /          \
          /____________\
   REQUIREMENTS    IMPLEMENTATION
```

All three must align for project success.

## Available scripts

- Bash: `scripts/bash/alignment-analysis.sh`
- PowerShell: `scripts/powershell/Get-AlignmentAnalysis.ps1`

## Alignment dimensions

| Dimension | Question | Artifacts |
|-----------|----------|-----------|
| **Strategic** | Does it serve business goals? | OKRs, KPIs |
| **Functional** | Does it do what was requested? | Requirements, User Stories |
| **Technical** | Is it built correctly? | Code, Architecture |
| **Operational** | Does it perform as expected? | Metrics, SLAs |
| **User** | Does it meet user needs? | Feedback, Analytics |

## Analysis framework

### 1. Business goals mapping

```yaml
business_goals:
  - id: BG-001
    name: "Increase user retention"
    kpi: "30-day retention rate"
    target: ">= 60%"
    features:
      - F-001: User onboarding
      - F-002: Notification system
```

### 2. Feature-to-goal traceability

For each feature, document which business goal(s) it serves and which KPIs
it should move. Flag features without a clear goal.

### 3. Implementation health per goal

Aggregate: features delivered, in progress, blocked; KPI progress vs target.

### 4. Misalignment detection

- Features in flight that don't map to any goal.
- Goals without any features in delivery.
- KPIs trending against target despite delivery.

## Output — Alignment report

```markdown
## Alignment Report

### Strategic
| Goal | KPI | Target | Current | Status |

### Functional
| Feature | Goal(s) | Status |

### Misalignments
| Type | Detail | Action |

### Recommendations
```

## Related agents (next steps)

- → `bolt-analyze`: technical consistency check.
- → `bolt-improve`: opportunities to close the alignment gap.
- → `bolt-specify`: update requirements when business pivots.
- → `bolt-status`: overall project status.
