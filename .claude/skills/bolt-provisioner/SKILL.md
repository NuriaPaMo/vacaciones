---
name: bolt-provisioner
description: "Download and provision Bolt Framework resources (skills, prompts, instructions, agents, templates) from multiple sources (local available-skills, Context7, Awesome Copilot, Awesome Skills GitHub). Auto-selects skills based on active scopes and tech stack. Triggers: 'provision resources', 'download skills', 'context7 download', 'awesome copilot', 'available-skills', 'install skill', '/bolt-provisioner'."
---

# Bolt Provisioner — Methodology

Mission: download and provision all resources (skills, prompts, instructions, agents,
templates) from scope definitions.

## When invoked

Invoked by `bolt-constitution` during **Phase 4: Provision Resources**.

- **Input expected**: active scopes list, project path, provisioning plan (from
  PowerShell dry-run).
- **Output delivered**: all resources downloaded/copied to `.github/` and other
  destinations; enhanced provision report with download metadata; verification summary.

## Execution workflow

### Step 1: Load provisioning plan

Plan provided by `bolt-constitution`:

```yaml
plan:
  core_skills: [bolt-framework, bolt-adr, new-skill, markdown-formatting]
  scopes:
    - name: backend
      local_files: [...]
      context7_items: [...]
      awesome_copilot_items: [...]
      awesome_skills_items: [...]
    - name: cloud-platform
      local_files: [...]
      context7_items: [...]
      awesome_copilot_items: [...]
```

If no plan provided, read scopes from `.boltf/scopes.yaml` and parse each `scope.yaml`.

### Step 2: Verify local provisioning

```bash
ls .claude/skills/bolt-framework/
ls .claude/skills/bolt-adr/

ls .claude/skills/
ls .github/prompts/
```

### Step 3: Auto-select relevant skills from `available-skills`

#### Mapping rules

Map each active scope to the `.boltf/available-skills/` category folder(s) that match
the detected tech stack, then scan those categories for individual skill folders.

| Scope             | Available-Skills Category Folders          | Selection Logic                                            |
| ----------------- | ------------------------------------------ | ---------------------------------------------------------- |
| `backend`         | `<backend-stack>/`, `testing-must/`        | Scan the categories matching the backend stack             |
| `frontend`        | `<frontend-stack>/`, `ui-common/`          | Scan the category matching the detected frontend framework |
| `cloud-platform`  | `<cloud-provider>/`, `bolt-framework/`     | Scan the cloud-provider category for skill folders         |
| `ai`              | `bolt-framework/`                          | Scan for AI / testing-discipline skills                    |
| `data`            | `testing-must/`                            | Scan for tdd-\* skill folders                              |
| `work-management` | `<tracker>/` (e.g. `github/`)              | Scan the active work-tracker category                      |

> **CRITICAL**: Skills must be copied in a **FLAT structure** to `.claude/skills/`.
> **NEVER** copy the parent category folder. **ALWAYS** copy individual skill folders
> directly under `.claude/skills/`.

Example (mapping a category to flat skill folders):

```bash
# CORRECT - Copy individual skill folders in flat structure:
.boltf/available-skills/<category>/<skill-a>/
  → .claude/skills/<skill-a>/

.boltf/available-skills/<category>/<skill-b>/
  → .claude/skills/<skill-b>/

.boltf/available-skills/testing-must/tdd-red-green-refactor/
  → .claude/skills/tdd-red-green-refactor/

# WRONG - DO NOT copy category folders:
# .boltf/available-skills/<category>/
#   → .claude/skills/<category>/  ← NEVER DO THIS
```

Copy skills after confirmation:

```bash
cp -r .boltf/available-skills/<category>/<skill-a>/ \
     .claude/skills/<skill-a>/

cp -r .boltf/available-skills/github/github-workflows/ \
     .claude/skills/github-workflows/

# Verify each skill has SKILL.md
ls .claude/skills/<skill-a>/SKILL.md
```

Final validation:

```bash
ls -1 .claude/skills/
# Expected: flat list of skill names (NOT category folders).
```

### Step 4: Download from Context7

For each item with `source.type: context7`:

```yaml
- id: <provider>-template-context7
  kind: templates
  enabled: true
  source:
    type: context7
    library: /<org>/<docs-library>
    query: <natural-language query for the snippet you need>
  destination:
    folder: <destination/folder>
    name: <output-file-name>
```

Execution:

1. Resolve library (`mcp_context7_resolve-library-id`).
2. Query documentation (`mcp_context7_query-docs`, `maxResults: 3`).
3. Extract relevant code/content (parse for examples, include comments).
4. Format with frontmatter:

   ```text
   /*
   Source: Context7
   Library: /<org>/<docs-library>
   Query: <natural-language query>
   URL: <source url>
   Fetched: <timestamp>
   License: <license>
   */

   <code from documentation>
   ...
   ```

