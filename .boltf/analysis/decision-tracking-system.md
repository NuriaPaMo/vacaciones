# Decision Tracking System - Iterative Control Flow

> **Based on Claude's Extended Thinking Pattern**
> Implements incremental state persistence with resume capability

## Overview

The Decision Tracking System enables **iterative, resumable refinement** of the Bolt Framework constitution. Inspired by Claude's interleaved thinking pattern, this system:

- ✅ **Saves state after EVERY decision** (not just at phase end)
- ✅ **Enables resuming** from any interruption point
- ✅ **Maintains decision history** with full traceability
- ✅ **Supports graceful degradation** when context limits are reached

## File Structure

```text
.boltf/memory/
├── refinement-state.yaml       # Current state checkpoint (CRITICAL)
├── refinement-ledger.yaml      # Complete decision history
├── constitution.master.md      # Full unfiltered constitution
└── constitution.md             # Refined final constitution (generated at end)
```

## refinement-state.yaml Structure

```yaml
# State Checkpoint - Updated after EVERY decision
# Version: 1.0.0
# Last Updated: 2026-03-01T14:23:45Z

metadata:
  version: '1.0.0'
  project_path: 'F:/repos/test-bolt-framework'
  started_at: '2026-03-01T10:15:00Z'
  last_updated: '2026-03-01T14:23:45Z'
  agent_version: 'Bolt Constitution v2.0.0'

# Current execution state
current_state:
  phase: 'phase_2b_important' # phase_1_master | phase_2a_critical | phase_2b_important | phase_2c_lowprio | phase_3_final | phase_4_provision
  status: 'in_progress' # not_started | in_progress | completed | suspended
  current_question_index: 18 # Index of current question being asked
  total_questions: 65 # Total questions parsed from master
  can_resume: true # Can this session be resumed?

# Phase progress tracking
phases:
  phase_1_master:
    status: 'completed'
    started_at: '2026-03-01T10:15:00Z'
    completed_at: '2026-03-01T10:18:32Z'
    output_file: '.boltf/memory/constitution.master.md'
    checkpoint:
      scopes_merged: 3
      total_lines: 1847

  phase_2a_critical:
    status: 'completed'
    started_at: '2026-03-01T10:20:00Z'
    completed_at: '2026-03-01T11:45:23Z'
    checkpoint:
      total_questions: 17
      answered: 17
      skipped: 0
      last_decision_id: 'arch-cqrs-pattern'

  phase_2b_important:
    status: 'in_progress'
    started_at: '2026-03-01T11:50:00Z'
    completed_at: null
    checkpoint:
      total_questions: 35
      answered: 18
      skipped: 2
      last_decision_id: 'cache-l2-provider'
      next_decision_id: 'cache-l3-enabled'

  phase_2c_lowprio:
    status: 'not_started'
    checkpoint:
      total_questions: 13

  phase_3_final:
    status: 'not_started'

  phase_4_provision:
    status: 'not_started'

# Decision ledger (incremental append)
# This section is APPENDED after each decision
decisions:
  # Article II: Application Configuration
  - id: 'app-config-backend-language'
    timestamp: '2026-03-01T10:25:12Z'
    phase: 'phase_2a_critical'
    article: 'II'
    section: '2.1'
    criticality: 'critical'
    question: 'Backend Language & Runtime'
    line: 45
    type: 'single-select'
    options: ['C# / .NET', 'Node.js / TypeScript', 'Python / FastAPI']
    user_choice: 'C# / .NET'
    default_was: null
    reasoning: 'Team has .NET expertise, enterprise requirements'

  - id: 'app-config-dotnet-version'
    timestamp: '2026-03-01T10:26:05Z'
    phase: 'phase_2a_critical'
    article: 'II'
    section: '2.1'
    criticality: 'critical'
    question: '.NET Version'
    line: 47
    type: 'single-select'
    options: ['.NET 8 (LTS)', '.NET 10']
    user_choice: '.NET 10'
    default_was: null
    reasoning: 'Want latest features, will upgrade before LTS ends'

  - id: 'arch-backend-style'
    timestamp: '2026-03-01T10:35:18Z'
    phase: 'phase_2a_critical'
    article: 'III'
    section: '3.1'
    criticality: 'critical'
    question: 'Backend Architecture Style'
    line: 89
    type: 'single-select'
    options:
      [
        'Microservices',
        'Modular Monolith',
        'Traditional Monolith',
        'Serverless',
        'Event-Driven / CQRS+ES',
      ]
    user_choice: 'Modular Monolith'
    default_was: null
    reasoning: 'Balance between simplicity and modularity for 5-person team'

  # ... (17 total from phase_2a_critical)

  # Phase 2B decisions continue...
  - id: 'cache-l1-enabled'
    timestamp: '2026-03-01T12:10:45Z'
    phase: 'phase_2b_important'
    article: 'VI'
    section: '6.1'
    criticality: 'important'
    question: 'L1 - In-Memory Cache Enabled'
    line: 287
    type: 'yes-no'
    user_choice: true
    default_was: false
    reasoning: 'Performance requirement for read-heavy APIs'

  - id: 'cache-l1-ttl'
    timestamp: '2026-03-01T12:11:30Z'
    phase: 'phase_2b_important'
    article: 'VI'
    section: '6.1'
    criticality: 'low-prio'
    question: 'L1 Cache TTL Default (minutes)'
    line: 287
    type: 'numeric'
    user_choice: 15
    default_was: 10
    reasoning: 'Balance freshness with cache hit rate'
    depends_on: 'cache-l1-enabled'

  - id: 'cache-l2-provider'
    timestamp: '2026-03-01T14:23:45Z'
    phase: 'phase_2b_important'
    article: 'VI'
    section: '6.2'
    criticality: 'important'
    question: 'L2 - Distributed Cache Provider'
    line: 295
    type: 'single-select'
    options: ['Redis', 'Azure Cache for Redis', 'Memcached', 'None']
    user_choice: 'Azure Cache for Redis'
    default_was: null
    reasoning: 'Azure native, managed service'

  # NEXT QUESTION TO ASK:
  # - id: "cache-l3-enabled"
  #   phase: "phase_2b_important"
  #   article: "VI"
  #   section: "6.3"
  #   ... (not yet answered)

# Resume information
resume_info:
  can_resume: true
  resume_from_phase: 'phase_2b_important'
  resume_from_question: 19
  resume_instructions: |
    Resume Phase 2B (IMPORTANT decisions) at question 19/35.
    Last answered: cache-l2-provider (Azure Cache for Redis)
    Next: cache-l3-enabled (L3 - Database Cache)

# User preferences (learned during session)
user_preferences:
  prefers_detailed_explanations: true # User asked 'help' multiple times
  decision_speed: 'deliberate' # Average 2 minutes per decision
  uses_reasoning: true # Provides reasoning for choices
  skip_behavior: 'rare' # Only skipped 2/18 so far

# Summary statistics
statistics:
  total_decisions_parsed: 65
  decisions_answered: 20
  decisions_skipped: 2
  decisions_remaining: 43
  completion_percentage: 30.77
  estimated_time_remaining: '45 minutes'
  session_duration: '4 hours 8 minutes'
```

