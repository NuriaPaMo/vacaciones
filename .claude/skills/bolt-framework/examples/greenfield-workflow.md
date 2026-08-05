# Greenfield Workflow — New Project from Scratch

> Complete workflow example for starting a new project with Bolt Framework.

---

## Overview

```text
Init → Constitution → Feature → Plan → Tasks → [Bolt Loop] → Release
```

## Step-by-Step

### 1. Initialize Workspace

**PowerShell (Windows)**:

```powershell
.\Init.ps1 -ProjectName "my-app" -Type greenfield -Stack "react-dotnet"
```

**Bash (Linux/Mac/WSL)**:

```bash
./init.sh my-app green --scope full-stack --backend csharp --frontend react
```

This creates:

```text
my-app/
├── memory/
│   └── constitution.md    # Template — needs ratification
├── specs/
├── src/
├── scripts/
│   ├── bash/
│   └── powershell/
└── .github/
```

### 2. Define Constitution

Invoke `@Bolt Constitution`:

```text
"Define constitution for a React + .NET 8 API project with PostgreSQL,
clean architecture, 80% test coverage, and semantic versioning."
```

**Output**: Ratified `.boltf/memory/constitution.md` with:

- Tech stack (React, .NET 8, PostgreSQL)
- Architecture pattern (Clean Architecture)
- Testing requirements (≥80% coverage, ≥70% mutation score)
- Naming conventions
- Quality standards

### 3. Create First Feature

Invoke `@Bolt Feature`:

```text
"Create feature spec for user authentication with email/password login,
registration, and password reset."
```

**Output**: `specs/001-user-authentication/`

- `feature.md` — User stories, acceptance criteria
- `requirements/requirements.md` — Detailed requirements

### 4. Plan Implementation

Invoke `@Bolt Plan`:

```text
"Create implementation plan for feature 001-user-authentication."
```

**Output**: `specs/001-user-authentication/planning/plan.md`

- Architecture decisions
- Component breakdown
- Dependency map
- Risk assessment

### 5. Generate Tasks

Invoke `@Bolt Tasks`:

```text
"Generate Bolt task breakdown for the user authentication plan."
```

**Output**: `specs/001-user-authentication/planning/tasks.md`

```markdown
## Bolt 1: Domain Layer
- [ ] T001: Create User entity
- [ ] T002: Create Email value object
- [ ] T003: Create Password value object with hashing
- [ ] T004: Unit tests for domain

## Bolt 2: Application Layer
- [ ] T005: Create RegisterUser use case
- [ ] T006: Create LoginUser use case
- [ ] T007: Create ResetPassword use case
- [ ] T008: Unit tests for use cases

## Bolt 3: Infrastructure + API
- [ ] T009: PostgreSQL repository implementation
- [ ] T010: JWT token service
- [ ] T011: API controllers
- [ ] T012: Integration tests
```

### 6. Implement (Bolt Loop)

For each Bolt, invoke `@Bolt Implement`:

```text
"Implement Bolt 1 (Domain Layer) for user authentication."
```

The agent will:

1. Auto-create branch: `feature/001-user-auth/bolt-1-domain`
2. Read constitution for standards
3. Implement each task sequentially
4. Run tests after each task
5. Run quality gates
6. Mark tasks complete

### 7. Test & Review

After each Bolt:

- `@Bolt Testing` — Verify coverage meets thresholds
- `@Bolt Review` — Code review against constitution

### 8. Release

When all Bolts complete:

- `@Bolt Release` — Package, changelog, tag, deploy

---

## Timeline Example

| Day | Activity | Agent |
|-----|----------|-------|
| 1 | Init + Constitution | Constitution |
| 1 | Feature Spec | Feature |
| 2 | Plan + Tasks | Plan, Tasks |
| 2-3 | Bolt 1: Domain | Implement, Testing |
| 4-5 | Bolt 2: Application | Implement, Testing |
| 6-7 | Bolt 3: Infrastructure | Implement, Testing |
| 8 | Review + Release | Review, Release |
