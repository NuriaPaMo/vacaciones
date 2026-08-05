# Scope-Specific Questions Guide

## Overview

The initialization scripts (`Init.ps1` and `init.sh`) use a **scope-based conditional questioning system** that only asks relevant questions based on the active scopes selected during project initialization.

This guide explains how the system works and how to add new scope-specific questions.

---

## Architecture

### Helper Function: `Test-ScopeActive` (PowerShell) / `test_scope_active` (Bash)

**Purpose**: Check if any of the required scopes are active.

**PowerShell**:

```powershell
function Test-ScopeActive {
    param(
        [string[]]$Scopes,           # Array of active scopes
        [string[]]$RequiredScopes    # Array of required scopes (OR logic)
    )
    foreach ($required in $RequiredScopes) {
        if ($Scopes -contains $required) {
            return $true
        }
    }
    return $false
}
```

**Bash**:

```bash
test_scope_active() {
    # Usage: test_scope_active "backend frontend" "${D_SCOPES[@]}"
    # Returns: 0 (true) if any required scope is active, 1 (false) otherwise
    local required_scopes="$1"; shift
    local -a active_scopes=("$@")

    for required in $required_scopes; do
        for active in "${active_scopes[@]}"; do
            if [[ "$active" == "$required" ]]; then
                return 0  # true
            fi
        done
    done
    return 1  # false
}
```

---

## Current Scope-Question Mapping

| Scope(s) | Questions | Article | Reasoning |
|----------|-----------|---------|-----------|
| `cloud-platform` | VNet, Private Endpoints, WAF | §16.1 | Network security only applies to cloud infrastructure |
| `cloud-platform` | IaC Tool selection | §11.1b | Infrastructure as Code only needed for cloud deployments |
| `cloud-platform` | Infrastructure Pipeline Stages | §11.2 | IaC linting, validation only for infra |
| `cloud-platform` | Infrastructure Monitoring | §12.3 | Resource health, activity logs only for cloud resources |
| `backend`, `data`, `ai` | Encryption Keys, PII Handling | §16.2 | Data security applies to data-processing scopes |
| `backend`, `frontend`, `ai` | Application Pipeline Stages | §11.2 | Build, test, scan only for application code |
| `frontend` | Frontend Framework selection | Step 1.6 | Framework instructions only needed for frontend |
| **All scopes** | Compliance requirements | §16.3 | Compliance applies regardless of architecture |

---

## How to Add New Scope-Specific Questions

### Step 1: Identify the Scope Dependency

Determine which scope(s) require the question:

- **Single scope**: e.g., "frontend" for framework selection
- **Multiple scopes (OR logic)**: e.g., "backend OR data OR ai" for database questions
- **All scopes**: e.g., compliance, work management tool

### Step 2: Add the Conditional Block

#### PowerShell (`Init.ps1`)

```powershell
# Example: Add database selection for backend, data, ai scopes
$hasDatabaseScopes = Test-ScopeActive -Scopes $d.Scopes -RequiredScopes @("backend", "data", "ai")
if ($hasDatabaseScopes) {
    $d.DatabaseType = Read-Choice `
        -Title "§X.X  Primary database type" `
        -Options @(
            "Azure SQL Database (relational)",
            "Cosmos DB (NoSQL)",
            "PostgreSQL (open-source relational)",
            "MongoDB (document store)"
        ) `
        -Values @("azure-sql", "cosmos-db", "postgresql", "mongodb") `
        -Default 1

    Write-Success "Database: $($d.DatabaseType)"
} else {
    # Default value for projects without database scopes
    $d.DatabaseType = "none"
    Write-Info "Database selection — skipped (no backend/data/ai scope)"
}
```

#### Bash (`init.sh`)

```bash
# Example: Add database selection for backend, data, ai scopes
if test_scope_active "backend data ai" "${D_SCOPES[@]}"; then
    read_choice "§X.X  Primary database type" 1 \
        "Azure SQL Database (relational)" \
        "Cosmos DB (NoSQL)" \
        "PostgreSQL (open-source relational)" \
        "MongoDB (document store)" \
        --- "azure-sql" "cosmos-db" "postgresql" "mongodb"
    D_DATABASE_TYPE="$REPLY_CHOICE"

    log_success "Database: $D_DATABASE_TYPE"
else
    # Default value for projects without database scopes
    D_DATABASE_TYPE="none"
    log_info "Database selection — skipped (no backend/data/ai scope)"
fi
```

### Step 3: Update `scopes.yaml` Generation

Add the new decision to the YAML output in `New-ScopesYaml` (PowerShell) or `generate_scopes_yaml` (Bash):

**PowerShell**:

```powershell
# In New-ScopesYaml function
decisions:
  # ... existing sections ...

  # Database Configuration (new section)
  database:
    type: ${d.DatabaseType}
```

**Bash**:

```bash
# In generate_scopes_yaml function
decisions:
  # ... existing sections ...

  # Database Configuration (new section)
  database:
    type: ${D_DATABASE_TYPE}
```

### Step 4: Update Decision Variable Declaration

Add the variable at the top of the script:

**PowerShell** (`Init.ps1`):

```powershell
# In Get-AllDecisions function
$d = @{}
# ... existing variables ...
$d.DatabaseType = "none"  # Add new variable
```

**Bash** (`init.sh`):

```bash
# At top of script, in decision variables section
D_DATABASE_TYPE="none"  # Add new variable
```