## Control Flow Pattern

### Standard Flow (No Interruptions)

```text
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Generate Master Constitution                       │
├─────────────────────────────────────────────────────────────┤
│ 1. Load scopes.yaml                                         │
│ 2. Merge all scope constitutions → constitution.master.md  │
│ 3. Save checkpoint: phase_1_master = completed             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2A: CRITICAL Decisions (Cannot Skip)                  │
├─────────────────────────────────────────────────────────────┤
│ FOR EACH critical decision (17 total):                     │
│   - Present question with context                          │
│   - Wait for user answer                                   │
│   - Validate response                                      │
│   - APPEND to refinement-state.yaml → decisions[]         │
│   - UPDATE current_question_index++                        │
│   - SAVE checkpoint (incremental)                          │
│ END                                                         │
│                                                             │
│ Save checkpoint: phase_2a_critical = completed             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2B: IMPORTANT Decisions (Can Skip with Defaults)      │
├─────────────────────────────────────────────────────────────┤
│ User chooses:                                               │
│   A) Answer all (continue iteration)                       │
│   B) Skip to Phase 2C (apply defaults to remaining)        │
│   C) Finish now (defaults for 2B + 2C)                     │
│                                                             │
│ IF (A):                                                     │
│   FOR EACH important decision (35 total):                  │
│     - Present question + default recommendation            │
│     - User can: answer | 'skip' this one | 'defaults-all' │
│     - APPEND to refinement-state.yaml                      │
│     - SAVE checkpoint                                      │
│   END                                                       │
│                                                             │
│ Save checkpoint: phase_2b_important = completed            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2C: LOW-PRIO Decisions (Safe to Postpone)            │
├─────────────────────────────────────────────────────────────┤
│ [Similar pattern to 2B]                                     │
│ Save checkpoint: phase_2c_lowprio = completed              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: Generate Final Constitution                        │
├─────────────────────────────────────────────────────────────┤
│ 1. Load refinement-state.yaml → decisions[]               │
│ 2. Transform to constitution.md (filtered, no checkboxes)  │
│ 3. Save checkpoint: phase_3_final = completed              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: Provision Resources (Optional)                     │
├─────────────────────────────────────────────────────────────┤
│ [Standard provisioning from scope.yaml]                    │
│ Save checkpoint: phase_4_provision = completed             │
└─────────────────────────────────────────────────────────────┘
```

