# Bolt Task Template

> Template for defining a Bolt (micro-iteration) task breakdown.
> Location: `specs/[XXX-feature-name]/planning/tasks.md`

---

## Feature: [XXX-FEATURE-NAME]

**Created**: [DATE]
**Feature Spec**: `specs/[XXX-feature-name]/feature.md`
**Plan**: `specs/[XXX-feature-name]/planning/plan.md`

---

## Bolt 1: [Layer/Component Name]

**Goal**: [What this Bolt delivers]
**Estimated**: [1-3 days]
**Branch**: `feature/[feature-name]/bolt-1-[description]`

### Tasks

- [ ] T001: [Task description — specific, actionable]
- [ ] T002: [Task description]
- [ ] T003: [Task description]
- [ ] T004: Unit tests for Bolt 1 components

### Acceptance Criteria

- [ ] AC1: [Measurable criterion]
- [ ] AC2: [Measurable criterion]

### Quality Gates

- [ ] Linting passes
- [ ] Tests pass (≥80% coverage)
- [ ] No security vulnerabilities
- [ ] Architecture compliance

---

## Bolt 2: [Layer/Component Name]

**Goal**: [What this Bolt delivers]
**Estimated**: [1-3 days]
**Branch**: `feature/[feature-name]/bolt-2-[description]`
**Depends on**: Bolt 1

### Tasks

- [ ] T005: [Task description]
- [ ] T006: [Task description]
- [ ] T007: [Task description]
- [ ] T008: Unit tests for Bolt 2 components

### Acceptance Criteria

- [ ] AC3: [Measurable criterion]
- [ ] AC4: [Measurable criterion]

### Quality Gates

- [ ] Linting passes
- [ ] Tests pass (≥80% coverage)
- [ ] No security vulnerabilities
- [ ] Architecture compliance

---

## Bolt 3: [Integration/API Layer]

**Goal**: [What this Bolt delivers]
**Estimated**: [1-3 days]
**Branch**: `feature/[feature-name]/bolt-3-[description]`
**Depends on**: Bolt 1, Bolt 2

### Tasks

- [ ] T009: [Task description]
- [ ] T010: [Task description]
- [ ] T011: [Task description]
- [ ] T012: Integration tests

### Acceptance Criteria

- [ ] AC5: [Measurable criterion]
- [ ] AC6: [Measurable criterion]

### Quality Gates

- [ ] Linting passes
- [ ] All tests pass (unit + integration, ≥80% coverage)
- [ ] No security vulnerabilities
- [ ] Architecture compliance
- [ ] API contracts validated

---

## Summary

| Bolt | Tasks | Estimated | Status |
|------|-------|-----------|--------|
| Bolt 1 | T001-T004 | [X] days | ⬜ Planned |
| Bolt 2 | T005-T008 | [X] days | ⬜ Planned |
| Bolt 3 | T009-T012 | [X] days | ⬜ Planned |
| **Total** | **12 tasks** | **[X] days** | |
