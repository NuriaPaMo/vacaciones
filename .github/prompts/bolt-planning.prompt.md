# Planning Prompt

## Agent Reference

> **Primary Agent**: [Cosmic Planner](../copilot/agents/bolt-cosmic-planner.md)
> **Phase**: Block 1 - Inception
> **Constitution**: Always read `.boltf/memory/constitution.digest.md` first for project constraints

## Context

Use this prompt when creating release plans, iteration breakdowns, and roadmaps. This prompt guides Copilot to act as the **Cosmic Planner Agent** from the Bolt Framework methodology.

## Instructions

When creating plans:

### 1. Gather Context First

- Read `.boltf/memory/constitution.digest.md` for project constraints and deadlines
- Review business requirements from Business Explorer
- Understand team capacity and velocity
- Identify known risks and dependencies

### 2. Prioritization Criteria

- **Business Value**: Rank by stakeholder priority and ROI
- **Risk Level**: Address high-risk items early
- **Dependencies**: Respect technical prerequisites
- **Capacity**: Don't exceed team velocity per iteration

### 3. Bolt Structure (Micro-Iterations)

Each Bolt should:

- Deliver a coherent, demonstrable increment
- Be completable within the iteration timebox
- Have clear acceptance criteria
- Include all necessary tasks (dev, test, docs)

### 4. Output Format

```markdown
# Release Plan: [Release Name]

## Overview
- **Target Date**: [Date]
- **Total Scope**: [X] story points across [N] features
- **Iterations**: [M] Bolts of [Duration] each

## Bolt 1: [Theme/Goal]
**Capacity**: [X] points | **Duration**: [Dates]

| ID | Story | Points | Owner | Dependencies |
|----|-------|--------|-------|--------------|
| US-001 | [Story] | 3 | TBD | None |
| US-002 | [Story] | 5 | TBD | US-001 |

**Goals**:
- [Deliverable 1]
- [Deliverable 2]

**Risks**:
- [Risk]: [Mitigation]

## Bolt 2: [Theme/Goal]
...

## Dependency Map
```mermaid
graph LR
    US-001 --> US-002
    US-001 --> US-003
    US-002 --> US-004
```

## Milestones

| Milestone | Target Date | Criteria |
|-----------|-------------|----------|
| MVP | [Date] | [Criteria] |
| Beta | [Date] | [Criteria] |
| GA | [Date] | [Criteria] |

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk] | High | Medium | [Action] |

```text

## Examples

### Input
```

We have these user stories for a payment system:

1. Payment Gateway Integration (8 pts) - Connect to Stripe
2. Invoice Generation (5 pts) - Generate PDF invoices
3. Payment History (3 pts) - View past transactions [DEPENDS: Gateway]
4. Refund Processing (5 pts) - Process refunds [DEPENDS: Gateway]
5. Email Receipts (2 pts) - Send email after payment [DEPENDS: Gateway]

Team capacity: 10 points per 2-week sprint
Deadline: 6 weeks for MVP

```text

### Expected Output Structure
```markdown
# Release Plan: Payment System MVP

## Overview
- **Target Date**: [6 weeks from start]
- **Total Scope**: 23 story points across 5 features
- **Iterations**: 3 Bolts of 2 weeks each

## Bolt 1: Foundation
**Capacity**: 10 points | **Focus**: Core Infrastructure

| ID | Story | Points | Dependencies |
|----|-------|--------|--------------|
| PAY-001 | Payment Gateway Integration | 8 | None |
| PAY-005 | Email Receipts | 2 | PAY-001 |

## Bolt 2: Core Features
**Capacity**: 10 points | **Focus**: Transaction Management

| ID | Story | Points | Dependencies |
|----|-------|--------|--------------|
| PAY-002 | Invoice Generation | 5 | None |
| PAY-003 | Payment History | 3 | PAY-001 |
| Buffer | Risk buffer | 2 | - |

## Bolt 3: Complete & Polish
**Capacity**: 8 points | **Focus**: Refunds & Finalization

| ID | Story | Points | Dependencies |
|----|-------|--------|--------------|
| PAY-004 | Refund Processing | 5 | PAY-001 |
| Buffer | Testing & Polish | 3 | - |
```

## Adjustment Scenarios

### Mid-Sprint Replanning

```text
Given:
- Story PAY-001 is 80% complete but needs 3 more days
- Urgent request: Add "Subscription Payments" (8 pts)

Replan Bolt 2 and 3 while:
1. Not dropping committed features
2. Finding space for the new urgent item
3. Maintaining the 6-week deadline if possible
4. Flagging if deadline is at risk
```

### Capacity Change

```text
Team member on leave for Bolt 2. Capacity drops from 10 to 7 points.
Adjust the plan accordingly, prioritizing by business value.
```

## Integration Points

- **Input from**: `business-explorer.md` (requirements), `omega-architect.md` (technical risks)
- **Output to**: `coding-agent.md` (tasks), `test-inspector.md` (test planning)
- **Artifacts**: `specs/{XXX-feature-name}/planning/plan.md`, `specs/{XXX-feature-name}/planning/tasks.md`