### Resume Flow (After Interruption)

```text
┌─────────────────────────────────────────────────────────────┐
│ Agent Invoked: @Bolt Constitution                          │
├─────────────────────────────────────────────────────────────┤
│ 1. CHECK: Does .boltf/memory/refinement-state.yaml exist? │
│                                                             │
│    [NO]  → Start fresh (Phase 1)                          │
│    [YES] → Load state and present resume options          │
└─────────────────────────────────────────────────────────────┘
                          ↓ [YES]
┌─────────────────────────────────────────────────────────────┐
│ Resume Detected                                             │
├─────────────────────────────────────────────────────────────┤
│ Present session summary:                                    │
│                                                             │
│ "🔄 Resuming Previous Session                              │
│                                                             │
│ **Last Session**:                                          │
│ - Started: 2026-03-01 10:15 AM                            │
│ - Last Activity: 2026-03-01 2:23 PM                       │
│ - Duration: 4 hours 8 minutes                             │
│                                                             │
│ **Progress**:                                              │
│ - ✅ Phase 1: Master Constitution (completed)             │
│ - ✅ Phase 2A: CRITICAL decisions (17/17 answered)        │
│ - 🔄 Phase 2B: IMPORTANT decisions (18/35 answered)       │
│                                                             │
│ **Last Decision**:                                         │
│ - Article VI › Section 6.2                                 │
│ - Question: L2 - Distributed Cache Provider               │
│ - Answer: Azure Cache for Redis                           │
│                                                             │
│ **What's Next?**                                           │
│ - Resume at Question 19: L3 - Database Cache enabled      │
│ - Remaining: 17 IMPORTANT + 13 LOW-PRIO decisions         │
│ - Estimated time: ~45 minutes                             │
│                                                             │
│ **Options**:                                               │
│ A) Resume from where I left off                           │
│ B) Review previous decisions                              │
│ C) Start over (discard previous session)                  │
│ D) Skip to Phase 3 (use defaults for remaining)          │
│                                                             │
│ Your choice? (A/B/C/D)"                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Resume Actions                                              │
├─────────────────────────────────────────────────────────────┤
│ IF (A): Continue from question 19                         │
│   - Load current_question_index from state                │
│   - Continue Phase 2B iteration                           │
│                                                             │
│ IF (B): Show decision history                             │
│   - Display all decisions[].id with answers               │
│   - Allow changing specific decisions                     │
│   - Then return to (A)                                    │
│                                                             │
│ IF (C): Confirm data loss                                 │
│   - "⚠️ This will discard 20 decisions (4 hours work)"   │
│   - "Are you sure? (yes/no)"                              │
│   - If yes: Delete state, start Phase 1                  │
│                                                             │
│ IF (D): Finish with defaults                              │
│   - Apply smart defaults to remaining 30 decisions        │
│   - Jump to Phase 3                                       │
└─────────────────────────────────────────────────────────────┘
```

## Incremental Save Algorithm

**CRITICAL**: Save state **after EVERY decision**, not at phase end.

```python
def ask_question_and_save(question_id, question_data, state_file):
    """
    Ask one question, capture answer, save immediately.
    Implements incremental persistence pattern.
    """
    # 1. Present question to user
    answer = present_question(question_data)

    # 2. Validate response
    validated = validate_response(answer, question_data.constraints)

    # 3. Create decision record
    decision = {
        'id': question_id,
        'timestamp': now_iso8601(),
        'phase': current_phase,
        'article': question_data.article,
        'section': question_data.section,
        'criticality': question_data.criticality,
        'question': question_data.question_text,
        'line': question_data.line_number,
        'type': question_data.type,
        'options': question_data.options,
        'user_choice': validated,
        'default_was': question_data.default,
        'reasoning': get_user_reasoning() if user_provided else None
    }

    # 4. CRITICAL: Load current state
    state = load_yaml(state_file)

    # 5. Append decision (incremental)
    state['decisions'].append(decision)

    # 6. Update progress counters
    state['current_state']['current_question_index'] += 1
    state['current_state']['last_updated'] = now_iso8601()

    current_phase_key = state['current_state']['phase']
    state['phases'][current_phase_key]['checkpoint']['answered'] += 1
    state['phases'][current_phase_key]['checkpoint']['last_decision_id'] = question_id

    # 7. Calculate next question ID (for resume)
    next_question = get_next_question_id(question_id, all_questions)
    state['phases'][current_phase_key]['checkpoint']['next_decision_id'] = next_question

    # 8. SAVE IMMEDIATELY (atomic write)
    save_yaml_atomic(state_file, state)

    # 9. Return decision for in-memory processing
    return decision
```

