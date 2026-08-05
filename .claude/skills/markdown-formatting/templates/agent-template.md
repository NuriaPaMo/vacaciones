---
description: '[Brief description of what this agent does]'
model: claude-sonnet-4
tools:
  - edit/editFiles
  - search/codebase
  - github
---

# [Agent Name]

[One-line description of the agent's expertise and role]

## Mission

[Detailed description of the agent's primary purpose and what it helps users accomplish]

## Expertise

This agent specializes in:

- [Domain area 1]
- [Domain area 2]
- [Domain area 3]

## Workflow

### 1. [First Phase Name]

[Description of what happens in this phase]

**Actions:**

- [Action 1]
- [Action 2]

**Artifacts:**

- [What gets produced]

### 2. [Second Phase Name]

[Description of what happens in this phase]

**Questions to ask:**

1. [Question 1]
2. [Question 2]

### 3. [Third Phase Name]

[Description of what happens in this phase]

**Validation checklist:**

- [ ] [Check 1]
- [ ] [Check 2]
- [ ] [Check 3]

## Guardrails

**DO:**

- ✅ [Thing to always do]
- ✅ [Another thing to do]

**DON'T:**

- ❌ [Thing to never do]
- ❌ [Another thing to avoid]

## Output Format

### [Output Type 1]

```[format]
[Example of the output format]
```

### [Output Type 2]

```[format]
[Example of another output format]
```

## Quality Standards

All outputs must meet these criteria:

- [ ] [Quality criterion 1]
- [ ] [Quality criterion 2]
- [ ] [Quality criterion 3]
- [ ] Follows Bolt Framework Methodology
- [ ] Passes validation checks
- [ ] Includes proper documentation

## Integration with Bolt Framework

### DISCOVERY Phase

[How this agent is used during Discovery]

### CONSTRUCTION Phase

[How this agent is used during Construction]

### TRANSITION Phase

[How this agent is used during Transition]

## Examples

### Example 1: [Use Case Name]

**User Request:**

```text
[What the user asks for]
```

**Agent Response:**

```text
[How the agent responds step by step]
```

**Result:**

```[format]
[The final artifact produced]
```

### Example 2: [Another Use Case]

**Scenario:** [Context]

**Process:**

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Output:** [Description of what gets created]

## Tools Usage

### edit/editFiles

Use when:

- [Specific situation 1]
- [Specific situation 2]

### search/codebase

Use when:

- [Specific situation 1]
- [Specific situation 2]

### github

Use when:

- [Specific situation 1]
- [Specific situation 2]

## Related Agents

- **[@AgentName1](../agent-name-1.agent.md)** - [Relationship description]
- **[@AgentName2](../agent-name-2.agent.md)** - [Relationship description]

## Related Skills

- **[skill-name](../../skills/skill-name/SKILL.md)** - [How it relates]

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2026-02-13 | Initial version | [Name] |

---

**Maintained by:** [Team/Person]  
**Last Updated:** [YYYY-MM-DD]
