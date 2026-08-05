---
name: bolt-review
description: "Comprehensive Bolt Framework code review validating constitution compliance, architecture patterns (Clean Arch, DDD, CQRS, Hexagonal), SOLID principles and test quality. Produces a review report with blocking vs major findings. Triggers: 'code review', 'review code', 'check SOLID', 'review BOLT', 'review PR', 'REVIEW phase', '/bolt-review'."
---

# Bolt Review — Methodology

Perform comprehensive code review validating constitution compliance,
architecture patterns, and coding standards.

**Bolt Framework Stage**: REVIEW
**Responsible Agent**: Code Reviewer

## Review dimensions

```text
CORRECT → SECURE → CLEAN → TESTED
Does it    Is it     Is it      Is it
work?      safe?     readable?  verified?
```

## Available scripts

- Bash: `scripts/bash/quality-gates.sh`
- PowerShell: `scripts/powershell/Quality-Gates.ps1`

## Review checklist

### 1. Constitution compliance (CRITICAL)

| Check | Description | Severity |
|-------|-------------|----------|
| Stack | Uses allowed languages/frameworks | 🔴 BLOCKING |
| Patterns | Follows defined architecture | 🔴 BLOCKING |
| Standards | Meets coding standards | 🟡 MAJOR |
| Testing | Meets coverage requirements | 🟡 MAJOR |
| Security | Follows security policies | 🔴 BLOCKING |

### 2. Architecture patterns

| Pattern | Validation |
|---------|------------|
| **Clean Architecture** | Dependencies point inward |
| **DDD** | Domain is isolated and rich |
| **CQRS** | Commands and Queries separated |
| **Event Sourcing** | Events are immutable |
| **Hexagonal** | Ports and Adapters defined |

### 3. SOLID principles

| Principle | Check | Common violations |
|-----------|-------|-------------------|
| **S** — Single Responsibility | Class does one thing | God classes |
| **O** — Open/Closed | Extendable w/o modification | Switch statements |
| **L** — Liskov Substitution | Subtypes replaceable | Override exceptions |
| **I** — Interface Segregation | Small focused interfaces | Fat interfaces |
| **D** — Dependency Inversion | Depend on abstractions | Concrete dependencies |

### 4. Code quality

- Naming clarity.
- Duplication.
- Cyclomatic complexity.
- Long methods / large classes.
- Magic numbers / hardcoded values.
- Comments WHY, not WHAT.

### 5. Test quality

- Coverage ≥ thresholds.
- Mutation score ≥ 70 %.
- Tests assert behavior, not implementation.
- AAA pattern (Arrange-Act-Assert).
- No flaky tests.
- Smoke paths marked.
- **[frontend/fullstack bolts]** Para cada componente de UI nuevo que implemente un flujo de usuario visible, existe un test E2E (p. ej. `e2e/tests/<feature>/<component>.spec.*`) con al menos 1 escenario `@smoke` ejecutable. Ausencia = 🔴 BLOCKING.

## Output — Review report

```markdown
## Code Review: [BOLT N / PR #X]

### Blocking issues (🔴)
| File:Line | Issue | Severity | Fix |

### Major issues (🟡)
| File:Line | Issue | Severity | Suggested |

### Suggestions (🟢)
| File:Line | Improvement |

### Coverage
| Metric | Value | Threshold | Status |

### Recommendation
- [ ] APPROVE
- [ ] REQUEST CHANGES (blocking found)
- [ ] DISCUSS (architectural concerns)
```

## Artifacts / templates literales

### Security review checklist (PR-level, fast)

This is the **fast PR-level checklist**. For deep stack-aware analysis,
hand off to `bolt-security`.

| Category | Checks |
|----------|--------|
| **Input Validation** | All inputs validated and sanitized |
| **Authentication** | Proper auth checks in place |
| **Authorization** | RBAC / ABAC correctly implemented |
| **Secrets** | No hardcoded secrets or keys |
| **SQL Injection** | Parameterized queries only |
| **XSS** | Output encoding in place |
| **CSRF** | Tokens validated |
| **Dependencies** | No known vulnerabilities |

### Code quality checklist

| Aspect | Requirements |
|--------|--------------|
| **Naming** | Clear, intention-revealing names |
| **Functions** | Small, single purpose |
| **Comments** | Why, not what (code is self-documenting) |
| **Error Handling** | Comprehensive and consistent |
| **Logging** | Appropriate level, no sensitive data |
| **Magic Numbers** | None — use named constants |

### Review process (3 steps)

#### Step 1: Load context

```bash
cat .boltf/memory/constitution.digest.md
cat specs/[XXX-feature-name]/requirements/requirements.md
find src/ -name "*.ts" -o -name "*.cs" | head -20
```

#### Step 2: Systematic review per file

1. **Architecture Check** — correct layer, valid dependencies, interface
   segregation.
2. **Logic Check** — edge cases, error handling, business rules.
3. **Security Check** — input validation, auth / authz, no
   vulnerabilities.
4. **Quality Check** — naming, function size, DRY.

#### Step 3: Generate report (see Output format below)

### Output format (review report)

````markdown
# 👀 Code Review Report

**Feature**: [XXX-feature-name]
**Reviewer**: bolt-review
**Date**: [timestamp]

## Summary
| Category | Issues | Severity |
|----------|--------|----------|
| Constitution | [N] | 🔴 |
| Architecture | [N] | 🟡 |
| Security | [N] | 🔴 |
| Quality | [N] | 🟢 |
| Testing | [N] | 🟡 |

**Verdict**: ✅ APPROVED / ⚠️ APPROVED WITH CHANGES / 🔴 CHANGES REQUIRED

## Critical Issues (🔴)

### 1. SQL Injection vulnerability
**File**: `src/domain/services/payment-service.ts`
**Line**: 45-52

```typescript
// ❌ VULNERABLE
const query = `SELECT * FROM users WHERE id = ${userId}`;

// ✅ FIXED
const query = 'SELECT * FROM users WHERE id = $1';
const result = await db.query(query, [userId]);
```

**Impact**: Critical security vulnerability
**Fix**: Use parameterized queries

## Major Issues (🟡)

### 2. God method — 150+ lines
**File**: `src/application/services/user-service.ts`
**Line**: 120

```typescript
// ❌ TOO LARGE
async processUserRequest(request: UserRequest) {
  // 150 lines of code...
}
```

**Fix**: Extract into smaller methods:
- `validateRequest()`
- `processPayment()`
- `updateUser()`
- `sendNotification()`

## Minor Issues (🟢)

### 3. Magic number
**File**: `src/infrastructure/repositories/user-repository.ts`
**Line**: 30

```typescript
// ❌ MAGIC NUMBER
if (retryCount > 3) { ... }

// ✅ NAMED CONSTANT
const MAX_RETRIES = 3;
if (retryCount > MAX_RETRIES) { ... }
```

## Positive Highlights ✨
1. Excellent domain model encapsulation
2. Comprehensive error handling in use cases
3. Good test coverage structure

## Action Items
| Priority | Action | Assignee |
|----------|--------|----------|
| P0 | Fix SQL injection vulnerability | Dev |
| P1 | Refactor god methods | Dev |
| P2 | Add missing unit tests | Dev |

## Next Steps
1. Address P0 issues immediately
2. Use bolt-implement to apply fixes
3. Re-run review after changes
````

## Related agents (next steps)

- → `bolt-implement`: apply fixes.
- → `bolt-testing`: improve coverage if below threshold.
- → `bolt-adr`: document architectural decisions surfaced in review.
- → `bolt-security`: hand off security findings for deeper analysis.
