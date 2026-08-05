# Bolt Framework - Python Integration Guide

## Overview

Bolt Framework includes Python-based scripts for advanced features like AI-powered skill optimization, evaluation, and scaffolding. These scripts are **optional** - basic framework functionality works without Python.

## When Do You Need Python?

Python is required for:

### ✅ Advanced Features

- **Skill Optimization**: AI-powered skill description improvement (`skill-creator`)
- **Automated Testing**: Skill trigger evaluation and benchmarking
- **Scaffolding**: Advanced code generation (frontend components, IaC templates)

### ⛔ NOT Required For

- Basic project initialization (`Init.ps1`)
- Constitution setup
- Feature specifications
- Agent interactions
- Manual skill creation

## Quick Start

### 1. Prerequisites

**Python 3.9 or higher** is required.

**Windows:**

```powershell
# Check if Python is installed
python --version

# If not, download from https://www.python.org/downloads/
# ⚠️ Check "Add Python to PATH" during installation
```

**Linux/macOS:**

```bash
# Check version
python3 --version

# Install if needed
# Ubuntu/Debian: sudo apt install python3 python3-venv
# macOS:         brew install python@3.11
# RHEL/Fedora:   sudo dnf install python3
```

### 2. Bootstrap Python Environment

Bolt Framework uses an **isolated virtual environment** (`.bolt-venv`) to avoid conflicts.

**Windows (PowerShell):**

```powershell
# From project root
.\.boltf\scripts\powershell\Bootstrap-Python.ps1

# Force recreate if needed
.\.boltf\scripts\powershell\Bootstrap-Python.ps1 -Force
```

**Linux/macOS (Bash):**

```bash
# From project root
source .boltf/scripts/bash/bootstrap-python.sh

# Force recreate
source .boltf/scripts/bash/bootstrap-python.sh --force
```

This command will:

1. ✅ Check Python version (3.9+)
2. ✅ Create virtual environment at `.bolt-venv/`
3. ✅ Install required packages (`anthropic`, `pyyaml`)
4. ✅ Verify installation

### 3. Using Python Scripts

#### Option A: Convenience Wrapper (Recommended)

**Windows:**

```powershell
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py my-skill\
```

**Linux/macOS:**

```bash
./.bolt-venv/bin/python .claude/skills/skill-creator/scripts/quick_validate.py my-skill/
```

#### Option B: Manual Activation

**Windows:**

```powershell
# Activate
.\.bolt-venv\Scripts\Activate.ps1

# Run scripts
python .claude\skills\skill-creator\scripts\quick_validate.py my-skill\
python .claude\skills\skill-creator\scripts\package_skill.py my-skill\ .\dist\

# Deactivate when done
deactivate
```

**Linux/macOS:**

```bash
# Activate
source .bolt-venv/bin/activate

# Run scripts
python .claude/skills/skill-creator/scripts/quick_validate.py my-skill/
python .claude/skills/skill-creator/scripts/package_skill.py my-skill/ ./dist/

# Deactivate
deactivate
```

## Available Python Scripts

### 🔍 skill-creator/scripts/

| Script                   | Purpose                             | Dependencies |
| ------------------------ | ----------------------------------- | ------------ |
| `quick_validate.py`      | Validate SKILL.md structure         | `pyyaml`     |
| `package_skill.py`       | Create distributable `.skill` file  | stdlib only  |
| `run_eval.py`            | Test skill triggering accuracy      | `anthropic`  |
| `improve_description.py` | AI-powered description optimization | `anthropic`  |
| `run_loop.py`            | Automated eval+improve loop         | `anthropic`  |
| `generate_report.py`     | HTML reports for evaluation         | stdlib only  |
| `aggregate_benchmark.py` | Statistical analysis                | stdlib only  |

### Example Workflows

#### Basic Skill Validation (No AI)

```powershell
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py .claude\skills\my-skill\
```

#### Package Skill for Distribution

```powershell
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\package_skill.py .claude\skills\my-skill\ .\dist\
```

#### AI-Powered Skill Optimization (Requires Anthropic API Key)

```powershell
# Set API key
$env:ANTHROPIC_API_KEY = "sk-ant-..."

# Run evaluation
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\run_eval.py `
    --eval-set evals\my-skill.json `
    --skill-path .claude\skills\my-skill\

# Optimize description
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\run_loop.py `
    --eval-set evals\my-skill.json `
    --skill-path .claude\skills\my-skill\ `
    --max-iterations 5
