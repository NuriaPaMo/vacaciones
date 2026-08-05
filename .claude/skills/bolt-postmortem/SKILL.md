---
name: bolt-postmortem
description: "Generate blameless postmortems for incidents, outages and project failures using the Bolt Framework methodology. Focuses on systems/processes, not individuals. Produces timeline, root cause, learnings and action items. Triggers: 'postmortem', 'incident review', 'blameless retro', 'RCA', 'root cause analysis', 'outage analysis', '/bolt-postmortem'."
---

# Bolt Postmortem — Methodology

Generate blameless postmortems to learn from incidents and prevent
recurrence.

**Bolt Framework Stage**: PRODUCTION (Incident Learning)
**Responsible Agent**: Incident Analyst

## Postmortem philosophy

> "We don't ask WHO caused the incident.
> We ask WHAT conditions allowed it to happen."

```text
INCIDENT → INVESTIGATE → LEARN → IMPROVE → SHARE
```

Focus on:

- ✅ Systems and processes.
- ✅ Environmental factors.
- ✅ Knowledge gaps.
- ❌ NOT individual blame.

## Available scripts

- Bash: `scripts/bash/generate-postmortem.sh`
- PowerShell: `scripts/powershell/Generate-Postmortem.ps1`

## When to write a postmortem

| Trigger | Threshold | Required |
|---------|-----------|----------|
| **User impact** | > 1 % users affected | ✅ YES |
| **Duration** | > 30 minutes | ✅ YES |
| **Data loss** | Any | ✅ YES |
| **Security** | Any breach / exposure | ✅ YES |
| **Revenue** | > $1 000 | ✅ YES |
| **Near miss** | Could have been severe | ⚠️ Recommended |
| **Learning opportunity** | Novel failure mode | ⚠️ Recommended |

## Process

### 1. Gather data

```yaml
timeline:
  - Collect timestamps
  - Review alerts and pages
  - Interview participants (blameless)
  - Review chat logs
impact:
  - User metrics during incident
  - Error rates and logs
  - Revenue / business impact
  - Customer complaints
response:
  - Detection time
  - Diagnosis time
  - Mitigation time
  - Resolution time
```

### 2. Build timeline

Minute-by-minute (or hour-by-hour) reconstruction of events, with sources.

### 3. Root cause analysis

5-whys / fishbone. Identify multiple contributing factors, not a single
"root cause". Categorize: technical / process / human-factors /
organizational.

### 4. Learnings

What we learned that we did not know before? What worked well? What
worked poorly?

### 5. Action items

| ID | Action | Owner | Due | Type | Priority |

Types: prevent-recurrence, detect-faster, mitigate-faster, reduce-impact.

## Output — postmortem document

```markdown
# Postmortem: [Incident Name]

## Summary
| Field | Value |
|-------|-------|
| Date | YYYY-MM-DD |
| Duration | [HH:MM] |
| Severity | SEV-[1/2/3] |
| Impact | [users / revenue / data] |
| Author | [name] |

## Timeline
## Detection
## Root Cause(s)
## Contributing Factors
## What Went Well
## What Went Poorly
## Learnings
## Action Items
## References (logs, dashboards, PRs)
```

## Quality gates

- Blameless tone throughout.
- Timeline backed by sources.
- Each action item has owner + due date.
- Filed in `docs/postmortems/`.

## Related agents (next steps)

- → `bolt-improve`: feed action items into improvement plan.
- → `bolt-ops`: update runbooks based on learnings.
- → `bolt-adr`: document architectural changes resulting from postmortem.
