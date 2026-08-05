# CI/CD Integration & Performance Optimization

Complete guide for running integration tests with Testcontainers in CI/CD pipelines and optimizing
performance.

## CI/CD Setup

### GitHub Actions

```yaml
# .github/workflows/integration-tests.yml

name: Integration Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  integration-tests:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: "8.0.x"

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore --configuration Release

      - name: Run Integration Tests
        run: |
          dotnet test tests/**/*.IntegrationTests.csproj \
            --no-build \
            --configuration Release \
            --logger "trx;LogFileName=integration-tests.trx" \
            --collect:"XPlat Code Coverage" \
            --results-directory ./test-results/integration

      - name: Generate Coverage Report
        if: always()
        uses: danielpalme/ReportGenerator-GitHub-Action@5.1.23
        with:
          reports: "./test-results/integration/**/coverage.cobertura.xml"
          targetdir: "./test-results/integration/report"
          reporttypes: "Html;TextSummary"

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: integration-test-results
          path: ./test-results/integration

      - name: Comment Coverage on PR
        if: github.event_name == 'pull_request'
        uses: 5monkeys/cobertura-action@v13
        with:
          path: "./test-results/integration/**/coverage.cobertura.xml"
          minimum_coverage: 80
```

### Azure Pipelines

```yaml
# azure-pipelines.yml

trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: "ubuntu-latest"

variables:
  buildConfiguration: "Release"

steps:
  - task: UseDotNet@2
    displayName: "Setup .NET SDK"
    inputs:
      version: "8.0.x"

  - task: DotNetCoreCLI@2
    displayName: "Restore NuGet packages"
    inputs:
      command: "restore"

  - task: DotNetCoreCLI@2
    displayName: "Build solution"
    inputs:
      command: "build"
      arguments: "--configuration $(buildConfiguration) --no-restore"

  - task: DotNetCoreCLI@2
    displayName: "Run Integration Tests"
    inputs:
      command: "test"
      projects: "tests/**/*.IntegrationTests.csproj"
      arguments: >
        --configuration $(buildConfiguration) --no-build --logger trx --collect:"XPlat Code
        Coverage" --results-directory $(Agent.TempDirectory)/TestResults/Integration

  - task: PublishTestResults@2
    displayName: "Publish Test Results"
    condition: always()
    inputs:
      testResultsFormat: "VSTest"
      testResultsFiles: "$(Agent.TempDirectory)/TestResults/Integration/**/*.trx"
      mergeTestResults: true
      testRunTitle: "Integration Tests"

  - task: PublishCodeCoverageResults@1
    displayName: "Publish Coverage"
    condition: always()
    inputs:
      codeCoverageTool: "Cobertura"
      summaryFileLocation: "$(Agent.TempDirectory)/TestResults/Integration/**/coverage.cobertura.xml"
      reportDirectory: "$(Agent.TempDirectory)/TestResults/Integration/Coverage"
```

### GitLab CI

```yaml
# .gitlab-ci.yml

stages:
  - test

variables:
  DOTNET_VERSION: "8.0"

integration-tests:
  stage: test
  image: mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_TLS_CERTDIR: ""
  before_script:
    - dotnet restore
    - dotnet build --configuration Release --no-restore
  script:
    - |
      dotnet test tests/**/*.IntegrationTests.csproj \
        --configuration Release \
        --no-build \
        --logger "junit;LogFileName=integration-tests.xml" \
        --collect:"XPlat Code Coverage" \
        --results-directory ./test-results/integration
  artifacts:
    when: always
    paths:
      - test-results/integration/
    reports:
      junit: test-results/integration/**/integration-tests.xml
      coverage_report:
        coverage_format: cobertura
        path: test-results/integration/**/coverage.cobertura.xml
  coverage: '/Total\s+\|\s+(\d+\.?\d*)%/'
```

## Performance Optimization

### Strategy 1: Shared Container (Fastest)

**Use when**: Test suite has 20+ tests

