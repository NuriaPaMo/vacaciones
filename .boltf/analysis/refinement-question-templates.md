# Refinement Question Templates

> **Reference Document for @Bolt Constitution Agent**
> Contains detailed question templates for Phase 2 Interactive Refinement

---

## Template A: Single-Select Checkbox (Select ONE)

```markdown
## 🎯 Decision #{N} of {Total} - {Article} › {Section}

📍 **Location**: `constitution.master.md` Line {X}

**Question**: {Generated question from section title}

**Context**: {Section preamble explaining what this controls}

**Your Options**:

{FOR EACH option:}

- **{Label}**. {Option text}
  {If explanation exists: → {explanation}}

**Current/Default**: {If specified in master}

**Your choice?** (Type {labels} or 'keep')
```

### Example

```markdown
## 🎯 Decision #5 of 47 - Article III › Section 3.1: Backend Architecture Style

📍 **Location**: `constitution.master.md` Line 89

**Question**: What backend architecture style fits your project?

**Context**: This determines service boundaries, deployment strategy, and team organization. Impacts modularity, independence, and operational complexity.

**Your Options**:

- **A**. Microservices
  → Independent deployable services

- **B**. Modular Monolith
  → Single deployment, modular boundaries

- **C**. Traditional Monolith
  → Single deployment, layered

- **D**. Serverless
  → Azure Functions based

- **E**. Event-Driven / CQRS+ES
  → Commands, queries, event sourcing

**Current/Default**: (Not specified - you must choose)

**Your choice?** (A, B, C, D, E, skip, or stop)
```

---

## Template B: Yes/No Toggle

```markdown
## 🎯 Decision #{N} of {Total} - {Article} › {Section}: {Feature}

📍 **Location**: `constitution.master.md` Line {X}

**Question**: Enable {Feature}?

**Context**: {What this feature provides}

**Impact**:
✅ **If Enabled**: {Benefits, requirements}
⛔ **If Disabled**: {What you'll need instead}

**Current/Default**: {Yes/No}

**Enable?** (Yes/No/keep)
```

### Example

```markdown
## 🎯 Decision #18 of 47 - Article VI › Section 6.1: L1 In-Memory Cache

📍 **Location**: `constitution.master.md` Line 234

**Question**: Enable in-memory caching per service?

**Context**: IMemoryCache (.NET) / node-cache (Node.js) provides microsecond access times for frequently-read data.

**Impact**:
✅ **If Enabled**:

- Sub-millisecond response times
- Reduces database load
- Requires cache invalidation strategy

⛔ **If Disabled**:

- All requests hit database/distributed cache
- Simpler consistency model

**Current/Default**: Disabled

**Enable?** (Yes/No/keep)
```

---

## Template C: Numeric/Text Configuration

```markdown
## 🎯 Decision #{N} of {Total} - {Article} › {Section}: {Field}

📍 **Location**: `constitution.master.md` Line {X}

**Question**: Set {Field} value?

**Context**: {What this controls}

**Constraints**: {Valid range, format}

**Recommended Values**:

- {Value 1}: {Use case}
- {Value 2}: {Use case}
- {Value 3}: {Use case}

**Current/Default**: {value}

**Your value?** (Enter value or 'keep')
```

### Example

```markdown
## 🎯 Decision #31 of 47 - Article XIII › Section 13.1: Line Coverage Minimum

📍 **Location**: `constitution.master.md` Line 567

**Question**: Set minimum line coverage threshold?

**Context**: Enforced in CI/CD - blocks PR merge if below this value.

**Constraints**: 0-100%

**Recommended Values**:

- 60%: Lenient (legacy/brownfield)
- 80%: Standard (industry best practice) ⭐
- 90%: Strict (critical systems)

**Current/Default**: Not set

**Your value?** (Enter 60-100 or 'keep' for 80%)
```

---

## Usage in Agent

Agent should:

1. **Parse decision type** from constitution.master.md
2. **Select appropriate template** (A, B, or C)
3. **Inject context** from parsed decision metadata
4. **Present to user** with progress indicators
5. **Save response** in refinement-state.yaml immediately

---

**Version**: 1.0.0
**Last Updated**: 2026-03-01