```

## Dependencies

### Core (Always Installed)

- **anthropic** (>=0.39.0): Claude API SDK for AI-powered features
- **pyyaml** (>=6.0): YAML parsing for SKILL.md frontmatter

### Standard Library (Built-in)

- `pathlib`, `json`, `subprocess`, `concurrent.futures`, `argparse`

## Troubleshooting

### "Python not found"

- ✅ Install Python 3.9+ from <https://python.org/downloads/>
- ✅ Windows: Check "Add Python to PATH" during installation
- ✅ Restart terminal after installation

### "anthropic module not found"

```powershell
# Reinstall dependencies
.\.boltf\scripts\powershell\Bootstrap-Python.ps1 -Force
```

### Virtual Environment Corrupted

```powershell
# Delete and recreate
Remove-Item -Recurse -Force .bolt-venv
.\.boltf\scripts\powershell\Bootstrap-Python.ps1
```

### Permission Errors (Windows)

```powershell
# Enable script execution
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Permission Errors (Linux/macOS)

```bash
# Make script executable
chmod +x .boltf/scripts/bash/bootstrap-python.sh
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Skill Validation

on: [push, pull_request]

jobs:
  validate-skills:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Bootstrap Python Environment
        run: |
          source .boltf/scripts/bash/bootstrap-python.sh --skip-install
          pip install -r .claude/skills/skill-creator/requirements.txt

      - name: Validate Skills
        run: |
          source .bolt-venv/bin/activate
          for skill in .claude/skills/*/; do
            python .claude/skills/skill-creator/scripts/quick_validate.py "$skill"
          done
```

### Azure Pipelines

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.11'
      addToPath: true

  - script: |
      source .boltf/scripts/bash/bootstrap-python.sh
    displayName: 'Bootstrap Python Environment'

  - script: |
      source .bolt-venv/bin/activate
      python .claude/skills/skill-creator/scripts/quick_validate.py .claude/skills/my-skill/
    displayName: 'Validate Skills'
```

## Architecture

```text
project-root/
├── .bolt-venv/                    # Python virtual environment (gitignored)
│   ├── bin/                       # Executables (Linux/macOS)
│   ├── Scripts/                   # Executables (Windows)
│   └── Lib/site-packages/         # Installed packages
│
├── .boltf/scripts/
│   ├── powershell/
│   │   └── Bootstrap-Python.ps1   # Setup script (Windows)
│   └── bash/
│       └── bootstrap-python.sh    # Setup script (Linux/macOS)
│
├── .claude/skills/
│   └── skill-creator/
│       ├── requirements.txt       # Python dependencies
│       └── scripts/               # Python utilities
│
└── Invoke-PythonScript.ps1        # Convenience wrapper
```

## Best Practices

### ✅ Do

- Use virtual environment (`.bolt-venv`) to avoid conflicts
- Run `Bootstrap-Python.ps1` once per project clone
- Keep API keys in environment variables, not in code
- Use the wrapper script (`Invoke-PythonScript.ps1`) for portability

### ⛔ Don't

- Install packages globally (`pip install` outside venv)
- Commit `.bolt-venv/` to Git (it's gitignored)
- Hardcode API keys in scripts
- Modify bootstrap scripts without testing on all platforms

## FAQ

**Q: Is Python required to use Bolt Framework?**
A: No. Basic features (init, constitution, specs) work without Python. It's only needed for advanced AI-powered features.

**Q: Can I use my existing Python installation?**
A: Yes, as long as it's version 3.9+. The bootstrap script creates an isolated virtual environment to avoid conflicts.

**Q: Where are packages installed?**
A: In `.bolt-venv/Lib/site-packages/` (Windows) or `.bolt-venv/lib/python3.x/site-packages/` (Linux/macOS).

**Q: How do I update dependencies?**
A: Run `Bootstrap-Python.ps1 -Force` to recreate the environment with latest versions.

**Q: Can I add more Python dependencies?**
A: Yes, add them to the appropriate `requirements.txt` and rerun bootstrap.

---

**Next Steps:**

- 📚 [Skill Creator Documentation](../.claude/skills/skill-creator/SKILL.md)
- 🤖 [Agent Documentation](../.github/agents/README.md)
- 📖 [Bolt Framework Guide](../README.md)
