---
name: bolt-testing
description: "Generate Bolt Framework test suites with coverage-first approach and mutation validation. Auto-creates unit/integration/E2E tests aligned with constitution thresholds (coverage ≥ 80%, mutation ≥ 70%). Triggers: 'generate tests', 'create test suite', 'TDD', 'BDD', 'coverage first', 'mutation testing', 'EXECUTE phase', '/bolt-testing'."
---

# Bolt Testing — Methodology

Generate test suites that achieve coverage targets and validate test quality
through mutation testing.

**Bolt Framework Stage**: EXECUTE (coverage-first approach)
**Responsible Agent**: Test Inspector

## Referenced skills

- `skill-bolt-branch-management` — branch context verification.
- `skill-bolt-testing-discipline` — TDD/BDD decision matrix and testing
  pyramid guidance.
- `skill-bolt-quality-gates` — coverage thresholds (80 % line, 75 % branch,
  70 % mutation).
- `bolt-smoke-testing` — smoke scenario classification and generation.
- `integration-e2e-testing` / `playwright-e2e` — integration and E2E testing
  patterns.

## Available scripts

- Bash: `.boltf/scripts/bash/generate-tests.sh`
- PowerShell: `.boltf/scripts/powershell/Generate-Tests.ps1`

## 🚀 Automatic execution

When user requests tests, automatically:

1. Verify branch (`feature/*`).
2. Read constitution → testing requirements and targets.
3. Read source code → analyze what needs testing.
4. Generate tests immediately.
5. Run tests and verify passing.

Do NOT ask for confirmation.

## Test pyramid by scenario

- **Unit (70 %)** — domain logic, value objects, pure functions.
- **Integration (20 %)** — repositories, handlers, DB roundtrips
  (`integration-e2e-testing`).
- **E2E (10 %)** — user flows via Playwright (`playwright-e2e`); mark
  critical paths `@smoke`.

## Thresholds (constitutional)

| Metric | Threshold | Tool |
|--------|-----------|------|
| Line coverage | ≥ 80 % | jest/dotnet cover |
| Branch coverage | ≥ 75 % | jest/dotnet cover |
| Mutation score | ≥ 70 % | Stryker / dotnet-stryker |

## Smoke classification

For each AC in `requirements.md`, evaluate with `bolt-smoke-testing` matrix.
Every P1 user story must have at least one `@smoke` test.

## Output

```markdown
✅ Generated: tests/unit/[Component].test.ts (or .cs)
✅ Tests: [N] tests created
✅ Coverage: [%]
✅ Mutation score: [%]
```

## Quality gates

- All new code paths covered.
- Mutation score over threshold.
- Smoke suite passes in < 60 s.

## Artifacts / templates literales

### Quality targets (full table)

| Metric | Minimum | Recommended | Critical Paths |
|--------|---------|-------------|----------------|
| Line Coverage | 80 % | 90 % | 100 % |
| Branch Coverage | 75 % | 85 % | 100 % |
| Mutation Score | 70 % | 80 % | 90 % |
| Critical Paths | 100 % | 100 % | 100 % |

### Mutation testing tools by language

| Language | Mutation Tool | Coverage Tool | Config File |
|----------|---------------|---------------|-------------|
| **Java** | PIT (Pitest) | JaCoCo | `pom.xml` / `build.gradle` |
| **.NET / C#** | Stryker.NET | coverlet | `stryker-config.json` |
| **JavaScript** | Stryker Mutator | Istanbul / NYC | `stryker.conf.js` |
| **TypeScript** | Stryker Mutator | Istanbul / NYC | `stryker.conf.js` |
| **Python** | mutmut | coverage.py | `pyproject.toml` |
| **Go** | go-mutesting | `go test -cover` | `Makefile` |

### TDD vs BDD decision matrix

| Scenario | Approach | Command |
|----------|----------|---------|
| User story with ACs | **BDD** | Use `bolt-gherkin` |
| New algorithm / utility | **TDD** | Use `bolt-testing` (tdd) |
| Existing untested code | **Coverage-First** | Use `bolt-testing` (coverage) |
| Bug fix | **TDD** | Use `bolt-testing` (tdd) |
| API endpoint | **BDD + Contract** | Use `bolt-gherkin` |
| Domain entity | **TDD** | Use `bolt-testing` (tdd) |
| **Legacy a modernizar (brownfield)** | **Caracterización / Equivalencia (modo oráculo)** | Use `skill-characterization-testing` |

### Modo oráculo legacy (brownfield)

Cuando el objetivo es **modernizar código legacy**, el flujo TDD forward NO basta: hay que
**fijar el comportamiento del legacy** y probar la equivalencia del código nuevo.

- **El legacy es el oráculo**: captura sus salidas reales (golden master) o monta un arnés de
  parity que ejecute legacy y moderno con el mismo input y compare.