5. Write to destination.

### Step 5: Download from Awesome Copilot

For each item with `source.type: awesome_copilot`:

```yaml
- id: <collection>-best-practices-awesome
  kind: instructions
  enabled: true
  source:
    type: awesome_copilot
    collection: <collection-name>
    item_path: instructions/<instruction-file>.instructions.md
  destination:
    folder: .github/instructions
    name: <instruction-file>.instructions.md
```

Execution: load collection (cache), load instruction, format with frontmatter:

```markdown
---
source: awesome_copilot
collection: <collection-name>
item: instructions/<instruction-file>.instructions.md
url: https://github.com/github/awesome-copilot/tree/main/collections/<collection-name>/instructions/<instruction-file>.instructions.md
fetched: <timestamp>
license: repository-defined
---

[Content from instruction.content]
```

### Step 6: Download from Awesome Skills (GitHub)

For items with `source.type: awesome_skills`:

```yaml
- id: <skill-name>-awesome-skills
  kind: skills
  enabled: true
  source:
    type: awesome_skills
    repository: https://github.com/<owner>/<repo>
    skill_path: <path/to/skill>
  destination:
    folder: .claude/skills
    name: <skill-name>
```

Add `.source.yaml` to skill directory:

```yaml
# .claude/skills/<skill-name>/.source.yaml
source: awesome_skills
repository: https://github.com/<owner>/<repo>
skill_path: <path/to/skill>
fetched: <timestamp>
license: <license>
```

### Step 7: Generate enhanced provision report

Append download details to `provision-report.md`:

```markdown
## External Downloads Completed

### Auto-Selected Skills from Available-Skills ([N] items)

| Skill              | Source Folder | Category        |
| ------------------ | ------------- | --------------- |
| [skill-a]          | <category>/   | [category name] |
| [skill-b]          | <category>/   | [category name] |
| github-workflows   | github/       | Work Management |

### Context7 Downloads ([M] items)

| Item          | Library            | Query     | Destination     | Fetched     |
| ------------- | ------------------ | --------- | --------------- | ----------- |
| <output-file> | /<org>/<docs-lib>  | <query>   | <destination>/  | <timestamp> |

### Awesome Copilot Downloads ([P] items)

| Item                                | Collection        | Path                   | Destination           | Fetched     |
| ----------------------------------- | ----------------- | ---------------------- | --------------------- | ----------- |
| <instruction-file>.instructions.md  | <collection-name> | instructions/<file>... | .github/instructions/ | <timestamp> |

### Awesome Skills Downloads ([Q] items)

| Skill        | Repository      | Path             | Destination     | Fetched     |
| ------------ | --------------- | ---------------- | --------------- | ----------- |
| <skill-name> | <owner>/<repo>  | <path/to/skill>  | .claude/skills/ | <timestamp> |

**Total Provisioned**: [Total] items
```

### Step 8: Verification & summary

```bash
# Verify skills
ls .claude/skills/ | wc -l

# Check Context7 downloads
head -20 <destination>/<output-file>

# Check Awesome Copilot downloads
head -10 .github/instructions/<instruction-file>.instructions.md

# View full report
cat .boltf/memory/provision-report.md
```

## Error handling

### MCP not available

```markdown
**MCP Server Not Available: [context7 | awesome_copilot]**

**Missing Items** ([N] items):
- [List items that need this source]

**Options**:

A. **Skip for now** — continue without them (can provision later)
B. **Manual download** — I'll provide URLs and instructions
C. **Abort provisioning** — stop and report partial completion
```

### Download failed

```markdown
**Download Failed**

**Item**: [item-id]
**Source**: [context7 | awesome_copilot | awesome_skills]
**Error**: [error message]

**Options**:

A. Skip item — continue with others, mark as failed
B. Retry download
C. Manual fallback — provide manual download instructions
```

### Skill directory not found

```markdown
**No Auto-Selected Skills**

Scopes Active: [list]
Tech Stack: [detected stack]

**Options**:

A. Continue without auto-selected skills
B. Manually specify skills
C. Review available-skills
```

## Notes

- Always load MCP tools before using via `tool_search_tool_regex`.
- Cache loaded collections (Awesome Copilot) to avoid re-loading.
- Respect licenses — include license info in all downloaded files.
- Verify file creation after each download.
- Report progress incrementally.
- Handle partial failures gracefully.
- Test skill validity — ensure SKILL.md exists in copied skills.

## Success criteria

- All enabled items provisioned (or attempted with clear failure report).
- Auto-selected skills copied from available-skills.
- All downloads include source metadata (frontmatter/comments).
- Provision report includes all items with timestamps.
- Verification commands provided for user.
- Clear next steps for using provisioned resources.

## Related agents (next steps)

- → `bolt-constitution`: return to constitution setup after provisioning.
- → `bolt-framework`: begin AI-DLC after resources ready.
