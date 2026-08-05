---
name: skill-bolt-branch-management
description: "Bolt micro-iteration branching pattern with feature/bolt hierarchy (feature/XXX-name/bolt-N). MANDATORY before implementing any Bolt iteration. Use before creating feature branches or managing Bolt branch workflows. Triggers => 'create bolt branch', 'branch pattern', 'feature branch Bolt', 'bolt iteration branch', 'micro-iteration workflow', 'bolt hierarchy', 'branch naming Bolt', 'feature/bolt pattern'. Required for each Bolt iteration."
---

# BOLT Branch Management

## When to Use

- Before implementing any BOLT iteration
- Creating feature branches
- Verifying correct branch context

## BOLT Branching Pattern

**Two-Level Hierarchy:**

```bash
feature/[feature-name]                              # Feature branch (parent)
  └── feature/[feature-name]/bolt-[N]-[description] # BOLT branch (child)
```

**Examples:**

```bash
feature/calculator-modernization
  ├── feature/calculator-modernization/bolt-1-foundation
  ├── feature/calculator-modernization/bolt-2-domain
  ├── feature/calculator-modernization/bolt-3-api
  └── feature/calculator-modernization/bolt-4-polish

feature/user-auth
  ├── feature/user-auth/bolt-1-domain
  ├── feature/user-auth/bolt-2-api-layer
  └── feature/user-auth/bolt-3-persistence
```

## Branch Creation Workflow

### 1. Verify Current Branch (MANDATORY)

**BEFORE implementing any BOLT:**

```bash
# Check current branch
git branch --show-current

# Expected: feature/[feature-name]
# If on main/develop, STOP!
```

**Automated Verification:**

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ ! "$CURRENT_BRANCH" =~ ^feature/ ]]; then
    echo "ERROR: Not on a feature branch!"
    echo "Current: $CURRENT_BRANCH"
    exit 1
fi
```

### 2. AUTO-CREATE BOLT Branch

```bash
# Get current feature branch name
CURRENT_BRANCH=$(git branch --show-current)

# Create BOLT branch
# Pattern: feature/[feature-name]/bolt-[N]-[description]
git checkout -b "${CURRENT_BRANCH}/bolt-[N]-[description]"
```

### 3. Implementation Rules

- **Each BOLT = New Branch** (mandatory)
- **Complete BOLT before merge** to feature branch
- **Incremental PRs** for review
- **Quality gates** on each BOLT branch
- **Never implement on main/develop**

## BOLT Examples by Type

### Bolt 1: Foundation (1-2 days)

- Project setup, Database schema, Base entities

### Bolt 2: Core Domain (2-3 days)

- Domain entities, Business logic, Unit tests

### Bolt 3: API Layer (2-3 days)

- Controllers/Endpoints, DTOs, Integration tests

### Bolt 4: UI/Integration (2-3 days)

- Frontend components, API integration, E2E tests

## Error Handling

**If NOT on feature branch:**

1. **STOP** - Do not implement on main/develop
2. **Create feature branch**: `./.boltf/scripts/bash/create-new-feature.sh "[feature-name]"`
3. **Then create BOLT branch** following pattern above

## References

- @bolt-implement agent (BOLT branch auto-creation)
- @bolt-plan agent (BOLT strategy documentation)
