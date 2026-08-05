# Azure DevOps Work Item Mappings

This directory contains JSON mapping files that define how BOLT artifacts map to Azure DevOps work item types.

## Files

| File                                         | Work Item Type       | BOLT Artifact                                  |
| -------------------------------------------- | -------------------- | ---------------------------------------------- |
| [epic-mapping.json](epic-mapping.json)       | Epic                 | None - not directly managed in BOLT            |
| [feature-mapping.json](feature-mapping.json) | Feature              | `specs/XXX-feature-name/feature.md`            |
| [pbi-mapping.json](pbi-mapping.json)         | Product Backlog Item | User Stories in `requirements/requirements.md` |
| [task-mapping.json](task-mapping.json)       | Task                 | Bolt tasks in `planning/tasks.md`              |
| [bug-mapping.json](bug-mapping.json)         | Bug                  | Optional - manual tracking                     |
| [mapping-schema.json](mapping-schema.json)   | JSON Schema          | Validates all mapping files                    |

## Mapping Structure

Each mapping file defines:

### 1. Work Item Metadata

```json
{
  "workItemType": "Feature",
  "referenceName": "Microsoft.VSTS.WorkItemTypes.Feature",
  "description": "Tracks a feature that will be released",
  "color": "773B93",
  "icon": "icon_trophy",
  "boltArtifact": "specs/XXX-feature-name/feature.md"
}
```

### 2. Field Mappings

Field mappings are organized by category (core, planning, business, etc.):

```json
{
  "mappings": {
    "core": {
      "System.Title": {
        "boltSource": "feature.md#title",
        "description": "Feature title from BOLT artifact",
        "required": true,
        "transformation": null
      }
    }
  }
}
```

#### BOLT Source Types

- **`file.md#field`** - Direct extraction from BOLT file
  - Example: `feature.md#title`

- **`computed:formula`** - Computed from other values
  - Example: `computed:sum-user-story-effort`

- **`inherited:parent`** - Inherited from parent work item
  - Example: `inherited:parent-feature`

- **`null`** - No BOLT source (manual entry in DevOps)

#### Transformations

- **`null`** - No transformation, use value as-is
- **`markdown-to-html`** - Convert markdown to HTML
- **`html`** - Treat as HTML
- **`path`** - Format as DevOps path (e.g., `Project\Area\Subarea`)
- **`semicolon-separated`** - Format as semicolon-separated list for tags

### 3. Relationships

Defines parent-child and other link relationships:

```json
{
  "relationships": {
    "parent": {
      "linkType": "System.LinkTypes.Hierarchy-Reverse",
      "targetType": "Feature",
      "boltSource": "computed:parent-feature",
      "description": "Parent Feature work item",
      "required": true
    },
    "children": {
      "linkType": "System.LinkTypes.Hierarchy-Forward",
      "targetType": "Task",
      "boltSource": "planning/tasks.md#bolt-tasks",
      "description": "Child tasks"
    }
  }
}
```

### 4. Extraction Rules

Regex patterns for parsing BOLT artifacts:

```json
{
  "extractionRules": {
    "taskIdPattern": "^- \\[([ x])\\] \\*\\*(\\d{3}-[\\w-]+-\\d{3})\\*\\*",
    "estimatePattern": "\\((\\d+(?:\\.\\d+)?)h\\)",
    "checkboxStates": {
      "[ ]": "To Do",
      "[x]": "Done"
    }
  }
}
```

## Work Item Hierarchy

```text
Epic (optional, not BOLT-managed)
 └── Feature (from specs/XXX-feature-name/)
      ├── Product Backlog Item (from requirements.md)
      │    └── Task (from planning/tasks.md)
      ├── Product Backlog Item
      │    └── Task
      └── Bug (optional)
```

## Usage in Synchronization

### Push BOLT → Azure DevOps

1. **Read mapping file** for work item type
2. **Extract values** from BOLT artifacts using `boltSource`
3. **Apply transformations** (markdown-to-html, path formatting, etc.)
4. **Map values** using value mappings (e.g., High → 2)
5. **Create work item** with mapped fields
6. **Create relationships** (parent-child links)

### Pull Azure DevOps → Bolt Framework

1. **Query work item** from Azure DevOps
2. **Read mapping file** for work item type
3. **Reverse transformation** (HTML to markdown)
4. **Generate BOLT artifact** structure
5. **Populate fields** from work item values
6. **Store metadata** in `.metadata/devops-sync.json`

## State Mapping

### Feature States

| BOLT Phase   | Azure DevOps State |
| ------------ | ------------------ |
| DISCOVERY    | New                |
| PLANNING     | Active             |
| CONSTRUCTION | Active             |
| TRANSITION   | Resolved           |
| PRODUCTION   | Closed             |

### Product Backlog Item States

| Bolt Status | Azure DevOps State |
| ----------- | ------------------ |
| not-started | New                |
| planned     | Approved           |
| in-progress | Committed          |
| completed   | Done               |

### Task States

| BOLT Checkbox | Azure DevOps State |
| ------------- | ------------------ |
| `[ ]`         | To Do              |
| (in progress) | In Progress        |
| `[x]`         | Done               |

## Custom Fields

The following custom fields are available in the "Registro Horario" project:

### Security (Feature only)

- `Custom.ADPT20DataClassification`
- `Custom.ADPT20PersonalData`
- `Custom.ADPT20ThreatModeling`
- `Custom.ADPT20LoggingandMonitoring`
- `Custom.ADPT20AuthorizationRbac`
- `Custom.ADPT20AuthorizationPam`

### WSJF (Feature only)

- `Custom.ADPT30RiskReductionOE`
- `Custom.ADPT30CostOfDelay` (calculated)
- `Custom.ADPT30Wsjf` (calculated)

### Task Classification

- `Custom.ADPT30TaskType`
- `Custom.ADPT30IsBlocked`
- `Custom.ADPT30Organization`

## Validation

Validate mapping files against the schema:

```powershell
# PowerShell validation example
$schema = Get-Content "mapping-schema.json" | ConvertFrom-Json
$mapping = Get-Content "feature-mapping.json" | ConvertFrom-Json

# Or use JSON Schema validator tool
npm install -g ajv-cli
ajv validate -s mapping-schema.json -d "*.json"
```

## Extending Mappings

To add new fields:

1. **Identify Azure DevOps field** - Check work item type definition
2. **Determine BOLT source** - Where does this data come from?
3. **Add to mapping file** - Choose appropriate category
4. **Define transformation** - How to convert the data?
5. **Update scripts** - Modify sync scripts to use new mapping
6. **Test thoroughly** - Validate with dry-run and actual sync

## See Also

- [SKILL.md](../SKILL.md) - Complete Azure DevOps sync skill documentation
- [Sync-BoltToDevOps.ps1](../examples/Sync-BoltToDevOps.ps1) - Push sync script
- [Import-DevOpsToBolt.ps1](../examples/Import-DevOpsToBolt.ps1) - Pull sync script
- [Azure DevOps Work Item Types](https://learn.microsoft.com/en-us/azure/devops/boards/work-items/guidance/agile-process-workflow)

---

**Version**: 1.0.0
**Last Updated**: 2026-02-14
**BOLT Compatibility**: 1.0.0+
