# Bolt Framework — Handoff Matrix

> Defines valid and invalid handoff paths between Bolt Framework agents.
> Use this matrix to validate handoffs in agent frontmatter.

---

## Rules

1. **Bolt Framework** (orchestrator) can hand off to ANY agent ✅
2. **No self-handoffs** — an agent must NEVER hand off to itself ❌
3. **No circular chains** — A → B → C → A is invalid ❌
4. **No duplicate handoffs** — don't have multiple handoffs to the same agent with similar prompts ❌
5. **Respect lifecycle order** — don't skip phases without justification
6. **Each handoff needs context** — include prompt with what to do

---

## Orchestrator

### FROM: Bolt Framework → TO: Any

| Target Agent          | Valid | Reason                            |
| --------------------- | ----- | --------------------------------- |
| Any specialized agent | ✅    | Orchestrator role — routes to all |

---

## INCEPTION Phase

### FROM: Bolt Constitution

| Target Agent   | Valid | Reason                                     |
| -------------- | ----- | ------------------------------------------ |
| Bolt Clarify   | ✅    | Resolve ambiguities before ratifying       |
| Bolt Feature   | ✅    | Start defining features after constitution |
| Bolt Templates | ✅    | Generate project templates                 |

### FROM: Bolt Clarify

| Target Agent      | Valid | Reason                                |
| ----------------- | ----- | ------------------------------------- |
| Bolt Constitution | ✅    | Apply clarifications to constitution  |
| Bolt Feature      | ✅    | Clarified requirements → feature spec |
| Bolt Specify      | ✅    | Clarified → detailed spec             |

---

## DISCOVERY Phase

### FROM: Bolt Feature

| Target Agent   | Valid | Reason                                  |
| -------------- | ----- | --------------------------------------- |
| Bolt Use Case  | ✅    | Detail use cases from stories           |
| Bolt Gherkin   | ✅    | BDD scenarios from acceptance criteria  |
| Bolt DDD       | ✅    | Domain model from feature context       |
| Bolt Plan      | ✅    | Implementation plan from spec           |
| Bolt Specify   | ✅    | Detailed specification                  |
| Bolt Implement | ✅    | Direct implementation (simple features) |
| Bolt Status    | ❌    | Not related to feature creation         |
| Bolt Ops       | ❌    | Too early in lifecycle                  |

### FROM: Bolt Plan

| Target Agent   | Valid | Reason                             |
| -------------- | ----- | ---------------------------------- |
| Bolt Tasks     | ✅    | Breakdown plan into Bolt tasks     |
| Bolt Analyze   | ✅    | Verify plan consistency with specs |
| Bolt Architect | ✅    | Validate architecture decisions    |
| Bolt Implement | ❌    | Must go through Tasks first        |
| Bolt Release   | ❌    | Too early in lifecycle             |

### FROM: Bolt Tasks

| Target Agent        | Valid | Reason                         |
| ------------------- | ----- | ------------------------------ |
| Bolt Implement      | ✅    | Start implementing tasks       |
| Bolt Plan           | ❌    | Tasks come FROM plan, not back |

### FROM: Bolt Specify

| Target Agent | Valid | Reason                   |
| ------------ | ----- | ------------------------ |
| Bolt Feature | ✅    | Refine feature from spec |
| Bolt Gherkin | ✅    | BDD from spec            |
| Bolt Plan    | ✅    | Plan from spec           |

### FROM: Bolt Use Case

| Target Agent | Valid | Reason              |
| ------------ | ----- | ------------------- |
| Bolt Gherkin | ✅    | BDD from use cases  |
| Bolt Plan    | ✅    | Plan from use cases |
| Bolt Feature | ✅    | Refine feature      |

### FROM: Bolt Gherkin

| Target Agent | Valid | Reason                          |
| ------------ | ----- | ------------------------------- |
| Bolt Testing | ✅    | Step definitions from scenarios |
| Bolt Feature | ✅    | Refine feature from scenarios   |
| Bolt Plan    | ✅    | Plan informed by BDD            |

