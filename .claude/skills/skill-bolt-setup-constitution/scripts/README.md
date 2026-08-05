# Bolt Setup Constitution - Scripts

Automation scripts for common constitution setup tasks.

## Available Scripts

### 1. Merge Refinement YAMLs

Automatically merge all scope refinement files into a single `merged-refinement.yaml`.

#### PowerShell

```powershell
.\Merge-RefinementYamls.ps1 [-ProjectPath <path>] [-Force]
```

**Parameters:**

- `-ProjectPath`: Path to Bolt Framework project (default: current directory)
- `-Force`: Overwrite existing merged-refinement.yaml without prompting

**Example:**

```powershell
cd my-bolt-project
.\.claude\skills\skill-bolt-setup-constitution\scripts\Merge-RefinementYamls.ps1 -ProjectPath .
```

#### Bash

```bash
./merge-refinement-yamls.sh [PROJECT_PATH] [--force]
```

**Arguments:**

- `PROJECT_PATH`: Path to Bolt Framework project (default: current directory)
- `--force`, `-f`: Overwrite existing merged-refinement.yaml without prompting

**Example:**

```bash
cd my-bolt-project
chmod +x .claude/skills/skill-bolt-setup-constitution/scripts/merge-refinement-yamls.sh
.claude/skills/skill-bolt-setup-constitution/scripts/merge-refinement-yamls.sh . --force
```

#### Python

```bash
python merge_refinement_yamls.py [PROJECT_PATH] [--force]
```

**Requirements:**

- Python 3.9+
- PyYAML: `pip install -r ../requirements.txt`

**Arguments:**

- `PROJECT_PATH`: Path to Bolt Framework project (default: current directory)
- `--force`, `-f`: Overwrite existing merged-refinement.yaml without prompting

**Example:**

```bash
cd my-bolt-project
python .claude/skills/skill-bolt-setup-constitution/scripts/merge_refinement_yamls.py .
```

### 2. Sort Constitution by Criticality

Sort articles in constitution by criticality level (high → medium → low).

#### PowerShell

```powershell
.\Sort-ConstitutionByCriticality.ps1 [-ProjectPath <path>]
```

#### Bash

```bash
./sort-constitution-by-criticality.sh [PROJECT_PATH]
```

#### Python

```bash
python sort-constitution-by-criticality.py [PROJECT_PATH]
```

## What the Merge Script Does

1. ✅ **Discovery**: Finds all `*-refinement.yaml` files in `.boltf/memory/refinement-states/`
2. ✅ **Loading**: Parses each scope's refinement data using YAML parser
3. ✅ **Conflict Detection**: Identifies articles appearing in multiple scopes
4. ✅ **Statistics**: Calculates total articles, decisions, and scope count
5. ✅ **Output**: Generates structured `merged-refinement.yaml` with:
   - Summary section (totals, timestamp, conflict flag)
   - Scopes section (list of all merged scopes)
   - Conflicts section (articles needing manual review)
   - Detailed scope data (full content of each scope preserved)

## Output Example

```text
[INFO] Found 3 scope refinement file(s):
[INFO]   • backend-refinement.yaml
[INFO]   • frontend-refinement.yaml
[INFO]   • cloud-platform-refinement.yaml

[INFO] Processing scope: backend
[OK]     Added 15 articles, 12 decisions

[INFO] Processing scope: frontend
[OK]     Added 8 articles, 6 decisions

[INFO] Processing scope: cloud-platform
[OK]     Added 22 articles, 18 decisions

[INFO] Detecting conflicts...
[WARN]   Conflict: Article III appears in: backend, frontend

[OK]   Merged refinement file created: merged-refinement.yaml

[INFO] Summary:
[INFO]   • Scopes merged: 3
[INFO]   • Total articles: 45
[INFO]   • Total decisions: 36
[INFO]   • Conflicts detected: 1

[OK]   Merge complete!
```

## Merged YAML Structure

```yaml
# Summary Statistics
total_scopes: 3
total_articles: 45
total_decisions: 36
merge_timestamp: 2026-03-06 14:30:00
has_conflicts: true

# Scopes
scopes:
  - scope: backend
    articles_count: 15
    decisions_count: 12
    source_file: backend-refinement.yaml

  - scope: frontend
    articles_count: 8
    decisions_count: 6
    source_file: frontend-refinement.yaml

  - scope: cloud-platform
    articles_count: 22
    decisions_count: 18
    source_file: cloud-platform-refinement.yaml

# Conflicts (articles appearing in multiple scopes)
conflicts:
  - article: 'Article III'
    scopes: [backend, frontend]
    resolution: pending

# Detailed Scope Data (full content of each scope)
scope_data:
  backend:
    # ... full backend-refinement.yaml content ...

  frontend:
    # ... full frontend-refinement.yaml content ...

  cloud-platform:
    # ... full cloud-platform-refinement.yaml content ...
```

## Troubleshooting

### Permission Denied (Bash)

```bash
chmod +x merge-refinement-yamls.sh
chmod +x sort-constitution-by-criticality.sh
```

### Python Import Error

```bash
pip install -r ../requirements.txt
```

### No Refinement Files Found

Ensure you've run the constitution refinement process first:

1. Run `Init.ps1` or `init.sh`
2. Invoke `@Bolt Constitution` agent
3. Complete at least one scope refinement
4. Check `.boltf/memory/refinement-states/` for `*-refinement.yaml` files

## When to Use

- **After completing all scope refinements** - Run merge script before generating final constitution
- **When adding new scopes** - Re-run merge to include new scope data
- **Manual constitution updates** - Re-merge after editing any scope refinement YAML
- **Conflict resolution** - After resolving conflicts, re-run merge to update timestamp

## Integration with Bolt Constitution Agent

The `@Bolt Constitution` agent automatically uses these scripts during Phase 3 (Merge All Refinement YAMLs). You can also run them manually at any time.

---

**Bolt Framework v2.0.0** | [Documentation](../../SKILL.md)
