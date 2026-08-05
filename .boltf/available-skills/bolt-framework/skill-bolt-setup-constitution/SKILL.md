---
name: skill-bolt-setup-constitution
description: Step 2 of Bolt Framework initialization - scope-based provisioning engine. Processes separate constitution files per scope, creates per-scope refinement YAMLs, and merges all decisions at the end. Use when provisioning files, initializing Bolt, scope provisioning, second init step, or resuming interrupted refinement.
user-invocable: false
---

# Bolt Setup Constitution

## When to Use

- After running `Init.ps1` / `init.sh` (step 2 of two-step initialization)
- When adding new scopes to existing project
- When updating constitution articles
- Invoked by `@Bolt Constitution` agent
- **Resuming interrupted refinement** - detect and restore from per-scope refinement state

## Available Scripts

This skill includes automation scripts for common tasks:

### Merge Refinement YAMLs

Automatically merge all scope refinement files into `merged-refinement.yaml`:

| Platform   | Script Path                         | Usage                                        |
| ---------- | ----------------------------------- | -------------------------------------------- |
| PowerShell | `scripts/Merge-RefinementYamls.ps1` | `.\Merge-RefinementYamls.ps1 -ProjectPath .` |
| Bash       | `scripts/merge-refinement-yamls.sh` | `./merge-refinement-yamls.sh . [--force]`    |
| Python     | `scripts/merge_refinement_yamls.py` | `python merge_refinement_yamls.py .`         |

**Features:**

- ✅ Auto-discovers all `*-refinement.yaml` files
- ✅ Detects article conflicts across scopes
- ✅ Calculates summary statistics
- ✅ Generates structured `merged-refinement.yaml`

### Sort Constitution by Criticality

Sort articles in constitution by criticality level (high → medium → low):

| Platform   | Script Path                                   |
| ---------- | --------------------------------------------- |
| PowerShell | `scripts/Sort-ConstitutionByCriticality.ps1`  |
| Bash       | `scripts/sort-constitution-by-criticality.sh` |
| Python     | `scripts/sort-constitution-by-criticality.py` |

## New Architecture: Per-Scope Processing

**KEY CHANGE**: Instead of merging all constitutions into one master file, this skill now:

1. **Processes each scope separately** (`<scope>-constitution.md`)
2. **Creates per-scope refinement state** (`<scope>-refinement.yaml`)
3. **Merges all YAMLs at the end** (`merged-refinement.yaml`)
4. **Generates final constitution** from merged decisions

### State Management Files

```text
.boltf/memory/
├── constitution-init.md                    # Base constitution (from Init step)
├── backend-constitution.md                 # Backend scope constitution
├── frontend-constitution.md                # Frontend scope constitution
├── cloud-platform-constitution.md          # Cloud platform scope constitution
├── constitution.md                         # Final merged constitution (after refinement)
└── refinement-states/
    ├── backend-refinement.yaml             # Backend scope decisions
    ├── frontend-refinement.yaml            # Frontend scope decisions
    ├── cloud-platform-refinement.yaml      # Cloud platform scope decisions
    └── merged-refinement.yaml              # Final merged decisions
```

## Control Flow & Resume Capability

✅ **Per-Scope State Persistence** - Each scope has its own refinement state
✅ **Resume from Interruption** - Continue from last unprocessed scope
✅ **Parallel Processing Ready** - Scopes are independent
✅ **Session Management** - Handle long refinement sessions (4+ hours)

## Workflow

### Phase 0: Initialization Check

**Check for existing state:**

```yaml
# Check for resume capability
if exists(.boltf/memory/refinement-states/):
  # Resume mode: find first scope with status != 'completed'
  # Ask user: "Resume from <scope>? [Y/n]"
else:
  # Fresh start: create refinement-states/ directory
  mkdir .boltf/memory/refinement-states/
```

### Phase 1: Read Active Scopes

**Source:** `.boltf/memory/scopes.yaml`

```yaml
# Read active scopes
active-scopes:
  - name: backend
    enabled: true
  - name: frontend
    enabled: true
  - name: cloud-platform
    enabled: true
```

**Output:** Array of active scope names → `['backend', 'frontend', 'cloud-platform']`

### Phase 2: Process Each Scope (Iterative)

**For each active scope, the agent processes its constitution file through a structured refinement workflow.**

📄 **[Scope Processing Logic Reference](references/scope-processing-logic.md)**

### Phase 3: Merge All Refinement YAMLs

**After all scopes are processed:**

#### Option A: Automated Merge with Scripts (Recommended)

Use the provided merge scripts to automatically combine all refinement files:

**PowerShell:**

```powershell
# From project root
.\.claude\skills\skill-bolt-setup-constitution\scripts\Merge-RefinementYamls.ps1 -ProjectPath . [-Force]
```

**Bash:**

```bash
# From project root
.claude/skills/skill-bolt-setup-constitution/scripts/merge-refinement-yamls.sh . [--force]
```

**Python:**

```bash
# From project root
python .claude/skills/skill-bolt-setup-constitution/scripts/merge_refinement_yamls.py . [--force]
```

#### Option B: Manual Merge (For Custom Processing)

If you need custom merge logic, refer to the detailed manual merge process:

📄 **[Manual Merge Logic Reference](references/manual-merge-logic.md)**

This reference provides step-by-step pseudocode for collecting scope refinement files, merging into a unified structure, and detecting conflicts between scopes.

### Phase 4: Generate Final Constitution

