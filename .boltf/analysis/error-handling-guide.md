# Error Handling & Recovery Guide

> **Reference Document for @Bolt Constitution Agent**
> Detailed error scenarios and recovery procedures

---

## 1. Session Interruption & Recovery

### Scenario: Interrupted Refinement Session

**Detection**: Agent detects `refinement-state.yaml` with `status: "in_progress"`

**Recovery Dialog**:

```markdown
## 🔄 Session Recovery Detected

**Session Details**:

- Started: {started_at}
- Last Activity: {last_updated}
- Duration: {session_duration}

**Progress Saved**:

- ✅ Phase 2A: CRITICAL ({X}/{Y} completed)
- 🔄 Phase 2B: IMPORTANT ({A}/{B} - interrupted here)

**Last Saved Decision**: {question_text} → {user_choice}

**Recovery Options**:

- **A) Resume** from question {N+1}
- **B) Review** decisions first
- **C) Start over** (⚠️ discard progress)
- **D) Exit** (keep state for later)

**Your choice?** (A/B/C/D)
```

---

## 2. State File Corruption

### Detection: YAML parse error or invalid structure

**Recovery Steps**:

1. **Check backup**: `.boltf/memory/refinement-state.yaml.backup`
2. **Check legacy ledger**: `refinement-ledger.yaml`
3. **Offer options**:

```markdown
## ⚠️ State File Corruption

**Corrupt File**: refinement-state.yaml

**Recovery Attempts**:

1. Backup file: [✓ Found / ✗ Missing]
2. Legacy ledger: [✓ Valid / ✗ Missing]

**Options**:

- **A) Restore from backup** (lose last decision)
- **B) Rebuild from ledger** (lose metadata)
- **C) Start fresh** (lose all progress)

**Recommended**: {based on availability}

**Your choice?**
```

---

## 3. Context Window Limits

### Detection: Context usage > 85%

**Action**:

```markdown
## ⚠️ Context Window Alert

**Current State**: {completed}/{total} decisions
**Context Usage**: {percentage}%

**Options**:

- **A) Checkpoint & fresh start** (safest)
- **B) Compress history** (risky)
- **C) Continue** (may fail)

**Recommendation**: A (no data loss)

**Your choice?**
```

**If (A)**:

1. Save final checkpoint
2. Exit with "Resume instructions"
3. User invokes agent again → loads checkpoint → fresh context

---

## 4. Network/Connectivity Issues

### Scenario: Network drop during tool call

**Action**:

```markdown
## ⚠️ Network Error

**Failed Operation**: {tool_name}
**Last Save**: Question {N} ({timestamp})

**Options**:

- **A) Retry** operation
- **B) Skip** question (mark deferred)
- **C) Exit** and resume later

**Your choice?**
```

---

## 5. Missing Prerequisites

### Missing scopes.yaml

```markdown
❌ **ERROR**: Configuration Not Found

Missing: `.boltf/scopes.yaml`

**Fix**: Run Init.ps1 first:

- PowerShell: `.\Init.ps1 -OutputDirectory ./project -ProjectType green`
- Bash: `./init.sh`

Then invoke @Bolt Constitution again.
```

### Invalid Scope Manifest

```markdown
❌ **ERROR**: Invalid Scope Configuration

Scope: {scope-name}
Issue: {description}

**Fix Options**:

1. Remove scope from scopes.yaml
2. Fix scope.yaml (validate YAML syntax)
3. Contact support (if framework scope)
```

### Script Execution Failure

```markdown
❌ **ERROR**: Provisioning Failed

**Error**: {error_message}
**Failed Step**: {step_name}

**Troubleshooting**:

1. Check error details above
2. Verify file permissions
3. Check disk space

**Recovery**:

- Retry with `-Verbose` flag
- Try dry-run to diagnose
- Start fresh (delete .boltf/ and .github/)
```

---

## 6. Manual Checkpoint Creation

### User Request: "Save my progress"

**Response**:

```markdown
## 💾 Checkpoint Saved

**Session State**:

- Phase: {phase}
- Completed: {N} of {total}
- Last decision: {id}

**Saved Files**:

- ✅ refinement-state.yaml
- ✅ refinement-ledger.yaml

**To Resume**:

1. Open VS Code
2. Invoke @Bolt Constitution
3. Choose "Resume"

Progress: {percentage}%
Estimated remaining: {time}

You can close VS Code safely! 👍
```

---

## Agent Implementation

### Pre-Flight Checks (Agent Start)

```python
# 1. State Detection
if exists("refinement-state.yaml"):
    state = load_state()

    if state.current_state.can_resume:
        # Show resume dialog
        present_recovery_options(state)
    else:
        # State complete, proceed normally
        proceed_to_phase_3_or_4()
else:
    # Fresh start
    start_phase_1()

# 2. Prerequisites Check
if not exists("scopes.yaml"):
    show_error_missing_prerequisites()
    exit()

if not exists("constitution.md"):
    show_error_missing_prerequisites()
    exit()
```

### During Refinement (Phase 2)

```python
# After each decision save
try:
    SaveStateAtomic(state_file, state)
except CorruptionError:
    # Restore from backup
    restore_from_backup()
    retry_save()

# Context monitoring
if context_usage() > 0.85:
    show_context_warning()
    offer_checkpoint_and_exit()
```

---

## Recovery Success Criteria

✅ **Session Recovery**: Resume from exact question, 0 decisions lost
✅ **Corruption Recovery**: Restore from backup, lose max 1 decision
✅ **Context Limit**: Checkpoint & fresh start, no data loss
✅ **Network Error**: Retry or defer, progress preserved
✅ **Prerequisites Missing**: Clear error with fix instructions

---

**Version**: 1.0.0
**Last Updated**: 2026-03-01