```csharp
// File: tests/Tests.Shared/DatabaseFixture.cs

public class DatabaseFixture : IAsyncLifetime
{
    private MsSqlContainer? _container;
    private Respawner? _respawner;

    public string ConnectionString { get; private set; } = string.Empty;
    public DbContextOptions<YourDbContext> DbContextOptions { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        // Container starts ONCE for entire suite
        _container = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("YourStrong!Passw0rd")
            .Build();

        await _container.StartAsync();
        ConnectionString = _container.GetConnectionString();

        DbContextOptions = new DbContextOptionsBuilder<YourDbContext>()
            .UseSqlServer(ConnectionString)
            .Options;

        await using var context = new YourDbContext(DbContextOptions);
        await context.Database.MigrateAsync();

        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();

        _respawner = await Respawner.CreateAsync(connection, new RespawnerOptions
        {
            DbAdapter = DbAdapter.SqlServer,
            SchemasToInclude = new[] { "dbo" },
            TablesToIgnore = new[] { new Table("__EFMigrationsHistory") }
        });
    }

    public async Task DisposeAsync()
    {
        if (_container != null)
        {
            await _container.StopAsync();
            await _container.DisposeAsync();
        }
    }

    public async Task ResetDatabaseAsync()
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();
        await _respawner!.ResetAsync(connection);
    }
}

[CollectionDefinition("Database")]
public class DatabaseCollection : ICollectionFixture<DatabaseFixture> { }
```

**Performance Impact**:

- Container startup: 10s (once)
- Per test: ~0.3s (Respawn reset)
- **50 tests**: ~25s total

### Strategy 2: Parallel Execution

xUnit runs test classes in parallel by default. For isolation:

```csharp
// Each collection runs in parallel with its own container
[Collection("Database1")]
public class UserTests : IntegrationTestBase { }

[Collection("Database2")]
public class OrderTests : IntegrationTestBase { }

[Collection("Database3")]
public class InvoiceTests : IntegrationTestBase { }
```

**Performance Impact**:

- 3 collections × 10s startup = 30s
- Tests within collection: sequential
- **Total**: Faster if classes can run in parallel

### Strategy 3: Test Categorization

```csharp
// Mark fast vs slow tests
public class FastUserTests : IntegrationTestBase
{
    [Fact]
    [Trait("Category", "Fast")]
    public async Task FastTest() { }
}

public class SlowImportTests : IntegrationTestBase
{
    [Fact]
    [Trait("Category", "Slow")]
    public async Task SlowImportTest()
    {
        // Long-running import simulation
    }
}
```

**Run only fast tests in PR checks**:

```bash
dotnet test --filter "Category=Fast"
```

**Run all tests in main builds**:

```bash
dotnet test
```

## Performance Benchmarks

### Scenario: 50 Integration Tests

| Approach                       | Setup    | Per Test | Total    | Notes                 |
| ------------------------------ | -------- | -------- | -------- | --------------------- |
| Container per test             | 10s × 50 | 5s       | ~750s    | **SLOW** ❌           |
| Shared container, no Respawn   | 10s      | 2s       | ~110s    | FK issues             |
| **Shared container + Respawn** | **10s**  | **0.3s** | **~25s** | **Optimal** ✅        |
| Parallel (3 collections)       | 30s      | 0.3s     | ~40s     | Good for large suites |

### Expected Times on CI

| Environment     | Container Start | Migration | Per Test | 50 Tests Total |
| --------------- | --------------- | --------- | -------- | -------------- |
| Local (SSD)     | 5s              | 2s        | 0.2s     | ~17s           |
| GitHub Actions  | 8s              | 3s        | 0.4s     | ~31s           |
| Azure Pipelines | 10s             | 4s        | 0.5s     | ~39s           |
| GitLab CI       | 12s             | 5s        | 0.6s     | ~47s           |

## Coverage Requirements

### Target Metrics

- **Infrastructure Layer**: >= 80% coverage
- **Repository Tests**: >= 90% coverage
- **Event Handlers**: >= 85% coverage
- **E2E Critical Flows**: >= 95% coverage

### Verification Commands

```bash
# Run tests with coverage
dotnet test tests/**/*.IntegrationTests.csproj \
    --collect:"XPlat Code Coverage" \
    --results-directory ./test-results/integration

# Generate HTML report
reportgenerator \
    -reports:"./test-results/integration/**/coverage.cobertura.xml" \
    -targetdir:"./test-results/integration/report" \
    -reporttypes:"Html;TextSummary;Badges"

# View summary
cat ./test-results/integration/report/Summary.txt

# Enforce minimum coverage (fails if < 80%)
reportgenerator \
    -reports:"./test-results/integration/**/coverage.cobertura.xml" \
    -targetdir:"./test-results/integration/report" \
    -reporttypes:"TextSummary" \
    -fail-if-coverage:Infrastructure:80
```