**Goal:** Create a concise, focused constitution containing ONLY user-approved articles.

**Source:** `merged-refinement.yaml`
**Output:** `.boltf/memory/constitution.md`

**CRITICAL FILTERING RULES:**

1. ✅ **Include** articles with `decision='include'` (original content)
2. ✅ **Include** articles with `decision='modified'` (modified content only)
3. ❌ **Exclude** articles with `decision='exclude'`
4. ❌ **Exclude** articles with `decision='skip'`
5. ❌ **Exclude** articles with `decision=null` or no decision
6. 💡 **Length Goal**: Keep final constitution focused and maintainable (typically 200-500 lines)

**Why This Matters:**

- Prevents information overload
- Makes constitution easier to reference during development
- Focuses on project-specific decisions, not generic boilerplate
- Ensures constitution reflects actual team choices, not defaults

````text
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

```text
IF exists(.boltf/memory/refinement-states/{scope}-refinement.yaml):
  READ state
  IF state.status == 'in-progress':
    # Find last processed article
    last_article = FIND article WHERE status == 'refined' (last one)
    next_article_index = last_article.index + 1

    ASK USER: "Resume scope '{scope}' from Article {next_article.number}? [Y/n]"

    IF yes:
      CONTINUE from next_article_index
    ELSE:
      START from beginning
````

### Phase 5: Generate Constitution Digest (token optimization)

**Goal:** Emit a condensed, decision-only view of the constitution so downstream
agents load ~1–2K tokens instead of the full file, **without dropping any binding decision**.

**Source:** `merged-refinement.yaml` (SAME structured source as `constitution.md` — never
re-parse the generated markdown).
**Output:** `.boltf/memory/constitution.digest.md`

📄 **[Constitution Digest Logic Reference](references/constitution-digest-logic.md)** —
full distillation rules and worked example.

**Core rule — `criticality` drives VERBOSITY, not INCLUSION:**

| `criticality` | Digest treatment |
| ------------- | ---------------------------------------------------------------------- |
| `HIGH`        | Keep full decision detail, including binding **code contracts** (e.g. CQRS interfaces) and thresholds |
| `MEDIUM`      | Collapse to a one-line decision statement (`key: value`)               |
| `LOW`         | Single bullet                                                          |

**Every** article with `decision IN ['include','modified']` appears in the digest. Only
non-decision content is dropped: Preamble, Governance ritual, Signatories, Revision History,
HTML banners, and repeated "Deferred — evaluate when cost-justified" prose (collapsed to one
line). Use `modified_content` for `modified` articles, exactly as Phase 4.

Generate the digest by following the reference logic (the distillation is semantic, exactly like
Phase 4 generates `constitution.md`). Then enforce the completeness gate mechanically:

```bash
python .claude/skills/skill-bolt-setup-constitution/scripts/validate_constitution_digest.py .
```

**Step 5.1 — Emit Tier-0 scope card into global instructions.** Regenerate the fenced
`<!-- BOLT:SCOPE-CARD -->` block in `CLAUDE.md` and `.github/copilot-instructions.md` from
`merged-refinement.yaml` (active scopes + one-line stack per scope + naming/formatting). This
block is auto-loaded by both clients, so scope/scenario detection costs zero extra reads.

**Step 5.2 — Validate the digest against the constitution (completeness gate):**

```text
FOR EACH article with decision IN ['include','modified'] in merged-refinement.yaml:
  ASSERT the article's decision appears in constitution.digest.md
IF any binding decision is missing → FAIL (do not ship the digest)
```

**Output size expectation:** ~150–250 lines / ~1–2K tokens (verify by decision coverage,
NOT by hitting a line count).

## Quality Gates

- [ ] All scope constitutions exist in `.boltf/memory/`
- [ ] Each scope has a corresponding refinement YAML
- [ ] All HIGH criticality articles have explicit decisions
- [ ] Merge script executed successfully to create `merged-refinement.yaml`
  - **Recommended**: Use `python .claude/skills/skill-bolt-setup-constitution/scripts/merge_refinement_yamls.py .`
  - Alternative: Manual merge following Phase 3 instructions
- [ ] All conflicts are resolved (check `conflicts:` section in merged-refinement.yaml)
- [ ] Final `constitution.md` generated successfully
- [ ] `constitution.digest.md` generated (Phase 5) and passes the completeness gate
      (every `include`/`modified` decision present)
- [ ] Tier-0 scope card block emitted into `CLAUDE.md` and `.github/copilot-instructions.md`
- [ ] Provision report created with stats

## Error Handling

```yaml
# Graceful degradation
errors:
  missing_scope_constitution:
    action: Log warning, skip scope, continue

  yaml_parse_error:
    action: Backup corrupt file, regenerate from scratch

  user_interruption:
    action: Save checkpoint, exit gracefully

  merge_conflict:
    action: Flag for manual review, include both versions with markers
```

## Example: Processing Backend Scope

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

### Resulting Final Constitution

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

**Note:** Articles VII and XII do not appear because their decisions were 'exclude' and 'skip' respectively.

## Next Steps

After constitution refinement:

1. ✅ **Reviewed**: All scope constitutions processed
2. ✅ **Merged**: Single `merged-refinement.yaml` created
3. ✅ **Generated**: Final `constitution.md` with approved articles
4. ➡️ **Provision**: Run `@Bolt Provisioner` to download skills/agents
5. ➡️ **Commit**: Save constitution to version control