---

## Best Practices

### 1. **Always Provide Default Values**

When skipping questions, set sensible defaults:

```powershell
if ($hasScope) {
    # Ask question
} else {
    $d.Value = "default-value"  # ✅ Always provide default
    Write-Info "Question — skipped (no X scope)"
}
```

### 2. **Use Consistent Naming**

- Variables: `$d.MyVariable` (PowerShell), `D_MY_VARIABLE` (Bash)
- YAML keys: `my-variable` (kebab-case)
- Scope names: `backend`, `frontend`, `cloud-platform` (lowercase, hyphenated)

### 3. **Group Related Questions**

Keep questions for the same scope/article together:

```powershell
# ── Article X — Database Configuration ─────────────────────────────
Write-Host ""
Write-Step "Article X — Database Configuration"

$hasDatabaseScopes = Test-ScopeActive -Scopes $d.Scopes -RequiredScopes @("backend", "data")
if ($hasDatabaseScopes) {
    # Ask all database-related questions here
    # 1. Database type
    # 2. Connection pooling
    # 3. Backup strategy
}
```

### 4. **Log Skipped Sections**

Always inform the user when questions are skipped:

```powershell
Write-Info "Database configuration — skipped (no backend/data scope)"
```

### 5. **Test Both Scripts**

Ensure changes are applied to **both** `Init.ps1` and `init.sh` for cross-platform consistency.

---

## Common Scope Combinations

| Use Case | Scope Check | Example |
|----------|-------------|---------|
| Cloud infrastructure | `cloud-platform` | IaC tools, networking |
| Application code | `backend`, `frontend`, `ai` | Build, test, lint |
| Data handling | `backend`, `data`, `ai` | Databases, encryption, PII |
| Web/mobile UI | `frontend` | Framework, bundler, state mgmt |
| External integrations | `integration` | API management, messaging |
| CRM/Power Platform | `crm` | Dataverse, plugins, canvas apps |

---

## Example: Adding CRM-Specific Questions

```powershell
# PowerShell
$hasCrmScope = Test-ScopeActive -Scopes $d.Scopes -RequiredScopes @("crm")
if ($hasCrmScope) {
    Write-Host ""
    Write-Step "CRM — Dynamics 365 Configuration"

    $d.CrmEdition = Read-Choice `
        -Title "Dynamics 365 edition" `
        -Options @("Customer Engagement", "Finance & Operations", "Business Central") `
        -Values @("ce", "fo", "bc") `
        -Default 1

    $d.CrmPlugins = Read-YesNo "Enable custom plugins?" $true

    $d.CrmPowerAutomate = Read-YesNo "Integrate Power Automate?" $true
} else {
    $d.CrmEdition = "none"
    $d.CrmPlugins = $false
    $d.CrmPowerAutomate = $false
}
```

---

## Testing Your Changes

1. **Run initialization with different scope combinations**:

   ```powershell
   # Test 1: Apps & Infra practice (backend + frontend + cloud-platform)
   ./Init.ps1 -OutputDirectory "./test-apps-infra" -ProjectType green

   # Test 2: Data & AI practice (data + ai + integration)
   ./Init.ps1 -OutputDirectory "./test-data-ai" -ProjectType green

   # Test 3: Custom with single scope
   ./Init.ps1 -OutputDirectory "./test-frontend-only" -ProjectType green
   ```

2. **Verify questions are asked/skipped correctly**:
   - ✅ Questions only appear for active scopes
   - ✅ Default values set when questions are skipped
   - ✅ Skip messages logged to console
   - ✅ `scopes.yaml` contains all decision values

3. **Check cross-platform consistency**:

   ```bash
   # Test Bash script with same scenarios
   ./init.sh --output "./test-apps-infra-bash" --type green
   ```

---

## Troubleshooting

### Question appears for wrong scope

**Symptom**: Question asked even when scope is not active.
**Fix**: Check `Test-ScopeActive` / `test_scope_active` call:

```powershell
# Wrong: Missing scope check
$d.Value = Read-Choice ...

# Correct: Add conditional check
$hasScope = Test-ScopeActive -Scopes $d.Scopes -RequiredScopes @("backend")
if ($hasScope) {
    $d.Value = Read-Choice ...
}
```

### Variable not found in scopes.yaml

**Symptom**: Decision value missing from generated YAML.
**Fix**: Add to `New-ScopesYaml` / `generate_scopes_yaml`:

```powershell
decisions:
  my-section:
    my-value: ${d.MyValue}  # Add this line
```

### Bash script out of sync with PowerShell

**Symptom**: Questions differ between `Init.ps1` and `init.sh`.
**Fix**: Apply the same changes to both scripts. Use this guide as reference.

---

## Future Enhancements

### Planned Features

1. **Scope Dependencies**: Automatically activate dependent scopes
   - Example: `ai` → auto-activate `backend`
   - Example: `data` → require `cloud-platform` or `backend`

2. **Question Presets**: Pre-defined question bundles per practice
   - Example: "Apps & Infra" → cloud networking questions enabled by default

3. **YAML-Driven Questions**: Define questions in YAML config files
   - Easier to maintain and version
   - No code changes needed for new questions

4. **Validation Rules**: Enforce constraints
   - Example: "If encryption = 'customer-managed', Key Vault is required"

---

**Version**: 2.0.0
**Last Updated**: 2026-03-14
**Maintained by**: Bolt Framework Team
