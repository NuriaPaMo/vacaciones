# Constitution Building Logic

This document describes the process for generating the final constitution file from merged refinement decisions.

## Overview

The constitution building process transforms the merged refinement YAML (containing all scope decisions) into a concise, focused constitution file containing ONLY user-approved articles.

## Source and Output

- **Source:** `.boltf/memory/refinement-states/merged-refinement.yaml`
- **Output:** `.boltf/memory/constitution.md`

## Critical Filtering Rules

| Decision Value  | Action             | Content Source                           |
| --------------- | ------------------ | ---------------------------------------- |
| `include`       | ✅ Include article | Original content from scope constitution |
| `modified`      | ✅ Include article | Modified content (NOT original)          |
| `exclude`       | ❌ Skip article    | N/A                                      |
| `skip`          | ❌ Skip article    | N/A                                      |
| `pending`       | ❌ Skip article    | N/A                                      |
| `null` or empty | ❌ Skip article    | N/A                                      |

## Constitution Generation Process

```text
# Step 4.1: Start with constitution-init.md header (metadata only, NO articles)
READ .boltf/memory/constitution-init.md
EXTRACT header ONLY:
  - Project name
  - Generated timestamp
  - Practice
  - Active Scopes list
  - Project Type
DO NOT EXTRACT: Any article content from constitution-init.md

# Step 4.2: Filter and include ONLY approved articles
# Decision types and actions:
#   'include'   → Include original article content
#   'modified'  → Include modified_content (NOT original)
#   'exclude'   → SKIP completely (do not write)
#   'pending'   → SKIP completely (do not write)
#   null/empty  → SKIP completely (do not write)

CREATE .boltf/memory/constitution.md:

  # Header from constitution-init.md (metadata ONLY)
  WRITE [metadata block]
  WRITE "---"
  WRITE ""
  WRITE "# Final Constitution"
  WRITE ""
  WRITE "This constitution contains only articles explicitly approved during refinement."
  WRITE ""

  # Track statistics
  included_count = 0
  excluded_count = 0

  # For each scope
  FOR EACH scope IN merged-refinement.yaml.scopes:

    # Filter articles before writing scope header
    approved_articles = FILTER scope.articles WHERE
      decision IN ['include', 'modified']

    # Only write scope section if it has approved articles
    IF approved_articles.length > 0:

      WRITE "# Scope: {scope.name}"
      WRITE ""

      FOR EACH article IN approved_articles:

        # Validate decision before writing
        IF article.decision == 'include':
          # Use original article content
          WRITE article.content
          WRITE ""
          included_count++

        ELSE IF article.decision == 'modified':
          # Use modified content ONLY (discard original)
          IF article.modified_content IS NOT EMPTY:
            WRITE article.modified_content
            WRITE ""
            included_count++
          ELSE:
            # Fallback if modified_content is missing
            LOG WARNING: "Article {article.number} marked 'modified' but no modified_content"
            WRITE article.content
            WRITE "<!-- ⚠️  Marked as modified but changes not found -->"
            WRITE ""
            included_count++

        ELSE:
          # Safety catch: should never reach here due to filter
          LOG WARNING: "Article {article.number} has unexpected decision: {article.decision}"
          excluded_count++

      WRITE "---"
      WRITE ""

    ELSE:
      # Scope has no approved articles - skip entirely
      LOG INFO: "Scope '{scope.name}' has no approved articles - skipping section"

  # Footer with statistics
  WRITE "---"
  WRITE ""
  WRITE "## Constitution Metadata"
  WRITE ""
  WRITE "- **Generated**: [timestamp]"
  WRITE "- **Source**: Merged refinement from {total_scopes} scopes"
  WRITE "- **Articles Included**: {included_count}"
  WRITE "- **Articles Excluded**: {excluded_count}"
  WRITE "- **Total Reviewed**: {included_count + excluded_count}"
  WRITE ""
  WRITE "*Only articles with decision='include' or decision='modified' are present in this constitution.*"

# Step 4.3: Validate constitution length
constitution_size = GET FILE SIZE of constitution.md
constitution_lines = COUNT LINES in constitution.md

IF constitution_lines < 10:
  LOG WARNING: "Constitution is suspiciously short ({constitution_lines} lines)"
  LOG WARNING: "Verify that articles were properly approved during refinement"

IF constitution_lines > 2000:
  LOG WARNING: "Constitution is very long ({constitution_lines} lines)"
  LOG WARNING: "Consider reviewing which articles are truly necessary"

LOG INFO: "Final constitution: {included_count} articles, {constitution_lines} lines"

# Step 4.4: Generate provision report
CREATE .boltf/memory/provision-report.md:
  ## Constitution Refinement Report

  **Generated**: [timestamp]

  ### Summary
  - **Total Scopes Processed**: {total_scopes}
  - **Total Articles Reviewed**: {included_count + excluded_count}
  - **Articles Included**: {included_count}
  - **Articles Excluded**: {excluded_count}
  - **Inclusion Rate**: {(included_count / total) * 100}%
  - **Conflicts Detected**: {conflict_count}

  ### Per-Scope Breakdown
  FOR EACH scope:
    - **{scope.name}**: {scope.included}/{scope.total} articles included

  ### Final Constitution
  - **File**: .boltf/memory/constitution.md
  - **Size**: {constitution_lines} lines
  - **Status**: ✅ Generated successfully

  ### Next Steps
  1. Review final constitution for completeness
  2. Resolve any flagged conflicts
  3. Run `@Bolt Provisioner` to download resources
  4. Commit constitution to version control
```

## Design Principles

### 1. Metadata-Only Header

The final constitution header comes from `constitution-init.md` but includes ONLY metadata (project name, practice, scopes). No article content from the init file is carried over.

### 2. Content Source Priority

- **For `include` decisions:** Use original article content from scope constitution
- **For `modified` decisions:** Use `modified_content` field ONLY, discard original
- **Fallback:** If `modified_content` is missing, use original with warning comment

### 3. Scope Section Gating

A scope section is only written if it has at least one approved article. Empty scopes are skipped entirely to keep the constitution concise.

### 4. Length Validation

- **Too Short (< 10 lines):** Warning - likely missing content
- **Too Long (> 2000 lines):** Warning - may need pruning
- **Target Range:** 200-500 lines (focused and maintainable)

## Output Structure

```markdown
---
project: My Project
practice: full-stack
scopes: [backend, frontend, cloud-platform]
---

# Final Constitution

This constitution contains only articles explicitly approved during refinement.

# Scope: backend

## Article I: Backend Language

[Article content...]

## Article II: API Framework

[Article content...]

---

# Scope: frontend

## Article I: Frontend Framework

[Article content...]

---

## Constitution Metadata

- **Generated**: 2026-03-06T10:00:00Z
- **Source**: Merged refinement from 3 scopes
- **Articles Included**: 12
- **Articles Excluded**: 8
- **Total Reviewed**: 20

_Only articles with decision='include' or decision='modified' are present in this constitution._
```

## Why This Approach Matters

✅ **Prevents Information Overload** - Only approved articles, no generic boilerplate

✅ **Maintainable** - Focused constitution is easier to reference during development

✅ **Traceable** - Metadata shows exactly what was included/excluded

✅ **User-Driven** - Constitution reflects actual team choices, not defaults

✅ **Resumable** - Can regenerate constitution from merged YAML at any time
