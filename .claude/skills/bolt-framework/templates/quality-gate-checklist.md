# Quality Gate Checklist

> Use this checklist at each Bolt boundary and before merging to main.
> Copy, fill in feature/bolt details, and verify all gates pass.

---

## Feature: [FEATURE-NAME]

## Bolt: [BOLT-N]

## Date: [YYYY-MM-DD]

## Reviewer: [AGENT or HUMAN]

---

## 1. Code Quality

- [ ] **Linting**: All linting rules pass (`0 errors, 0 warnings`)
- [ ] **Formatting**: Code formatted per project standards
- [ ] **No TODO/FIXME**: No unresolved TODO or FIXME comments in deliverable code
- [ ] **Dead code**: No unreachable or unused code introduced
- [ ] **Naming conventions**: All identifiers follow constitution naming rules

## 2. Test Coverage

| Metric | Threshold | Actual | Pass? |
|--------|-----------|--------|-------|
| Line coverage | ≥ 80% | __%  | ☐ |
| Branch coverage | ≥ 75% | __% | ☐ |
| Mutation score | ≥ 70% | __% | ☐ |
| Critical path coverage | 100% | __% | ☐ |

- [ ] All unit tests pass
- [ ] All integration tests pass (if applicable)
- [ ] Edge cases covered (null, empty, boundary values)
- [ ] Error paths tested

## 3. Architecture Compliance

- [ ] **Layered architecture**: Dependencies flow in correct direction
- [ ] **No circular dependencies**: Module dependency graph is acyclic
- [ ] **SOLID principles**: Single Responsibility, Interface Segregation respected
- [ ] **DDD boundaries**: Aggregate roots and bounded contexts maintained
- [ ] **Pattern consistency**: Follows established patterns in constitution

## 4. Security

- [ ] **No hardcoded secrets**: No API keys, passwords, or tokens in code
- [ ] **Input validation**: All external inputs sanitized and validated
- [ ] **OWASP Top 10**: No introduction of common vulnerabilities
- [ ] **Dependencies**: No known vulnerable dependencies added
- [ ] **Authentication/Authorization**: Proper checks on protected resources

## 5. Documentation

- [ ] **Code comments**: Complex logic has explanatory comments
- [ ] **API documentation**: Public APIs documented (JSDoc/TSDoc/Docstrings)
- [ ] **README updates**: README reflects any new setup/config requirements
- [ ] **ADR created**: Architecture Decision Record created if applicable
- [ ] **Changelog entry**: Change described in changelog or release notes

## 6. Performance

- [ ] **No N+1 queries**: Database queries optimized
- [ ] **No memory leaks**: Resources properly disposed/released
- [ ] **Bundle size**: No unexpected increase in bundle size
- [ ] **Response time**: API response within SLA thresholds

## 7. Specification Alignment

- [ ] **User story satisfied**: Implementation matches the user story intent
- [ ] **Acceptance criteria**: All acceptance criteria verified
- [ ] **Contract compliance**: API contracts match specification
- [ ] **No scope creep**: No functionality beyond the Bolt scope

---

## Gate Decision

| Decision | Criteria |
|----------|----------|
| ✅ **PASS** | All required checks pass, thresholds met |
| ⚠️ **CONDITIONAL PASS** | Minor issues documented, tracked for next Bolt |
| ❌ **FAIL** | Critical issues found, Bolt requires rework |

**Decision**: [ PASS / CONDITIONAL PASS / FAIL ]

**Notes**:
> [Any observations, deferred items, or follow-up actions]

---

## Sign-off

| Role | Agent/Person | Date | Status |
|------|-------------|------|--------|
| Implementation | @Bolt Implement | | ☐ |
| Review | @Bolt Review | | ☐ |
| Testing | @Bolt Testing | | ☐ |
| Security | @Bolt Security | | ☐ |
