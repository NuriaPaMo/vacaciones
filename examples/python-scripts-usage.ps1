# =============================================================================
# Bolt Framework - Python Script Examples
# =============================================================================
# Common workflows for using Python scripts in Bolt Framework
# =============================================================================

# ─── Prerequisites ───────────────────────────────────────────────────────────
# Run once to setup Python environment:
#   .\.boltf\scripts\powershell\Bootstrap-Python.ps1

# ─── Skill Validation (No AI, No API Key) ───────────────────────────────────

# Validate a single skill
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py .claude\skills\my-skill\

# Validate all skills
Get-ChildItem .claude\skills -Directory | ForEach-Object {
    Write-Host "`nValidating: $($_.Name)" -ForegroundColor Cyan
    .\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py $_.FullName
}

# ─── Skill Packaging (No AI, No API Key) ────────────────────────────────────

# Package a single skill
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\package_skill.py .claude\skills\my-skill\ .\dist\

# Package all skills
$distDir = ".\dist"
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
Get-ChildItem .claude\skills -Directory | ForEach-Object {
    Write-Host "`nPackaging: $($_.Name)" -ForegroundColor Cyan
    .\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\package_skill.py $_.FullName $distDir
}

# ─── AI-Powered Skill Evaluation (Requires ANTHROPIC_API_KEY) ───────────────

# Set API key (get from https://console.anthropic.com/)
$env:ANTHROPIC_API_KEY = "sk-ant-..."

# Run evaluation on skill
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\run_eval.py `
    --eval-set .claude\skills\my-skill\evals\trigger-tests.json `
    --skill-path .claude\skills\my-skill\ `
    --num-workers 5 `
    --runs-per-query 3 `
    --verbose

# ─── AI-Powered Description Optimization (Requires ANTHROPIC_API_KEY) ───────

# Optimize skill description (train/test split)
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\run_loop.py `
    --eval-set .claude\skills\my-skill\evals\trigger-tests.json `
    --skill-path .claude\skills\my-skill\ `
    --max-iterations 10 `
    --holdout 0.3 `
    --model claude-sonnet-4-20250514 `
    --verbose

# With live HTML report (auto-refreshing)
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\run_loop.py `
    --eval-set .claude\skills\my-skill\evals\trigger-tests.json `
    --skill-path .claude\skills\my-skill\ `
    --max-iterations 10 `
    --report-path .\reports\skill-optimization.html `
    --open-browser `
    --verbose

# ─── Generate HTML Report from Eval Results ──────────────────────────────────

# Generate visual report
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\generate_report.py `
    --input-json .\results\eval-output.json `
    --output-html .\reports\skill-evaluation.html `
    --open-browser

# ─── Benchmark Analysis (Statistical) ────────────────────────────────────────

# Aggregate benchmark data
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\aggregate_benchmark.py `
    .\benchmarks\2026-02-26T10-30-00\

# ─── Continuous Validation in CI/CD ──────────────────────────────────────────

# Add to GitHub Actions workflow:
<#
name: Validate Skills
on: [push, pull_request]
jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: .\.boltf\scripts\powershell\Bootstrap-Python.ps1
      - run: |
          Get-ChildItem .claude\skills -Directory | ForEach-Object {
            .\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py $_.FullName
          }
#>

# ─── Troubleshooting ─────────────────────────────────────────────────────────

# Recreate Python environment
Remove-Item -Recurse -Force .bolt-venv -ErrorAction SilentlyContinue
.\.boltf\scripts\powershell\Bootstrap-Python.ps1 -Force

# Check installed packages
.\.bolt-venv\Scripts\python.exe -m pip list

# Verify anthropic SDK
.\.bolt-venv\Scripts\python.exe -c "import anthropic; print(f'Anthropic SDK version: {anthropic.__version__}')"

# Test API connection (with API key)
.\.bolt-venv\Scripts\python.exe -c @"
import anthropic, os
client = anthropic.Anthropic(api_key=os.environ.get('ANTHROPIC_API_KEY'))
print('API connection: OK')
"@

# ─── Notes ───────────────────────────────────────────────────────────────────

# 1. Scripts without AI (quick_validate, package_skill) work without API key
# 2. AI-powered features (run_eval, run_loop, improve_description) require:
#    - ANTHROPIC_API_KEY environment variable
#    - Valid API credits
# 3. Use -verbose flag for detailed output
# 4. HTML reports open automatically with --open-browser flag
