---
name: session-efficiency
description: "Mandatory rules for token cost reduction: auto-compact sessions every 30 turns, delegate multi-file research to subagents."
version: 1.0.0
triggers:
  - session efficiency
  - token cost
  - auto-compact
  - research delegation
  - context management
---

# Session Efficiency

## Mandatory Rules

### Auto-compact
After completing turn 30 (and every 30 turns thereafter), compact the session
before processing the next request. If the task is clearly independent of current
context, start a new session instead of continuing.

### Research delegation
When a task requires reading **3+ files** to understand a flow or dependency chain:
1. Do NOT read them in the main context.
2. Spawn an explore/research subagent with a focused question.
3. The subagent must return a **summary** (not raw content).
4. Act on the summary. Never re-read files the subagent already reported.

**Exceptions:** single-file reads, files already in context, files you're about to edit.

## When to use
Always. These rules apply to every session regardless of task.
