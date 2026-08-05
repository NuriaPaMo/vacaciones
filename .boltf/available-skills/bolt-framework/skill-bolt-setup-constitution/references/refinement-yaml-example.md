# Refinement YAML Example

This document provides a complete example of a scope refinement YAML file and the resulting final constitution, demonstrating how different decision values affect the output.

## Overview

This example shows a `backend-refinement.yaml` file with 5 articles, each demonstrating a different decision type:

- ✅ **`include`** - Original article included as-is
- ✅ **`modified`** - Modified version included (original discarded)
- ❌ **`exclude`** - Article not needed for this project
- ❌ **`skip`** - Article not applicable to this scope

## Backend Refinement YAML

This is what a completed scope refinement file looks like:

```yaml
# .boltf/memory/refinement-states/backend-refinement.yaml
scope: backend
status: completed
total_articles: 10
articles:
  # ✅ INCLUDED: decision='include'
  - number: 'III'
    title: 'Tech Stack'
    criticality: HIGH
    status: refined
    content: |
      # Article III — Tech Stack
      - Language: C# (.NET 10)
      - Framework: ASP.NET Core Minimal APIs
      - Database: PostgreSQL
    decision: include
    reason: 'Approved default .NET stack for backend'
    decided_at: '2026-03-04 10:23:45'

  # ✅ INCLUDED: decision='modified' (uses modified_content, NOT original)
  - number: 'V'
    title: 'Code Quality'
    criticality: MEDIUM
    status: refined
    content: |
      # Article V — Code Quality
      - Coverage: 80%
      - Mutation: 70%
    decision: modified
    modified_content: |
      # Article V — Code Quality (Enhanced)
      - Unit Test Coverage: 85%
      - Integration Test Coverage: 75%
      - Mutation Score: 75%
      - Static Analysis: SonarQube with Quality Gate
    reason: 'Increased thresholds and added static analysis per team standards'
    decided_at: '2026-03-04 10:25:12'

  # ❌ EXCLUDED: decision='exclude'
  - number: 'VII'
    title: 'API Versioning Strategy'
    criticality: MEDIUM
    status: refined
    content: |
      # Article VII — API Versioning
      - Versioning: URL-based (e.g., /api/v1/)
      - Deprecation: 6-month notice period
    decision: exclude
    reason: 'Project uses single-version API, versioning not needed at this stage'
    decided_at: '2026-03-04 10:26:30'

  # ✅ INCLUDED: decision='include' (LOW criticality auto-approved)
  - number: 'IX'
    title: 'Logging Standards'
    criticality: LOW
    status: refined
    content: |
      # Article IX — Logging
      - Framework: Serilog
      - Levels: Debug, Info, Warning, Error, Fatal
      - Structured logging: JSON format
    decision: include
    reason: 'Auto-approved: standard logging configuration'
    decided_at: '2026-03-04 10:27:15'

  # ❌ EXCLUDED: decision='skip'
  - number: 'XII'
    title: 'Mobile App Guidelines'
    criticality: LOW
    status: refined
    content: |
      # Article XII — Mobile Development
      - Platform: React Native
      - Offline support: Required
    decision: skip
    reason: 'Not applicable: backend-only project, no mobile app'
    decided_at: '2026-03-04 10:28:00'

# Summary: 3 included, 2 excluded
# Final constitution will contain ONLY articles III, V (modified), and IX
```

## Resulting Final Constitution

When the constitution is generated from the above refinement YAML, it includes **only** the articles with `decision='include'` or `decision='modified'`:

```markdown
# Final Constitution

This constitution contains only articles explicitly approved during refinement.

# Scope: backend

# Article III — Tech Stack

- Language: C# (.NET 10)
- Framework: ASP.NET Core Minimal APIs
- Database: PostgreSQL

# Article V — Code Quality (Enhanced)

- Unit Test Coverage: 85%
- Integration Test Coverage: 75%
- Mutation Score: 75%
- Static Analysis: SonarQube with Quality Gate

# Article IX — Logging

- Framework: Serilog
- Levels: Debug, Info, Warning, Error, Fatal
- Structured logging: JSON format

---

## Constitution Metadata

- **Generated**: 2026-03-04 10:30:00
- **Source**: Merged refinement from 1 scopes
- **Articles Included**: 3
- **Articles Excluded**: 2
- **Total Reviewed**: 5

_Only articles with decision='include' or decision='modified' are present in this constitution._
```

## Key Observations

### What Gets Included

| Article     | Decision   | Included? | Content Source       | Reason                          |
| ----------- | ---------- | --------- | -------------------- | ------------------------------- |
| Article III | `include`  | ✅ Yes    | Original content     | Tech stack approved as-is       |
| Article V   | `modified` | ✅ Yes    | **Modified content** | Enhanced with higher thresholds |
| Article IX  | `include`  | ✅ Yes    | Original content     | Auto-approved (LOW criticality) |

### What Gets Excluded

| Article     | Decision  | Included? | Reason                                                   |
| ----------- | --------- | --------- | -------------------------------------------------------- |
| Article VII | `exclude` | ❌ No     | API versioning not needed for single-version API         |
| Article XII | `skip`    | ❌ No     | Mobile guidelines not applicable to backend-only project |

### Important Notes

1. **Modified Content Takes Precedence**: Article V uses `modified_content`, NOT the original `content` field. The original thresholds (80%/70%) are completely discarded in favor of the enhanced values (85%/75%/75%).

2. **Articles VII and XII Do Not Appear**: Despite being in the refinement YAML with full content, these articles are completely omitted from the final constitution due to their `exclude` and `skip` decisions.

3. **Metadata Tracking**: The final constitution includes statistics showing exactly how many articles were included vs. excluded, providing transparency into the refinement process.

4. **Focused Constitution**: The result is a concise, project-specific constitution (3 articles) instead of a bloated document with unnecessary boilerplate (would have been 5 articles if nothing was excluded).

## Use Cases by Decision Type

### `include` - Accept Default Recommendation

Use when the scope constitution's article is appropriate as-is:

- Standard tech stack choices that match team preferences
- Low-criticality best practices (logging, formatting)
- Generic guidelines that apply universally

### `modified` - Customize to Project Needs

Use when the article concept is good but details need adjustment:

- Increasing/decreasing thresholds (coverage, performance metrics)
- Adding project-specific requirements
- Enhancing with additional constraints or tools

### `exclude` - Not Needed for This Project

Use when an article doesn't apply to your project type:

- Features not in scope (e.g., versioning for single-version APIs)
- Technologies not used (e.g., GraphQL when using REST)
- Practices that don't fit project size/complexity

### `skip` - Not Applicable to This Scope

Use when an article is for a different scope:

- Mobile guidelines in a backend-only project
- Frontend patterns in a backend constitution
- Cloud-specific articles in an on-prem deployment

## Validation Checklist

After generating the final constitution:

- ✅ **All `include` articles present** - Verify original content is intact
- ✅ **All `modified` articles use modified content** - Check that modifications are applied
- ✅ **No `exclude` articles present** - Confirm excluded articles are omitted
- ✅ **No `skip` articles present** - Confirm skipped articles are omitted
- ✅ **Metadata accurate** - Counts match actual articles in constitution
- ✅ **Target length achieved** - Typically 200-500 lines for focused constitution