### Coverage Report Example

```text
Summary
  Generated on: 2026-02-08 - 14:30:15
  Parser: Cobertura
  Assemblies: 3
  Classes: 24
  Files: 24
  Line coverage: 87.2% (1,234 of 1,415)
  Branch coverage: 82.3% (178 of 216)
  Method coverage: 89.5% (85 of 95)

Coverage
  Infrastructure.Repositories: 92.4%
  Infrastructure.Persistence: 84.1%
  Infrastructure.EventHandlers: 81.2%
```

## Quality Gates

### Pre-Commit Checks

```bash
#!/bin/bash
# scripts/pre-commit-integration-tests.sh

echo "Running integration tests..."

dotnet test tests/**/*.IntegrationTests.csproj \
    --configuration Debug \
    --logger "console;verbosity=minimal" \
    --collect:"XPlat Code Coverage"

TEST_RESULT=$?

if [ $TEST_RESULT -ne 0 ]; then
    echo "❌ Integration tests FAILED!"
    exit 1
fi

echo "✅ Integration tests PASSED!"
exit 0
```

### PR Checks

```yaml
# .github/workflows/pr-check.yml

name: PR Check

on:
  pull_request:
    branches: [main]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3

      - name: Run Tests
        run: |
          dotnet test tests/**/*.IntegrationTests.csproj \
            --configuration Release \
            --collect:"XPlat Code Coverage"

      - name: Check Coverage
        run: |
          reportgenerator \
            -reports:"**/coverage.cobertura.xml" \
            -targetdir:"./coverage" \
            -reporttypes:"TextSummary" \
            -fail-if-coverage:Infrastructure:80

      - name: Comment on PR
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '❌ Integration tests failed or coverage below 80%'
            })
```

## Troubleshooting CI/CD

### Issue 1: Docker Not Available

**GitHub Actions**: Use `ubuntu-latest` (Docker pre-installed)

```yaml
runs-on: ubuntu-latest # Docker available by default
```

**Azure Pipelines**: Use Microsoft-hosted agents

```yaml
pool:
  vmImage: "ubuntu-latest" # Docker available
```

### Issue 2: Timeout in CI

**Cause**: Slow container startup on shared runners

**Solution**: Increase timeout

```csharp
_mssqlContainer = new MsSqlBuilder()
    .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
    .WithPassword("YourStrong!Passw0rd")
    .WithStartupTimeout(TimeSpan.FromMinutes(3)) // CI needs more time
    .Build();
```

### Issue 3: Out of Memory

**Cause**: Too many parallel containers

**Solution**: Limit parallelism

```bash
dotnet test --parallel none # Run sequentially
```

Or configure xUnit:

```json
// xunit.runner.json
{
  "maxParallelThreads": 2, // Limit to 2 parallel collections
  "parallelizeTestCollections": true
}
```

### Issue 4: Intermittent Failures

**Cause**: Race conditions in database reset

**Solution**: Add retry logic

```csharp
protected async Task ResetDatabaseAsync()
{
    var retries = 3;
    while (retries > 0)
    {
        try
        {
            await using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            await _respawner!.ResetAsync(connection);
            return;
        }
        catch (Exception)
        {
            retries--;
            if (retries == 0) throw;
            await Task.Delay(100);
        }
    }
}
```

## Best Practices Summary

### ✅ DO

- ✅ Use shared container + Respawn for test suites with 20+ tests
- ✅ Configure timeout for CI environments (2-3 minutes)
- ✅ Categorize tests (Fast/Slow) for faster PR checks
- ✅ Enforce minimum coverage (80%+) in CI
- ✅ Publish test results and coverage reports
- ✅ Use parallel execution when tests are independent

### ❌ DON'T

- ❌ Create new container per test (too slow)
- ❌ Run all tests on every commit (use Fast category)
- ❌ Ignore coverage metrics
- ❌ Use SQLite in CI (defeats purpose)
- ❌ Skip cleanup (resource leaks)

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
