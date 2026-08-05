# Wiki Order File Template

Order files (`.order`) control the sequence of pages in Azure DevOps wiki navigation sidebar.

## How It Works

- Place a `.order` file in each wiki folder
- List page names one per line (without .md extension)
- Pages appear in the sidebar in the order specified
- Pages not listed appear alphabetically after listed pages

## Example: ADR Ordering

**File**: `/Documentation/ADR/.order`

```text
ADR-0001-Adopt-DotNet-Aspire
ADR-0002-Azure-Simple-Architecture
ADR-0003-OpenTelemetry-Observability
```

## Example: Documentation Root Ordering

**File**: `/Documentation/.order`

```text
Architecture-Overview
Architecture-Quickstart
ADR
Observability
Feature-Plan
```

## Creating Order Files

### Option 1: Manual Creation

Create a `.order` file in your docs folder:

```powershell
# For ADR folder
@"
ADR-0001-Adopt-DotNet-Aspire
ADR-0002-Azure-Simple-Architecture
ADR-0003-OpenTelemetry-Observability
"@ | Out-File "docs/adr/.order" -Encoding UTF8
```

### Option 2: Generate from Existing Files

```powershell
# Auto-generate .order from existing markdown files
$files = Get-ChildItem "docs/adr" -Filter "ADR-*.md" |
    Sort-Object Name |
    ForEach-Object { $_.BaseName }

$files | Out-File "docs/adr/.order" -Encoding UTF8
```

### Option 3: Using MCP Tool

```javascript
// Create order file directly in wiki
const orderContent = `
ADR-0001-Adopt-DotNet-Aspire
ADR-0002-Azure-Simple-Architecture
ADR-0003-OpenTelemetry-Observability
`.trim();

await mcp_azure_devops_wiki_create_or_update_page({
  wikiIdentifier: 'Registro-Horario.wiki',
  project: 'Registro Horario',
  path: '/Documentation/ADR/.order',
  content: orderContent,
});
```

## Best Practices

1. **Consistent Naming**: Use same names as in wiki (without `.md`)
2. **Logical Grouping**: Order by importance or chronology
3. **Version Control**: Keep `.order` files in git alongside docs
4. **Sync Together**: Upload `.order` when you sync folder contents

## Syncing Order Files

The `Sync-DocsToWiki.ps1` script will automatically sync `.order` files if they exist in the docs folder.

```powershell
# Sync ADR folder including .order file
.\scripts\powershell\Sync-DocsToWiki.ps1 `
  -SourcePath "docs/adr/" `
  -Recursive
```

## Examples for Different Sections

### Architecture Documentation

```text
Overview
Quickstart
System-Architecture
Component-Design
Data-Model
Deployment-Guide
```

### ADR (Architecture Decision Records)

```text
README
ADR-0001-Technology-Choice
ADR-0002-Architecture-Pattern
ADR-0003-Database-Selection
ADR-0004-Authentication-Approach
```

### Observability

```text
Overview
OpenTelemetry-Guide
Metrics-Collection
Logging-Standards
Tracing-Setup
Monitoring-Dashboards
```

## Troubleshooting

**Issue**: Pages not appearing in specified order

**Solution**: Verify:

- File is named exactly `.order` (no extension)
- Page names match exactly (case-sensitive)
- No extra whitespace or blank lines
- File is UTF-8 encoded

**Issue**: Order file not syncing

**Solution**:

```powershell
# Explicitly create the order page
az devops wiki page create `
  --wiki "Registro-Horario.wiki" `
  --project "Registro Horario" `
  --path "/Documentation/ADR/.order" `
  --content (Get-Content "docs/adr/.order" -Raw)
```

## References

- [Azure DevOps Wiki Order Files](https://learn.microsoft.com/azure/devops/project/wiki/wiki-file-structure)
- [SKILL.md](../SKILL.md) - Azure Wiki Agent documentation
