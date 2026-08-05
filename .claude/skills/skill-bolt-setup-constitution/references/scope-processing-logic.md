# Active Scope Processing Logic

This document describes the detailed process for processing each active scope constitution file during Phase 2 of the constitution setup workflow.

- **Resumability:** Checking existing refinement state and resuming from checkpoints
- **Article Extraction:** Reading scope constitutions and extracting articles
- **Criticality Sorting:** Prioritizing articles (HIGH → MEDIUM → LOW)
- **Decision Making:** Handling user decisions based on criticality levels
- **Checkpoint Saves:** Saving state after each article decision
- **Completion Tracking:** Marking scopes as completed

**Key Decision Values:**

| Decision   | Included in Final Constitution? |
| ---------- | ------------------------------- |
| `include`  | ✅ Yes (original content)       |
| `modified` | ✅ Yes (modified content)       |
| `exclude`  | ❌ No                           |
| `skip`     | ❌ No                           |
| `null`     | ❌ No                           |

## Overview

For each active scope, the system:

1. Checks for existing refinement state
2. Extracts articles from the scope constitution
3. Sorts articles by criticality (HIGH → MEDIUM → LOW)
4. Iteratively refines each article with user decisions
5. Saves checkpoints after each decision

## Complete Processing Flow

```text
FOR EACH scope IN active_scopes:

  # Step 2.1: Check if scope already processed
  IF exists(.boltf/memory/refinement-states/{scope}-refinement.yaml):
    READ state from {scope}-refinement.yaml
    IF state.status == 'completed':
      SKIP to next scope
    ELSE:
      RESUME from last processed article

  # Step 2.2: Read scope constitution
  READ .boltf/memory/{scope}-constitution.md

  # Step 2.3: Initialize refinement state (if new)
  CREATE .boltf/memory/refinement-states/{scope}-refinement.yaml:
    scope: {scope}
    status: in-progress
    total_articles: [count from constitution]
    articles: []
    decisions: []

  # Step 2.4: Extract articles from scope constitution
  EXTRACT articles (Article I, Article II, etc.)
  FOR EACH article:
    ADD to {scope}-refinement.yaml:
      - number: "I"
        title: "Article Title"
        criticality: HIGH | MEDIUM | LOW
        status: pending
        content: "Article markdown content"

  # Step 2.5: Sort articles by criticality
  SORT articles: HIGH → MEDIUM → LOW
  UPDATE {scope}-refinement.yaml with sorted_articles

  # Step 2.6: Iteratively refine each article
  # CRITICAL: Decision values determine final constitution inclusion
  #   'include'  → Article WILL appear in final constitution (as-is)
  #   'modified' → Article WILL appear (with modifications)
  #   'exclude'  → Article WILL NOT appear in final constitution
  #   'skip'     → Article WILL NOT appear (deferred/not applicable)

  FOR EACH article IN sorted_articles:
    IF article.status == 'refined':
      SKIP to next article

    # Criticality-based handling
    IF article.criticality == HIGH:
      # High criticality: Explicit user decision required
      - Present article to user with full context
      - Explain implications for the project
      - Ask: "Include this article? [include/exclude/modify]"
      - IF user says 'modify':
          - Prompt for modifications
          - Store in article.modified_content
          - Set decision = 'modified'
      - ELSE IF user says 'include':
          - Set decision = 'include'
      - ELSE IF user says 'exclude':
          - Set decision = 'exclude'
      - Record decision with timestamp and reason

    ELSE IF article.criticality == MEDIUM:
      # Medium criticality: Agent recommends, user approves
      - Analyze article + generate recommendation
      - Present: "Recommendation: [include/modify/exclude] because [reason]"
      - Ask user: "Accept recommendation? [y/n/modify]"
      - IF user accepts:
          - Set decision = recommended value
      - ELSE IF user says 'modify':
          - Prompt for changes
          - Set decision = 'modified'
      - ELSE:
          - Ask for manual decision (include/exclude)
      - OFFER: "Apply this decision to all remaining MEDIUM articles? [y/N]"
          - IF yes: Set bulk_decision_medium = current_decision
      - Record decision

    ELSE IF article.criticality == LOW:
      # Low criticality: Auto-recommend, quick approval
      - Generate auto-recommendation (usually 'include' for low-impact)
      - Present: "Auto-recommendation: [include] - [brief reason]"
      - Ask: "Approve? [Y/n]"
      - IF user approves (or no response):
          - Set decision = 'include'
      - ELSE:
          - Ask for manual decision (include/exclude/modify)
      - OFFER: "Apply to all remaining LOW articles? [y/N]"
          - IF yes: Set bulk_decision_low = current_decision
      - Record decision

    # Checkpoint after EACH decision
    UPDATE {scope}-refinement.yaml:
      articles[current].status = 'refined'
      articles[current].decision = [user's choice: include|modified|exclude|skip]
      articles[current].decided_at = [timestamp]
      articles[current].reason = [brief reason]
      IF decision == 'modified':
        articles[current].modified_content = [user's modified version]
    SAVE FILE

    LOG INFO: "Article {article.number}: decision='{decision}' | Will appear in final: {decision IN ['include', 'modified']}"

  # Step 2.7: Mark scope as completed
  UPDATE {scope}-refinement.yaml:
    status: completed
    completed_at: [timestamp]
  SAVE FILE

  NEXT scope
```

## Decision Value Semantics

| Decision Value       | Meaning                                      | Included in Final Constitution? |
| -------------------- | -------------------------------------------- | ------------------------------- |
| `include`            | Accept article as-is from scope constitution | ✅ Yes (original content)       |
| `modified`           | Accept article with user modifications       | ✅ Yes (modified content)       |
| `exclude`            | Permanently reject article                   | ❌ No                           |
| `skip`               | Defer or not applicable                      | ❌ No                           |
| `null` / no decision | Not yet decided                              | ❌ No                           |

## Criticality Levels

**HIGH:** Requires explicit user decision. No defaults, no auto-recommendations.

**MEDIUM:** Agent recommends, user approves or modifies. Option for bulk decisions.

**LOW:** Auto-recommend with quick approval. Option for bulk decisions.

## Resumability

The refinement state file (`.boltf/memory/refinement-states/{scope}-refinement.yaml`) serves as a checkpoint system:

- **Status: `in-progress`** - Scope processing is incomplete; resume from last refined article
- **Status: `completed`** - Scope processing is done; skip to next scope

This allows interruption and resumption at any point without losing progress.