## Atomic Save Implementation

**Prevent corruption during save**:

```powershell
function Save-RefinementStateAtomic {
    param(
        [string]$StateFile,
        [hashtable]$StateData
    )

    $tempFile = "$StateFile.tmp"
    $backupFile = "$StateFile.backup"

    try {
        # 1. Write to temp file first
        $StateData | ConvertTo-Yaml | Out-File -FilePath $tempFile -Encoding UTF8

        # 2. Validate temp file (YAML syntax)
        $null = Get-Content $tempFile | ConvertFrom-Yaml

        # 3. Backup current file (if exists)
        if (Test-Path $StateFile) {
            Copy-Item $StateFile $backupFile -Force
        }

        # 4. Atomic rename (Windows: ReplaceFile, Linux: rename)
        Move-Item $tempFile $StateFile -Force

        Write-Host "✓ State saved: $StateFile" -ForegroundColor Green

    } catch {
        # Restore from backup if corruption detected
        if (Test-Path $backupFile) {
            Copy-Item $backupFile $StateFile -Force
            Write-Warning "State restore from backup due to save error"
        }
        throw
    }
}
```

## Benefits

### 1. **Data Loss Prevention**

- Save after EVERY decision → max 1 decision lost on crash
- Backup file strategy → rollback on corruption
- Atomic writes → no partial saves

### 2. **Resume Capability**

- Interrupt at any point (coffee break, meeting, crash)
- Resume from exact question
- See progress summary before resuming

### 3. **Audit Trail**

- Every decision timestamped
- Reasoning capture (if user provides)
- Full history for retrospectives

### 4. **Context Management**

- If context window fills → checkpoint and continue
- Can split into multiple sessions automatically
- No "lost work" frustration

### 5. **User Experience**

- Long refinement sessions feel safe
- Can stop/continue without guilt
- Progress visibility (18/35 decisions)

## Usage Patterns

### Pattern 1: Continuous Refinement

```text
User starts Phase 2A → Answers 5 critical questions → Takes break
[STATE SAVED: 5/17 decisions]

User returns → Agent shows "Resume from question 6?" → Continue
[STATE SAVED: 17/17 complete]

Agent: "Phase 2A complete! Continue to Phase 2B?"
```

### Pattern 2: Interrupted Session

```text
User starts Phase 2B → Answers 10/35 questions → Network drops
[STATE SAVED: 10/35 decisions, last = cache-invalidation-strategy]

User reopens VS Code → Invokes @Bolt Constitution
Agent detects state: "Last session interrupted at question 11"
User chooses Resume → Continues from question 11
```

### Pattern 3: Review and Change

```text
User completes Phase 2B → Before Phase 3, wants to review
User: "Show me all my decisions"
Agent: Lists all 52 decisions with IDs
User: "Change decision #18 (CQRS enabled) to false"
Agent: Updates state, asks dependencies (CQRS pattern)
User: "Now continue to Phase 3"
```

## Implementation Checklist

- [ ] Create `refinement-state.yaml` schema
- [ ] Implement `Save-RefinementStateAtomic` function
- [ ] Add resume detection at agent start
- [ ] Build "Resume Options" dialog
- [ ] Implement incremental append to decisions[]
- [ ] Add progress indicators (18/35)
- [ ] Create "Review Decisions" viewer
- [ ] Implement "Change Decision" flow
- [ ] Add context window monitoring
- [ ] Test interruption scenarios

## Next Steps

1. ✅ **Design complete** (this document)
2. ⏭️ Update `bolt-constitution.agent.md` with resume flow
3. ⏭️ Update `skill-bolt-setup-constitution` with state management
4. ⏭️ Create PowerShell helper functions for state I/O
5. ⏭️ Add resume examples to agent instructions

---

**Version**: 1.0.0
**Last Updated**: 2026-03-01
**Author**: Bolt Framework Team