### FROM: Bolt DDD

| Target Agent   | Valid | Reason                         |
| -------------- | ----- | ------------------------------ |
| Bolt Architect | ✅    | Architecture from domain model |
| Bolt Feature   | ✅    | Refine features from domain    |
| Bolt Plan      | ✅    | Plan from domain model         |

---

## CONSTRUCTION Phase

### FROM: Bolt Implement

| Target Agent | Valid | Reason                                  |
| ------------ | ----- | --------------------------------------- |
| Bolt Testing | ✅    | Generate tests for implementation       |
| Bolt Analyze | ✅    | Verify consistency with spec            |
| Bolt Review  | ✅    | Code review                             |
| Bolt Feature | ❌    | Circular — impl doesn't create features |
| Bolt Plan    | ❌    | Already has plan                        |
| Bolt Release | ❌    | Must pass review first                  |

### FROM: Bolt Testing

| Target Agent   | Valid | Reason                            |
| -------------- | ----- | --------------------------------- |
| Bolt Implement | ✅    | TDD green phase — make tests pass |
| Bolt Gherkin   | ✅    | Generate BDD scenarios            |
| Bolt Review    | ✅    | Review test quality               |
| Bolt Analyze   | ✅    | Coverage analysis                 |
| Bolt Feature   | ❌    | Tests come from feature, not back |

### FROM: Bolt Review

| Target Agent   | Valid | Reason                           |
| -------------- | ----- | -------------------------------- |
| Bolt Implement | ✅    | Fix issues found in review       |
| Bolt Testing   | ✅    | Improve coverage                 |
| Bolt ADR       | ✅    | Document architectural decision  |
| Bolt Analyze   | ✅    | Deep analysis of findings        |
| Bolt Feature   | ❌    | Review doesn't create features   |
| Bolt Release   | ❌    | Should go through Bolt Framework |

### FROM: Bolt Analyze

| Target Agent   | Valid | Reason                |
| -------------- | ----- | --------------------- |
| Bolt Implement | ✅    | Fix inconsistencies   |
| Bolt Feature   | ✅    | Update spec if needed |
| Bolt Review    | ✅    | Quality findings      |

### FROM: Bolt ADR

| Target Agent   | Valid | Reason                    |
| -------------- | ----- | ------------------------- |
| Bolt Architect | ✅    | Architecture implications |
| Bolt Implement | ✅    | Apply decision            |

### FROM: Bolt Architect

| Target Agent   | Valid | Reason                         |
| -------------- | ----- | ------------------------------ |
| Bolt ADR       | ✅    | Document architecture decision |
| Bolt Plan      | ✅    | Inform plan with architecture  |
| Bolt DDD       | ✅    | Domain modeling                |
| Bolt Implement | ✅    | Guide implementation           |

---

## TRANSITION Phase

### FROM: Bolt Release

| Target Agent | Valid | Reason                 |
| ------------ | ----- | ---------------------- |
| Bolt CI/CD   | ✅    | Pipeline configuration |
| Bolt Ops     | ✅    | Deployment operations  |
| Bolt Status  | ✅    | Release status update  |

### FROM: Bolt CI/CD

| Target Agent | Valid | Reason                    |
| ------------ | ----- | ------------------------- |
| Bolt Release | ✅    | Release process           |
| Bolt Ops     | ✅    | Deployment                |
| Bolt Testing | ✅    | Pipeline test integration |

---

## PRODUCTION Phase

### FROM: Bolt Ops

| Target Agent    | Valid | Reason                              |
| --------------- | ----- | ----------------------------------- |
| Bolt Improve    | ✅    | Identify improvements from ops data |
| Bolt Postmortem | ✅    | Incident analysis                   |
| Bolt Status     | ✅    | Operational status                  |
| Bolt Release    | ✅    | New deployment needed               |
| Bolt Monitoring | ✅    | Configure monitoring                |
| Bolt Feature    | ❌    | Ops doesn't create features         |

