---
name: bolt-skill-creator
description: "Create, improve and optimize Bolt Framework skills using the AI-powered skill-creator workflow with iterative testing, benchmarking and description optimization. Triggers: 'create skill', 'new skill', 'improve skill', 'optimize skill', 'skill triggering', 'skill evaluation', 'package skill', '/bolt-skill-creator'."
---

# Bolt Skill Creator — Methodology

Primary mission: guide users through creating, improving and optimizing skills using
the `skill-creator` skill workflow with iterative testing and optimization.

## When to use

- **Create a new skill from scratch** — "Create a skill for X".
- **Improve an existing skill** — "Optimize my Y skill".
- **Run skill evaluations** — "Test my skill with benchmarks".
- **Optimize skill descriptions** — "Improve skill triggering accuracy".
- **Package skills for distribution** — "Package my skill for sharing".

## Prerequisites — Python environment

`skill-creator` requires Python 3.9+ with:

- `anthropic>=0.39.0`
- `pyyaml>=6.0`

```bash
# 1. Check if Python environment exists
ls .bolt-venv/

# 2. If missing, run bootstrap
.boltf/scripts/bash/bootstrap-python.sh --project-root .

# 3. Activate virtual environment
source .bolt-venv/bin/activate

# 4. Verify dependencies
python -c "import anthropic, yaml; print('Dependencies ready')"
```

Windows (PowerShell):

```powershell
.bolt-venv\Scripts\Activate.ps1
deactivate
```

## Workflow overview

### Phase 1: Capture intent

1. **What should this skill enable Claude to do?** Define clear success criteria.
2. **When should this skill trigger?** User phrases, contexts, keywords.
3. **Expected output format?** File types, data structures, responses.
4. **Should we set up test cases?**
   - YES for objective skills: file transforms, data extraction, code generation.
   - NO for subjective skills: writing style, creative work.

### Phase 2: Interview & research

- Proactively ask about edge cases, input/output formats, dependencies.
- Research in parallel using available MCPs (Context7, Microsoft Docs).
- Wait to write test prompts until context is complete.

### Phase 3: Write SKILL.md

```yaml
---
name: skill-identifier
description: 'When to trigger, what it does. Be "pushy" - include specific contexts for when to use.'
compatibility: # Optional - required tools/dependencies
---

# Skill Name

## Purpose
What this skill does and why it exists

## When to Use This Skill
Specific scenarios where this skill applies

## When NOT to Use
Clear anti-patterns or exclusions

## Key Concepts
Important concepts users need to understand

## Workflows
Step-by-step procedures

## Examples
Concrete usage examples with code/output

## References
External documentation and resources
```

Best practices:

- Keep SKILL.md under 500 lines (use progressive disclosure for larger skills).
- Make descriptions "pushy" — overtrigger is better than undertrigger.
- Include clear "When to Use" and "When NOT to Use" sections.
- Provide concrete examples, not just theory.

### Phase 4: Create test cases

```text
skills/my-skill/
├── SKILL.md
└── tests/
    ├── test-prompts.txt
    ├── expected/
    │   ├── case-1.txt
    │   └── case-2.json
    └── eval-assertions.json
```

`test-prompts.txt`:

```text
---
Write JavaScript function to validate email addresses

---
Convert this JSON to YAML format:
{"name": "test", "version": "1.0"}

---
Create React component for user profile card
```

`eval-assertions.json`:

```json
{
  "test-1": {
    "assertions": [
      { "type": "contains", "value": "function" },
      { "type": "regex", "pattern": "@.*\\." }
    ]
  },
  "test-2": {
    "assertions": [
      { "type": "file_format", "format": "yaml" },
      { "type": "contains", "value": "version: 1.0" }
    ]
  }
}
```

### Phase 5: Run evaluation loop

```bash
python -m scripts.run_loop \
  --skill-path /path/to/skills/my-skill \
  --test-prompts /path/to/skills/my-skill/tests/test-prompts.txt \
  --output ./workspace/iteration-1
```

What this does: runs each test prompt with the skill loaded, saves responses to
workspace, runs quantitative assertions, generates performance metrics.

### Phase 6: Review & iterate

```bash
python .claude/skills/skill-creator/eval-viewer/generate_review.py \
  --workspace ./workspace/iteration-1 \
  --output review.html
```

Feedback dimensions: correctness, completeness, quality, edge cases.

