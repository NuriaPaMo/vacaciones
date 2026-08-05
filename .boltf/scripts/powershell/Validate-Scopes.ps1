<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Validate Scopes Script

.DESCRIPTION
    Validates .boltf/scopes/*/scope.yaml files for structure, external source rules,
    and tags constraints.

.PARAMETER Check
    Run validation checks.

.EXAMPLE
    .\Validate-Scopes.ps1 -Check
#>

param(
    [switch]$Check
)

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Err { Write-Host "[✗] $args" -ForegroundColor Red }

$python = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } elseif (Get-Command py -ErrorAction SilentlyContinue) { 'py -3' } else { $null }
if (-not $python) {
    Write-Err "Python is required to run this validator."
    exit 1
}

Write-Info "Validating scope definitions..."

$pyScript = @'
import glob
import json
import os
import re
import sys

try:
    import yaml
except Exception:
    print("[✗] PyYAML is required. Install with: pip install pyyaml")
    sys.exit(1)

errors = 0
warnings = 0


def warn(msg):
    global warnings
    warnings += 1
    print(f"[⚠] {msg}")


def err(msg):
    global errors
    errors += 1
    print(f"[✗] {msg}")


scope_files = sorted(glob.glob('.boltf/scopes/*/scope.yaml'))

if not scope_files:
    err('No scope.yaml files found under .boltf/scopes')
    sys.exit(1)

for scope_file in scope_files:
    scope_name = os.path.basename(os.path.dirname(scope_file))
    print("\n────────────────────────────────────────")
    print(f"  Scope: {scope_name}")
    print("────────────────────────────────────────")

    try:
        with open(scope_file, 'r', encoding='utf-8') as f:
            content = f.read()
        doc = yaml.safe_load(content)
        print('[✓] YAML parse OK')
    except Exception as ex:
        err(f"{scope_file}: invalid YAML ({ex})")
        continue

    if not isinstance(doc, dict):
        err(f"{scope_file}: root must be an object")
        continue

    if 'scope' not in doc:
        err('Missing root field: scope')
    if 'items' not in doc:
        err('Missing root field: items')
        continue

    items = doc.get('items')
    if not isinstance(items, list):
        err('Root field items must be an array')
        continue
    if not items:
        warn('No items defined')
        continue

    for i, item in enumerate(items):
        item_ref = f'item[{i}]'
        if not isinstance(item, dict):
            err(f'{item_ref} must be an object')
            continue

        for required in ('id', 'kind', 'enabled', 'source', 'destination'):
            if required not in item:
                err(f'{item_ref} missing required field: {required}')

        if 'tags' in item:
            tags = item.get('tags')
            if not isinstance(tags, list):
                err(f'{item_ref} tags must be an array')
                tags = []
            if len(tags) > 3:
                err(f'{item_ref} tags has {len(tags)} entries; max allowed is 3')
            for t in tags:
                if not isinstance(t, str) or not t.strip():
                    err(f'{item_ref} tags contains empty or invalid value')

        source = item.get('source')
        if isinstance(source, dict) and source.get('type') == 'awesome_skills':
            if not source.get('catalog_url'):
                err(f"{item_ref} (id={item.get('id')}) source.type=awesome_skills requires source.catalog_url")
            if not source.get('repository'):
                err(f"{item_ref} (id={item.get('id')}) source.type=awesome_skills requires source.repository")

        blob = json.dumps(item, ensure_ascii=False).lower()
        tags_lower = [str(x).lower() for x in item.get('tags', [])] if isinstance(item.get('tags', []), list) else []

        if re.search(r'csharp|dotnet|aspnet|\.net', blob):
            if 'csharp' not in tags_lower:
                err(f"{item_ref} (id={item.get('id')}) is C#/.NET related and must include tag 'csharp'")

        if re.search(r'nodejs|\bnode\b|nestjs|express|fastify', blob):
            if 'nodejs' not in tags_lower:
                err(f"{item_ref} (id={item.get('id')}) is Node.js related and must include tag 'nodejs'")

print("\n────────────────────────────────────────")
print("  Validation Summary")
print("────────────────────────────────────────")
print("")
print(f"  Errors:   {errors}")
print(f"  Warnings: {warnings}")
print("")

if errors > 0:
    print(f"[ERROR] Scope validation FAILED with {errors} error(s)")
    sys.exit(1)
elif warnings > 0:
    print(f"[WARNING] Scope validation passed with {warnings} warning(s)")
    sys.exit(0)
else:
    print("[SUCCESS] Scope validation PASSED")
    sys.exit(0)
'@

$tempPy = Join-Path $env:TEMP "bolt-validate-scopes.py"
Set-Content -Path $tempPy -Value $pyScript -Encoding UTF8

if ($python -eq 'python') {
    & python $tempPy
}
else {
    & py -3 $tempPy
}

exit $LASTEXITCODE
