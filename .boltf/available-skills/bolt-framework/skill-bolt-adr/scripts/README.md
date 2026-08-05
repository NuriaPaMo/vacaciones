# ADR Number Scripts

Utility scripts to find the next available ADR number in a project.

## Available Scripts

| Script                   | Platform                 | Description                               |
| ------------------------ | ------------------------ | ----------------------------------------- |
| `get-next-adr-number.sh` | Linux / macOS / WSL      | Bash script to find next ADR number       |
| `Get-NextAdrNumber.ps1`  | Windows / Cross-platform | PowerShell script to find next ADR number |

## Usage

### Bash (Linux / macOS / WSL)

```bash
# From project root
NUM=$(.claude/skills/bolt-adr/scripts/get-next-adr-number.sh)
echo "Next ADR number: $NUM"

# Custom ADR directory
NUM=$(.claude/skills/bolt-adr/scripts/get-next-adr-number.sh docs/decisions)
```

### PowerShell (Windows / Cross-platform)

```powershell
# From project root
$Num = .\.claude\skills\bolt-adr\scripts\Get-NextAdrNumber.ps1
Write-Host "Next ADR number: $Num"

# Custom ADR directory
$Num = .\.claude\skills\bolt-adr\scripts\Get-NextAdrNumber.ps1 -AdrDirectory "docs/decisions"
```

## How It Works

Both scripts:

1. Scan the ADR directory for files matching pattern `ADR-*.md`
2. Extract the numeric portion from each filename
3. Find the highest number
4. Return the next number formatted as 4 digits with leading zeros (e.g., `0001`, `0042`, `0123`)

## Output Format

Both scripts output a 4-digit string with leading zeros:

- If no ADRs exist: `0001`
- If last ADR is `ADR-0005`: `0006`
- If last ADR is `ADR-0099`: `0100`

## Integration with ADR Creation

These scripts are used by the main ADR creation scripts:

- `.boltf/scripts/bash/create-adr.sh` uses `get-next-adr-number.sh`
- `.boltf/scripts/powershell/Create-ADR.ps1` uses `Get-NextAdrNumber.ps1`

## Cross-Platform Detection

For scripts that need to work on any OS:

```bash
#!/bin/bash
# Auto-detect OS and use appropriate script
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash)
    NUM=$(powershell.exe -File .claude/skills/bolt-adr/scripts/Get-NextAdrNumber.ps1)
else
    # Linux / macOS / WSL
    NUM=$(.claude/skills/bolt-adr/scripts/get-next-adr-number.sh)
fi
```

## Permissions

Make sure the bash script is executable:

```bash
chmod +x .claude/skills/bolt-adr/scripts/get-next-adr-number.sh
```

## Error Handling

- If ADR directory doesn't exist, both scripts return `0001`
- If no ADR files exist, both scripts return `0001`
- Scripts exit with error code 0 on success

## Testing

```bash
# Test bash script
.claude/skills/bolt-adr/scripts/get-next-adr-number.sh
# Expected output: 0001 (if no ADRs exist)

# Test PowerShell script
.\.claude\skills\bolt-adr\scripts\Get-NextAdrNumber.ps1
# Expected output: 0001 (if no ADRs exist)
```

---

**Version**: 1.0.0
**Part of**: bolt-adr
**Updated**: 2026-02-13