Iteration: identify issues → update SKILL.md → re-run evaluation → compare iterations.

### Phase 7: Expand & benchmark

After initial success (3-5 prompts → 10-20 prompts), add edge cases, run full
benchmark:

```bash
python -m scripts.aggregate_benchmark \
  ./workspace/iteration-N \
  --skill-name my-skill
```

Benchmark metrics: success rate, average response quality, performance variance, edge
case handling.

### Phase 8: Optimize description (manual)

The skill's `description` field is **critical** for triggering. Manual optimization:

1. Test triggering accuracy — try different user prompts.
2. Analyze false negatives.
3. Brainstorm trigger phrases — common ways users express the need.
4. Update description — add explicit trigger phrases.
5. Verify — test again.

Optimization tips:

- Be "pushy" — include specific trigger phrases and synonyms.
- Use concrete keywords — what users actually type.
- Include action verbs — "formatting", "validating", "generating".
- List domains — "SQL", "JSON", "API design".

Examples:

- Bad: "Help with data visualization"
- Good: "Data visualization, charts, graphs, dashboards, plotting. Use whenever user
  mentions visual analysis, displaying data, creating plots, or chart generation."

### Phase 9: Package & share

```bash
python -m scripts.package_skill /path/to/skills/my-skill
```

Output: `my-skill.skill` file.

Share options: project-specific (`.claude/skills/`), framework library
(`.boltf/available-skills/`), public distribution (GitHub).

## Common commands reference

### Skill development

| Task                   | Command                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------- |
| Create skill structure | `mkdir -p .claude/skills/my-skill && touch .claude/skills/my-skill/SKILL.md`                                |
| Validate SKILL.md      | `python .claude/skills/skill-creator/scripts/quick_validate.py .claude/skills/my-skill`                     |
| Run single evaluation  | `python -m scripts.run_loop --skill-path .claude/skills/my-skill --test-prompts tests.txt --output ./out`   |
| Generate review        | `python .claude/skills/skill-creator/eval-viewer/generate_review.py --workspace ./out --output review.html` |
| Aggregate benchmarks   | `python -m scripts.aggregate_benchmark ./workspace/iteration-N --skill-name my-skill`                       |
| Package skill          | `python -m scripts.package_skill .claude/skills/my-skill`                                                   |

### Environment management

| Task                | Command                                                                                                               |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Setup Python        | `.boltf/scripts/bash/bootstrap-python.sh` (Linux/macOS)<br>`.boltf/scripts/powershell/Bootstrap-Python.ps1` (Windows) |
| Activate venv       | `source .bolt-venv/bin/activate` (Linux/macOS)<br>`.bolt-venv\Scripts\Activate.ps1` (Windows)                         |
| Deactivate venv     | `deactivate`                                                                                                          |
| Verify dependencies | `python -c "import anthropic, yaml; print('OK')"`                                                                     |
| Reinstall deps      | `pip install -r .claude/skills/skill-creator/requirements.txt`                                                        |

## Example: creating a SQL formatter skill

User request: "Create a skill for formatting SQL queries"

### 1. Capture intent

```text
Agent: What should this SQL formatter do?
User: Beautify SQL queries with proper indentation and keyword case

Agent: When should it trigger?
User: When users paste SQL or say "format SQL"

Agent: Expected output?
User: Formatted SQL string

Agent: Should we test it?
User: Yes - let's create test cases
```

### 2. Interview

```text
Agent Questions:
- SQL dialects? (PostgreSQL, MySQL, SQL Server)
- Keyword case? (UPPER, lower, PascalCase)
- Indentation? (2 spaces, 4 spaces, tabs)
- Handle syntax errors? (skip or report)

User Answers:
- PostgreSQL primarily, but generic SQL
- Keywords UPPERCASE
- 2-space indentation
- Skip invalid SQL with warning
```

### 3. Write SKILL.md

```markdown
---
name: sql-formatter
description: 'Format and beautify SQL queries. Use when user mentions SQL formatting, query beautification, or pastes unformatted SQL code. Triggers on: "format SQL", "beautify query", "indent SQL", SQL code blocks.'
---

# SQL Formatter

## Purpose
Automatically format SQL queries with proper indentation, keyword case, and structure.

## When to Use
- User pastes unformatted SQL
- User says "format SQL" or "beautify query"

## Workflow
1. Parse SQL query
2. Apply formatting rules:
   - Keywords: UPPERCASE
   - Indentation: 2 spaces per level
   - Line breaks: Before SELECT, FROM, WHERE, JOIN
3. Return formatted SQL
```

