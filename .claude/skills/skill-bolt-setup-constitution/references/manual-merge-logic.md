# Manual Merge Logic for Refinement YAMLs

This document describes the manual process for merging scope-specific refinement YAML files when custom processing is required.

## Process Overview

### Step 3.1: Collect all scope refinement files

```text
scope_yamls = [
  .boltf/memory/refinement-states/backend-refinement.yaml,
  .boltf/memory/refinement-states/frontend-refinement.yaml,
  .boltf/memory/refinement-states/cloud-platform-refinement.yaml
]
```

### Step 3.2: Merge into unified structure

```text
CREATE .boltf/memory/refinement-states/merged-refinement.yaml:
  scopes:
    - scope: backend
      articles: [from backend-refinement.yaml]
      decisions: [from backend-refinement.yaml]
    - scope: frontend
      articles: [from frontend-refinement.yaml]
      decisions: [from frontend-refinement.yaml]
    - scope: cloud-platform
      articles: [from cloud-platform-refinement.yaml]
      decisions: [from cloud-platform-refinement.yaml]

  # Summary stats
  total_scopes: 3
  total_articles: [sum of all articles]
  total_decisions: [sum of all decisions]
  merge_timestamp: [timestamp]
```

### Step 3.3: Detect conflicts (same article number across scopes)

```text
FOR EACH article_number:
  IF article appears in multiple scopes:
    # Flag for manual review
    ADD to merged-refinement.yaml:
      conflicts:
        - article: "Article III"
          scopes: [backend, frontend]
          resolution: pending
```

## When to Use Manual Merge

Use this manual process when:

- You need custom conflict resolution logic
- Automated merge scripts don't meet your requirements
- You want to understand the merge process in detail
- You're debugging merge issues

## Output Structure

The merged YAML should follow this structure:

```yaml
scopes:
  - scope: backend
    articles: [...]
    decisions: [...]
  - scope: frontend
    articles: [...]
    decisions: [...]
  - scope: cloud-platform
    articles: [...]
    decisions: [...]

total_scopes: 3
total_articles: [number]
total_decisions: [number]
merge_timestamp: [ISO timestamp]

# Optional: if conflicts detected
conflicts:
  - article: 'Article III'
    scopes: [backend, frontend]
    resolution: pending
```