- Toma las reglas `RULE-NNN` de `bolt-legacy-analyst` (las P0 = behavior contract).
- Genera la suite con la skill **`skill-characterization-testing`** y reporta cobertura de
  comportamiento legacy + equivalence pass rate → alimenta el **gate de equivalencia** de
  `skill-bolt-quality-gates`.
- Discrepancias = defectos sospechosos: escalar a SME, no replicar a ciegas.

> Equivalente Claude (plugin `code-modernization`): agente `test-engineer`. Esta capacidad es
> nativa y dual-client en Bolt vía `skill-characterization-testing`.

### Test category examples

#### Unit test (TypeScript / Jest)

```typescript
// tests/unit/domain/entities/user.test.ts
import { User } from '@/domain/entities/user';
import { Email } from '@/domain/value-objects/email';

describe('User Entity', () => {
  describe('create', () => {
    it('should create user with valid data', () => {
      const props = { email: 'test@example.com', name: 'Test User' };
      const result = User.create(props);

      expect(result.success).toBe(true);
      expect(result.value.email.value).toBe(props.email);
    });

    it('should reject invalid email', () => {
      const result = User.create({ email: 'invalid-email', name: 'X' });
      expect(result.success).toBe(false);
      expect(result.error.code).toBe('INVALID_EMAIL');
    });
  });
});
```

#### Integration test (TypeScript)

```typescript
// tests/integration/repositories/user-repository.test.ts
describe('UserRepository', () => {
  let repository: UserRepository;
  let testDb: TestDatabase;

  beforeAll(async () => {
    testDb = await TestDatabase.create();
    repository = new UserRepositoryImpl(testDb);
  });

  afterAll(async () => {
    await testDb.cleanup();
  });

  it('should persist and retrieve user', async () => {
    const user = User.create({ email: 'test@example.com', name: 'Test' });
    await repository.save(user.value);
    const retrieved = await repository.findById(user.value.id);

    expect(retrieved).not.toBeNull();
    expect(retrieved?.email.value).toBe('test@example.com');
  });
});
```

#### E2E test (Playwright)

```typescript
// tests/e2e/user-registration.test.ts
describe('User Registration Flow', () => {
  it('should complete registration successfully', async () => {
    await page.goto('/register');
    await page.fill('[name="email"]', 'new@example.com');
    await page.fill('[name="password"]', 'SecurePass123!');
    await page.click('[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('.welcome')).toContainText('Welcome');
  });
});
```

### Execution commands

```bash
# Run all tests with coverage
npm test -- --coverage
# or: dotnet test /p:CollectCoverage=true

# Run specific category
npm test -- --testPathPattern=unit
npm test -- --testPathPattern=integration

# Mutation testing
npx stryker run
# or: dotnet stryker

# Smoke-only (pre-deploy / merge to main)
dotnet test --filter "Category=smoke"
npm run test:e2e:smoke   # playwright test --grep @smoke --config=playwright.config.ts
```

### Smoke Test Verification Step (MANDATORY when generating BDD/E2E)

Verify that the `@smoke` scenarios in the `.feature` files have full
implementation in step definitions and/or Playwright tests.

1. List `@smoke` scenarios:
   `grep -n "@smoke" specs/[XXX]/tests/*.feature`.
2. Verify each one has its step definition / Playwright test.
3. Execute the smoke suite and confirm pass:
   `dotnet test --filter "Category=smoke"` (or the stack's equivalent command).
4. For Playwright, verify or create entry in
   `e2e/tests/smoke/smoke-features.spec.ts`.

If any `@smoke` scenario fails, **it must be resolved before continuing**
with the rest of the quality gates. Use `bolt-smoke-testing` for the full
guide.

### Output template (detailed)

```markdown
## Tests Generated

**Feature**: [XXX-feature-name]
**Files Created**: [N]

**Test Summary**:
| Category | Tests | Coverage |
|----------|-------|----------|
| Unit | [N] | [X] % |
| Integration | [N] | [X] % |
| E2E | [N] | [X] % |
| **Smoke** | **[N]** | **—** |

**Smoke Suite**:
- Backend: `dotnet test --filter "Category=smoke"` → [N] tests, [X] s
- Frontend: `npm run test:e2e:smoke` → [N] tests, [X] s

**Quality Metrics**:
- Line Coverage: [X] % (target: 80 %)
- Branch Coverage: [X] % (target: 75 %)
- Mutation Score: [X] % (target: 70 %)

**Next Steps**:
1. Run mutation testing for quality validation
2. Use bolt-review to verify test quality
3. Proceed to next implementation phase
```

## Related agents (next steps)

- → `bolt-implement`: TDD green phase (make tests pass).
- → `bolt-gherkin`: BDD scenarios for new feature.
- → `bolt-review`: quality review of test code.
- → `bolt-analyze`: run quality gates.

## References

- `.github/prompts/bolt-test-generation.prompt.md`
