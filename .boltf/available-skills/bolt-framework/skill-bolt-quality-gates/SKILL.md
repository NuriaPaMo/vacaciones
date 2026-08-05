---
name: skill-bolt-quality-gates
description: Per-Bolt quality gates with code coverage, mutation testing, and linting thresholds. MANDATORY at the end of every Bolt iteration - no PR merge without passing gates. Use for enforcing quality standards, checking coverage, running mutation tests, or validating linting. Triggers => 'quality gates', 'coverage threshold', 'mutation testing', 'lint check', 'quality check', 'gate validation', 'Bolt gates', 'enforce quality'. NON-OPTIONAL checkpoint.
---

# Quality Gates

## When to Use

- At the end of every BOLT iteration (MANDATORY)
- Before merging BOLT branch to feature branch
- During CI/CD pipeline execution

## Quality Gate Thresholds

| Metric          | Minimum | Recommended | Critical Paths |
| --------------- | ------- | ----------- | -------------- |
| Line Coverage   | 80%     | 90%         | 100%           |
| Branch Coverage | 75%     | 85%         | 100%           |
| Mutation Score  | 70%     | 80%         | 90%            |
| Linting Errors  | 0       | 0           | 0              |
| Test Pass Rate  | 100%    | 100%        | 100%           |

## Scoped Mutation Testing (Default at Bolt/Feature Close)

Running mutation tests over the full solution is expensive. By default, scope the run to the
service/module of the active Bolt. Reserve full-solution runs for release gates only.

### Execution modes

| Mode | When | .NET command | Angular/TS command |
| ---- | ---- | ------------ | ------------------ |
| **Bolt-scope** | Bolt close (default) | `dotnet stryker --project <Svc>.Application.csproj --project <Svc>.Domain.csproj` | `npx stryker run --mutate "src/app/features/<name>/**/*.ts"` |
| **Feature-scope** | Feature PR gate | `dotnet stryker --project <Svc>.Api.csproj --project <Svc>.Application.csproj --project <Svc>.Domain.csproj` | `npx stryker run --mutate "src/app/features/<name>/**/*.ts"` |
| **Full-scope** | Release gate only | `dotnet stryker` | `npx stryker run` |

### Auto-detection from git branch

The `Quality-Gates` scripts and `Test-Mutation-*` scripts detect scope automatically:

```text
feature/my-feature/bolt-3-desc  →  service: MyFeature
                                   .NET: --project MyFeature.Application.csproj
                                         --project MyFeature.Domain.csproj
                                   Angular: --mutate "src/app/features/my-feature/**/*.ts"
```

If your service name doesn't follow `kebab-case → PascalCase`, add the mapping to `$ServiceNameMap`
in the Quality-Gates script or pass `-BoltScope <ServiceName>` / `--bolt-scope <name>` explicitly.
Pass `-BoltScope full` / `--bolt-scope full` to force a full-solution scan.

## MANDATORY Quality Gate Tasks

**Each BOLT MUST include these trackable tasks:**

| Task ID Pattern | Description                     | Command                                                                                                   | Threshold |
| --------------- | ------------------------------- | --------------------------------------------------------------------------------------------------------- | --------- |
| TXX-QG          | Run linting                     | `npm run lint` / `dotnet format`                                                                          | 0 errors  |
| TXX-QG          | Run all tests                   | `npm test` / `dotnet test`                                                                                | 100% pass |
| TXX-QG          | Run coverage report             | `npm run test:cov`                                                                                        | Generate  |
| TXX-QG          | Verify line coverage            | Check report                                                                                              | >= 80%    |
| TXX-QG          | Verify branch coverage          | Check report                                                                                              | >= 75%    |
| TXX-QG          | Run mutation tests (Bolt-scope) | `dotnet stryker --project <Svc>.Application.csproj --project <Svc>.Domain.csproj` / `npx stryker run --mutate "src/app/features/<name>/**/*.ts"` | Generate  |
| TXX-QG          | Verify mutation score           | Check report                                                                                              | >= 70%    |

## Mutation Testing Tools by Language

| Language       | Mutation Tool   | Coverage Tool  | Config File           |
| -------------- | --------------- | -------------- | --------------------- |
| **Java**       | PIT (Pitest)    | JaCoCo         | `pom.xml`             |
| **.NET/C#**    | Stryker.NET     | coverlet       | `stryker-config.json` |
| **JavaScript** | Stryker Mutator | Istanbul/NYC   | `stryker.conf.js`     |
| **TypeScript** | Stryker Mutator | Istanbul/NYC   | `stryker.conf.js`     |
| **Python**     | mutmut          | coverage.py    | `pyproject.toml`      |
| **Go**         | go-mutesting    | go test -cover | `Makefile`            |

## Setup (First BOLT Only)

### Node.js/TypeScript

```bash
npm install --save-dev @stryker-mutator/core @stryker-mutator/jest-runner @stryker-mutator/typescript-checker
npx stryker init
```

### .NET

```bash
dotnet tool install -g dotnet-stryker
dotnet stryker init
```

## Example Quality Gate Checklist

```markdown
### Quality Gates (MANDATORY)

- [ ] T009-QG Run linting: `npm run lint` or `dotnet format`
- [ ] T010-QG Run all tests: `npm test` or `dotnet test`
- [ ] T011-QG Run coverage report: `npm run test:cov`
- [ ] T012-QG Verify coverage >= 80% (constitution threshold)
- [ ] T013-QG Configure mutation testing tool (first Bolt only): `dotnet stryker init` / `npx stryker init`
- [ ] T014-QG Run mutation tests (Bolt-scope): `dotnet stryker --project <Svc>.Application.csproj --project <Svc>.Domain.csproj`
       or auto-scoped: `.boltf/scripts/powershell/Quality-Gates.ps1 -BoltScope <Svc>`
- [ ] T015-QG Verify mutation score >= 70%
```

> ℹ️ **Scoped execution is the default** at Bolt-close. Full-solution runs are reserved for
> release gates. Use `-BoltScope full` / `--bolt-scope full` to force a full run.

## Quality Gate Failure Policy

- **Coverage < 80%**: BOLT cannot be marked complete
- **Mutation Score < 70%**: Tests need improvement before proceeding
- **Any test failure**: Fix before next task
- **Linting errors**: Must resolve before merge

## References

- @bolt-tasks agent (Quality gate task generation)
- @bolt-testing agent (Coverage and mutation testing)
- `.boltf/memory/constitution.md` (Project thresholds)