### 5. Run evaluation

```bash
cd .claude/skills/skill-creator
python -m scripts.run_loop \
  --skill-path ../../skills/sql-formatter \
  --test-prompts ../../skills/sql-formatter/tests/test-prompts.txt \
  --output ./workspace/sql-formatter-v1
```

### 8. Optimize description (manual)

```yaml
description: "SQL query formatting, beautification, query optimization, database code cleanup. Use whenever user mentions SQL queries, format SQL, beautify database code, query formatting, or database query cleanup."
```

### 9. Package & deploy

```bash
python -m scripts.package_skill ../../skills/sql-formatter
cp sql-formatter.skill ../../../.boltf/available-skills/database/
```

## Troubleshooting

### Python environment issues

`ModuleNotFoundError: No module named 'anthropic'`:

```bash
source .bolt-venv/bin/activate
pip install -r .claude/skills/skill-creator/requirements.txt
```

`command not found: python`:

```bash
python3 -m scripts.run_loop ...
alias python=python3
```

### Skill not triggering

1. Make description more explicit (pushy + concrete keywords + action verbs).
2. Add more trigger phrases.
3. Test manually with various prompts.
4. Check compatibility — are required tools available?

### Evaluation failures

1. Review actual outputs in workspace folder.
2. Verify expected outputs are correct.
3. Adjust assertions to be less brittle:

   ```json
   // Brittle
   {"type": "exact_match", "value": "function validateEmail()"}

   // Flexible
   {"type": "contains", "value": "validateEmail"}
   {"type": "regex", "pattern": "function.*Email"}
   ```

4. Add tolerance for non-deterministic outputs.

### Performance issues

1. Reduce test set during iteration (3-5 prompts).
2. Use `--parallel` flag if available.
3. Cache results between iterations.
4. Profile bottlenecks with timing metrics.

## Best practices

### Skill design

- **Single responsibility**: one skill = one capability.
- **Clear scope**: define what skill does AND doesn't do.
- **Progressive disclosure**: keep SKILL.md under 500 lines.
- **Concrete examples**: show, don't just tell.

### Testing

- **Start small**: 3-5 test prompts initially.
- **Iterate fast**: Run → Review → Improve → Repeat.
- **Expand gradually**: add tests as you discover edge cases.
- **Quantify success**: use assertions for objective metrics.

### Description optimization

- **Be pushy**: overtrigger is better than undertrigger.
- **Include synonyms**: "data viz, charts, graphs, plots".
- **Add contexts**: "Use when user mentions X, Y, or Z".

### Collaboration

- Document decisions, version test cases, share learnings, reuse patterns.

## Integration with Bolt Framework

### Skill lifecycle

1. **Development** (this agent) → create & test skill.
2. **Provisioning** (`bolt-constitution`) → include skill in scope.yaml.
3. **Usage** (all agents) → auto-load when triggered.
4. **Maintenance** (this agent) → update & re-test skills.

### Scope integration

Edit `.boltf/scopes/{scope}/scope.yaml`:

```yaml
items:
  - kind: skill
    name: my-skill
    source_type: local_file
    source_path: .claude/skills/my-skill
    auto_provision: true
    destination: .claude/skills/my-skill
```

To make skill universal: add to `.boltf/scopes/common/scope.yaml`.

### Constitution documentation

After creating skill, document in constitution Article XXIII (Custom Skills):

```markdown
## Custom Skills Created

- **sql-formatter** - SQL query beautification
  - Triggers on: Format SQL, beautify query
  - Test coverage: 15 cases
  - Optimization score: 92%
  - Created: 2026-02-27
```

## References

- `.claude/skills/skill-creator/SKILL.md`
- `.claude/skills/bolt-framework/SKILL.md`
- `.boltf/docs/skill-best-practices.md` (if exists)
- `.boltf/scripts/README.md` (if exists)

## Memory

Store: skill patterns that work well, common pitfalls, description templates that
trigger reliably, test assertion patterns that are reusable, performance benchmarks.

## Related agents (next steps)

- → `bolt-specify`: document skill as a formal feature specification.
- → `bolt-testing`: create comprehensive test suite beyond basic evals.
- → `bolt-docs`: generate user-facing documentation with examples.
- → `bolt-review`: code review of skill implementation.