### FROM: Bolt Status

| Target Agent   | Valid | Reason                    |
| -------------- | ----- | ------------------------- |
| Bolt Analyze   | ✅    | Deep analysis             |
| Bolt Improve   | ✅    | Improvement opportunities |
| Bolt Alignment | ✅    | Check alignment           |
| Bolt Ops       | ✅    | Operational health        |
| Bolt Implement | ❌    | Status is read-only       |

### FROM: Bolt Improve

| Target Agent   | Valid | Reason                     |
| -------------- | ----- | -------------------------- |
| Bolt Feature   | ✅    | Improvement → new feature  |
| Bolt Implement | ✅    | Apply improvement          |
| Bolt Analyze   | ✅    | Analyze improvement impact |

### FROM: Bolt Alignment

| Target Agent | Valid | Reason                     |
| ------------ | ----- | -------------------------- |
| Bolt Improve | ✅    | Misalignment → improvement |
| Bolt Status  | ✅    | Alignment status           |
| Bolt Analyze | ✅    | Deep alignment analysis    |

### FROM: Bolt Monitoring

| Target Agent | Valid | Reason                |
| ------------ | ----- | --------------------- |
| Bolt Ops     | ✅    | Alert → operations    |
| Bolt Improve | ✅    | Metrics → improvement |

---

## RETIREMENT Phase

### FROM: Bolt Retire

| Target Agent    | Valid | Reason                     |
| --------------- | ----- | -------------------------- |
| Bolt Ops        | ✅    | Decommissioning operations |
| Bolt Status     | ✅    | Retirement status          |
| Bolt Postmortem | ✅    | Lessons learned            |

### FROM: Bolt Postmortem

| Target Agent | Valid | Reason                 |
| ------------ | ----- | ---------------------- |
| Bolt Improve | ✅    | Lessons → improvements |
| Bolt ADR     | ✅    | Document decisions     |

---

## Cross-Phase Agents

### FROM: Bolt Security

| Target Agent      | Valid | Reason                     |
| ----------------- | ----- | -------------------------- |
| Bolt Constitution | ✅    | Update security standards  |
| Bolt Implement    | ✅    | Fix vulnerabilities        |
| Bolt Testing      | ✅    | Security test suites       |
| Bolt Review       | ✅    | Security review findings   |
| Bolt Security     | ❌    | **SELF-HANDOFF — INVALID** |

### FROM: Bolt Dependencies

| Target Agent      | Valid | Reason                      |
| ----------------- | ----- | --------------------------- |
| Bolt Implement    | ✅    | Install dependencies        |
| Bolt Security     | ✅    | Check dependency security   |
| Bolt Constitution | ✅    | Update allowed dependencies |

### FROM: Bolt Docs

| Target Agent | Valid | Reason                     |
| ------------ | ----- | -------------------------- |
| Bolt ADR     | ✅    | Architecture documentation |
| Bolt Feature | ✅    | Feature documentation      |

### FROM: Bolt Templates

| Target Agent      | Valid | Reason                    |
| ----------------- | ----- | ------------------------- |
| Bolt Constitution | ✅    | Template for constitution |
| Bolt Feature      | ✅    | Template for features     |
| Bolt Implement    | ✅    | Code templates            |

---

## Anti-Patterns ❌

| Anti-Pattern          | Example                                 | Why Invalid                                |
| --------------------- | --------------------------------------- | ------------------------------------------ |
| **Self-handoff**      | Security → Security                     | Infinite loop, no progress                 |
| **Circular chain**    | Plan → Tasks → Implement → Plan         | Never terminates                           |
| **Phase skip**        | Discovery → Production                  | Skips Construction entirely                |
| **Duplicate handoff** | Two handoffs to same agent, same prompt | Confusing, redundant                       |
| **Reverse flow**      | Testing → Feature                       | Tests validate features, don't create them |
| **Premature release** | Implement → Release                     | Must pass review and quality gates first   |
