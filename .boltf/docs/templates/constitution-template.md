# Project Constitution

> **Project DNA** - The single source of truth for project governance, standards, and constraints.

**Project Name:** {PROJECT_NAME}
**Version:** 1.0.0
**Created:** {DATE}
**Last Updated:** {DATE}
**Status:** [Draft | Active | Archived]

---

## 1. Project Identity

### Vision

{One sentence describing the project's ultimate goal}

### Mission

{How this project will achieve the vision}

### Scope

- **In Scope:** {What the project will do}
- **Out of Scope:** {What the project will NOT do}

---

## 2. Technology Stack

### Languages

| Layer | Language | Version | Justification |
|-------|----------|---------|---------------|
| Backend | {language} | {version} | {why} |
| Frontend | {language} | {version} | {why} |
| Database | {language} | {version} | {why} |
| Scripts | {language} | {version} | {why} |

### Frameworks

| Purpose | Framework | Version | Justification |
|---------|-----------|---------|---------------|
| API | {framework} | {version} | {why} |
| UI | {framework} | {version} | {why} |
| ORM | {framework} | {version} | {why} |
| Testing | {framework} | {version} | {why} |

### Infrastructure

| Component | Technology | Justification |
|-----------|------------|---------------|
| Cloud | {AWS/Azure/GCP} | {why} |
| Container | {Docker/Podman} | {why} |
| Orchestration | {K8s/ECS/None} | {why} |
| CI/CD | {GitHub Actions/Jenkins} | {why} |

### External Services

| Service | Provider | Purpose |
|---------|----------|---------|
| {service} | {provider} | {purpose} |

---

## 3. Architecture

### Pattern

- [ ] Monolith
- [ ] Modular Monolith
- [ ] Microservices
- [ ] Serverless
- [ ] Event-Driven
- [ ] Hexagonal/Clean Architecture

### Layers

```text
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│         (API, UI, Controllers)          │
├─────────────────────────────────────────┤
│           Application Layer             │
│       (Use Cases, Services, DTOs)       │
├─────────────────────────────────────────┤
│             Domain Layer                │
│   (Entities, Value Objects, Events)     │
├─────────────────────────────────────────┤
│          Infrastructure Layer           │
│    (Repositories, External Services)    │
└─────────────────────────────────────────┘
```

### Key ADRs

| ADR | Title | Status |
|-----|-------|--------|
| ADR-001 | {title} | Accepted |

---

## 4. Coding Standards

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `UserService` |
| Methods | camelCase | `getUserById` |
| Variables | camelCase | `userName` |
| Constants | UPPER_SNAKE | `MAX_RETRIES` |
| Files | kebab-case | `user-service.ts` |
| Database Tables | snake_case | `user_accounts` |

### Code Style

- **Max line length:** {80/100/120}
- **Indentation:** {spaces/tabs} ({2/4})
- **Quotes:** {single/double}
- **Semicolons:** {yes/no}
- **Trailing commas:** {yes/no}

### Linting & Formatting

| Tool | Config File | Purpose |
|------|-------------|---------|
| ESLint/Pylint | {file} | Linting |
| Prettier/Black | {file} | Formatting |
| EditorConfig | .editorconfig | Editor settings |

---

## 5. Quality Gates

### Test Coverage

| Type | Minimum | Target |
|------|---------|--------|
| Unit Tests | {70%} | {85%} |
| Integration Tests | {50%} | {70%} |
| E2E Tests | {30%} | {50%} |
| Overall | {60%} | {80%} |

### Code Quality

| Metric | Threshold |
|--------|-----------|
| Cyclomatic Complexity | ≤ {10} |
| Cognitive Complexity | ≤ {15} |
| Duplication | ≤ {3%} |
| Technical Debt Ratio | ≤ {5%} |

### Performance

| Metric | Threshold |
|--------|-----------|
| API Response Time (p95) | ≤ {200ms} |
| Page Load Time | ≤ {3s} |
| Build Time | ≤ {5min} |

### Security

- [ ] OWASP Top 10 compliance
- [ ] Dependency vulnerability scanning
- [ ] Secret detection in commits
- [ ] SAST/DAST enabled

### Architecture Quality

> **"You can't test architecture with unit tests alone, but you can set objective quality gates that capture when the design is going off the rails."**

#### 5.1 Dependency Rules (Layer Enforcement)

| Rule | Description | Tool |
|------|-------------|------|
| Domain Isolation | Domain cannot import from Infrastructure/Presentation | dependency-cruiser / NetArchTest |
| No Circular Dependencies | Modules cannot have circular imports | madge / ArchUnitNET |
| Boundary Enforcement | Each module can only import from allowed dependencies | eslint-plugin-boundaries / NetArchTest |

**Configuration:**

- Node/TS: `.dependency-cruiser.cjs` or `eslint-plugin-boundaries` rules
- .NET: `ArchitectureTests.cs` with NetArchTest
- Java: ArchUnit rules in test suite

#### 5.2 Contract Validation

| Contract Type | Validation | Tool |
|---------------|------------|------|
| REST API | Implementation matches OpenAPI spec | openapi-diff / Spectral |
| Async Events | Events match AsyncAPI spec | asyncapi-cli |
| Consumer-Driven | Contracts between services | Pact |

**Configuration:**

- OpenAPI spec location: `specs/{feature}/contracts/openapi.yaml`
- Contract tests in: `src/{module}/__contracts__/`

#### 5.3 Complexity Metrics

| Metric | Threshold | Tool |
|--------|-----------|------|
| Cyclomatic Complexity (per function) | ≤ 10 | ESLint/SonarQube |
| Cognitive Complexity | ≤ 15 | SonarQube/CodeClimate |
| Max Function Lines | ≤ 50 | ESLint/Roslyn |
| Max File Lines | ≤ 400 | ESLint/Roslyn |
| Fan-out (dependencies per class) | ≤ 10 | dependency-cruiser/NDepend |

#### 5.4 Fitness Functions

| Fitness Function | Threshold | Measurement |
|------------------|-----------|-------------|
| No cycles between modules | 0 cycles | madge / dependency-cruiser |
| Cold start time | < 3s | Performance test |
| Domain testability | < 3 mocks per test | Test analysis |
| Build time | < 5 min | CI metrics |
| Bundle size (frontend) | < 500KB | webpack-bundle-analyzer |

#### 5.5 Thin Slice Integration Tests
>
> **Indicator:** If you need > 5 mocks to test a use case, architecture is leaking.

| Thin Slice | What it tests | Expected Mocks |
|------------|---------------|----------------|
| Happy path | Input → Use Case → Persistence → Output | ≤ 2 |
| Error path | Input → Validation Error → Error Response | 0 |
| External call | Use Case → External Service → Response | 1 (external service) |

---

## 6. Git Workflow

### Branching Strategy

- [ ] Git Flow
- [ ] GitHub Flow
- [ ] Trunk-Based Development

### Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/{ticket}-{description}` | `feature/ABC-123-user-auth` |
| Bugfix | `bugfix/{ticket}-{description}` | `bugfix/ABC-456-login-error` |
| Hotfix | `hotfix/{ticket}-{description}` | `hotfix/ABC-789-security-patch` |
| Release | `release/{version}` | `release/1.2.0` |

### Commit Messages

Format: `{type}({scope}): {description}`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example: `feat(auth): add JWT token refresh endpoint`

### Pull Requests

- Minimum reviewers: {1/2}
- Required checks: {list}
- Auto-merge: {yes/no}

---

## 7. Documentation Requirements

### Code Documentation

- [ ] JSDoc/Docstrings for public APIs
- [ ] README in each module
- [ ] Inline comments for complex logic

### Project Documentation

- [ ] API documentation (OpenAPI/Swagger)
- [ ] Architecture diagrams
- [ ] ADRs for significant decisions
- [ ] Runbooks for operations

---

## 8. Constraints

### Non-Negotiable

1. {constraint 1}
2. {constraint 2}
3. {constraint 3}

### Preferences

1. {preference 1}
2. {preference 2}

### Forbidden

1. {forbidden pattern/technology 1}
2. {forbidden pattern/technology 2}

---

## 9. Team Agreements

### Communication

- Primary channel: {Slack/Teams/Discord}
- Async-first: {yes/no}
- Response time: {hours}

### Meetings

| Meeting | Frequency | Duration |
|---------|-----------|----------|
| Standup | Daily | 15min |
| Planning | {frequency} | {duration} |
| Retro | {frequency} | {duration} |

### On-Call

- Rotation: {schedule}
- Escalation: {process}

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | {DATE} | {author} | Initial constitution |

---

*This constitution is the law of the project. Any deviation requires an ADR and team approval.*
