# Hotfix Workflow — Emergency Production Fix

> Workflow for fixing critical bugs in production with minimal process overhead.

---

## Overview

```text
Hotfix Branch → Implement Fix → Test → Review → Emergency Release → Postmortem
```

## When to Use

- Production is broken or degraded
- Security vulnerability discovered
- Data corruption or loss risk
- SLA breach imminent

## Step-by-Step

### 1. Create Hotfix Branch

```bash
# Branch from main/production
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug-description
```

### 2. Implement Fix (Single Bolt)

Invoke `@Bolt Implement`:

```text
"Hotfix: [describe the issue]. Fix it with minimal changes.
Branch: hotfix/critical-bug-description.
Skip full Bolt ceremony — this is an emergency fix."
```

The agent will:

1. Read constitution for standards (still must comply)
2. Identify root cause
3. Apply minimal fix
4. Write regression test

### 3. Test Fix

Invoke `@Bolt Testing`:

```text
"Generate regression tests for the hotfix. Verify:
1. The bug is fixed
2. No other functionality is broken
3. Edge cases are covered"
```

Run full test suite:

```bash
./scripts/bash/quality-gates.sh
```

### 4. Quick Review

Invoke `@Bolt Review`:

```text
"Quick review of hotfix. Focus on:
1. Fix correctness
2. No side effects
3. Regression test quality"
```

### 5. Emergency Release

Invoke `@Bolt Release`:

```text
"Emergency release for hotfix. Patch version bump.
Include only the hotfix changes."
```

### 6. Postmortem (After Stabilization)

Invoke `@Bolt Postmortem`:

```text
"Generate postmortem for [incident description].
Include: timeline, root cause, fix applied, prevention measures."
```

---

## Key Differences from Normal Flow

| Aspect | Normal | Hotfix |
|--------|--------|--------|
| Branching | feature/ → bolt-N | hotfix/ from main |
| Bolt ceremony | Full planning | Single Bolt, skip planning |
| Review depth | Full review | Quick review (correctness focus) |
| Release | Normal process | Emergency patch release |
| Postmortem | Not required | Required after stabilization |
| Quality gates | All must pass | All must pass (no shortcuts) |

> **Important**: Quality gates are NOT skipped for hotfixes. The fix must still pass
> linting, tests, and security checks. Only the planning ceremony is abbreviated.
