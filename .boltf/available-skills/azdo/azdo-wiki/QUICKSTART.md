# Azure Wiki Agent - Quick Start Guide

Get started with wiki synchronization in 5 minutes.

## Step 1: Install Prerequisites (2 min)

```powershell
# Install Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Verify installation
mmdc --version
az devops --version
```

## Step 2: Configure Authentication (1 min)

```powershell
# Set your Azure DevOps PAT
$env:AZURE_DEVOPS_EXT_PAT = "your-personal-access-token"

# Configure default project
az devops configure -d project="Registro Horario"
```

💡 **Get PAT**: <https://dev.azure.com/jdmveira/_usersSettings/tokens>

## Step 3: Test Sync (1 min)

```powershell
# Dry run to preview
.\scripts\powershell\Sync-DocsToWiki.ps1 `
  -SourcePath "docs/architecture-overview.md" `
  -DryRun

# Actually sync
.\scripts\powershell\Sync-DocsToWiki.ps1 `
  -SourcePath "docs/architecture-overview.md"
```

## Step 4: Sync All Docs (1 min)

```powershell
# Sync everything under docs/
.\scripts\powershell\Sync-DocsToWiki.ps1 `
  -SourcePath "docs/" `
  -Recursive
```

## Common Tasks

### Sync ADRs Only

```powershell
.\scripts\powershell\Sync-DocsToWiki.ps1 -SourcePath "docs/adr/" -Recursive
```

### Check What Will Change

```powershell
.\scripts\powershell\Sync-DocsToWiki.ps1 -SourcePath "docs/" -Recursive -DryRun
```

### View Wiki

```text
https://dev.azure.com/jdmveira/Registro%20Horario/_wiki
```

## Using MCP Tools

```javascript
// List wikis
mcp_azure_devops_wiki_list_wikis({ project: 'Registro Horario' });

// Create/update page
mcp_azure_devops_wiki_create_or_update_page({
  wikiIdentifier: 'Registro-Horario.wiki',
  project: 'Registro Horario',
  path: '/Documentation/My-Page',
  content: '# My Page\n\nContent...',
});
```

## Troubleshooting

| Problem                   | Solution                                     |
| ------------------------- | -------------------------------------------- |
| `mmdc: command not found` | Run `npm install -g @mermaid-js/mermaid-cli` |
| `PAT not configured`      | Set `$env:AZURE_DEVOPS_EXT_PAT`              |
| Permission denied         | Check PAT has Wiki write permissions         |

## Next Steps

- 📖 Read [SKILL.md](SKILL.md) for complete documentation
- 💡 See [examples/README.md](examples/README.md) for more use cases
- 🔧 Review [templates/order-file-template.md](templates/order-file-template.md) for navigation ordering

---

⚡ **Ready to sync!** Run the script and check your wiki.
