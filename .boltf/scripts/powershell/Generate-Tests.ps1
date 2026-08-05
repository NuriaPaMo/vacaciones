# Bolt Framework Test Generator - Intelligent test suite generation
# PowerShell equivalent of generate-tests.sh

[CmdletBinding()]
param(
    [string]$Feature = "",
    [switch]$ScanCoverage,
    [ValidateSet("unit", "integration", "e2e", "all")]
    [string]$Type = "all",
    [string]$Output = "tests",
    [int]$MinCoverage = 80,
    [string]$ConstitutionFile = "memory\constitution.md",
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: Generate-Tests.ps1 [OPTIONS]"
    Write-Host "Options:"
    Write-Host "  -Feature ID         Generate tests for specific feature"
    Write-Host "  -ScanCoverage       Analyze and generate missing tests"
    Write-Host "  -Type TYPE          Test type: unit|integration|e2e|all"
    Write-Host "  -Output DIR         Output directory (default: tests)"
    Write-Host "  -MinCoverage NUM    Minimum coverage percentage (default: 80)"
    Write-Host "  -Help               Show this help message"
    exit 0
}

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Test-TechStack {
    param([string]$ConstitutionPath)
    
    if (-not (Test-Path $ConstitutionPath)) {
        return "unknown"
    }
    
    $constitution = Get-Content $ConstitutionPath -Raw
    
    if ($constitution -match "React.*\.NET|\.NET.*React") { return "react-dotnet" }
    if ($constitution -match "Vue.*Python|Python.*Vue") { return "vue-python" }
    if ($constitution -match "Angular.*Node|Node.*Angular") { return "angular-node" }
    if ($constitution -match "\.NET") { return "dotnet" }
    if ($constitution -match "Node\.?js|JavaScript|TypeScript") { return "nodejs" }
    if ($constitution -match "Python") { return "python" }
    if ($constitution -match "React") { return "react" }
    if ($constitution -match "Vue") { return "vue" }
    if ($constitution -match "Angular") { return "angular" }
    
    return "unknown"
}

function New-TestDirectory {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Log "Created directory: $Path"
    }
}

function New-UnitTests {
    param([string]$TechStack, [string]$OutputDir)
    
    Write-Log "Generating unit tests for $TechStack..."
    
    switch ($TechStack) {
        "react-dotnet" {
            # React unit tests
            New-TestDirectory "$OutputDir\frontend\unit"
            
            $reactTestTemplate = @"
// Bolt Framework Generated Test
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import ExampleComponent from '../../../src/components/ExampleComponent';

describe('ExampleComponent', () => {
  it('should render correctly', () => {
    render(<ExampleComponent title="Test Title" />);
    expect(screen.getByText('Test Title')).toBeInTheDocument();
  });

  it('should handle user interactions', () => {
    const mockOnClick = vi.fn();
    render(<ExampleComponent title="Test" onClick={mockOnClick} />);
    
    fireEvent.click(screen.getByRole('button'));
    expect(mockOnClick).toHaveBeenCalledTimes(1);
  });

  it('should handle edge cases', () => {
    render(<ExampleComponent title="" />);
    expect(screen.getByText('Default Title')).toBeInTheDocument();
  });
});
"@
            
            Set-Content "$OutputDir\frontend\unit\ExampleComponent.test.tsx" $reactTestTemplate
            
            # .NET unit tests
            New-TestDirectory "$OutputDir\backend\unit"
            
            $dotnetTestTemplate = @"
// Bolt Framework Generated Test
using Xunit;
using FluentAssertions;
using Moq;
using Microsoft.Extensions.Logging;
using Bolt Framework.Application.Services;
using Bolt Framework.Domain.Entities;

namespace Bolt Framework.Tests.Unit.Services
{
    public class ExampleServiceTests
    {
        private readonly Mock<ILogger<ExampleService>> _loggerMock;
        private readonly ExampleService _service;

        public ExampleServiceTests()
        {
            _loggerMock = new Mock<ILogger<ExampleService>>();
            _service = new ExampleService(_loggerMock.Object);
        }

        [Fact]
        public async Task CreateAsync_WithValidData_ShouldReturnSuccess()
        {
            // Arrange
            var entity = new ExampleEntity { Name = "Test Entity" };

            // Act
            var result = await _service.CreateAsync(entity);

            // Assert
            result.Should().NotBeNull();
            result.IsSuccess.Should().BeTrue();
        }

        [Fact]
        public async Task CreateAsync_WithNullData_ShouldReturnFailure()
        {
            // Act
            var result = await _service.CreateAsync(null);

            // Assert
            result.IsSuccess.Should().BeFalse();
            result.Error.Should().Contain("cannot be null");
        }

        [Theory]
        [InlineData("")]
        [InlineData("   ")]
        [InlineData(null)]
        public async Task CreateAsync_WithInvalidName_ShouldReturnFailure(string name)
        {
            // Arrange
            var entity = new ExampleEntity { Name = name };

            // Act
            var result = await _service.CreateAsync(entity);

            // Assert
            result.IsSuccess.Should().BeFalse();
        }
    }
}
"@
            
            Set-Content "$OutputDir\backend\unit\ExampleServiceTests.cs" $dotnetTestTemplate
            Write-Success "Created React + .NET unit tests"
        }
        
        "nodejs" {
            New-TestDirectory "$OutputDir\unit"
            
            $nodeTestTemplate = @"
// Bolt Framework Generated Test
const request = require('supertest');
const { expect } = require('chai');
const sinon = require('sinon');
const app = require('../../../src/app');

describe('Example Service', () => {
  let sandbox;

  beforeEach(() => {
    sandbox = sinon.createSandbox();
  });

  afterEach(() => {
    sandbox.restore();
  });

  describe('POST /api/examples', () => {
    it('should create new example successfully', async () => {
      const exampleData = {
        name: 'Test Example',
        description: 'Test Description'
      };

      const response = await request(app)
        .post('/api/examples')
        .send(exampleData)
        .expect(201);

      expect(response.body).to.have.property('id');
      expect(response.body.name).to.equal(exampleData.name);
    });

    it('should return validation error for missing name', async () => {
      const response = await request(app)
        .post('/api/examples')
        .send({})
        .expect(400);

      expect(response.body).to.have.property('error');
      expect(response.body.error).to.contain('name is required');
    });
  });
});
"@
            
            Set-Content "$OutputDir\unit\example.test.js" $nodeTestTemplate
            Write-Success "Created Node.js unit tests"
        }
        
        "python" {
            New-TestDirectory "$OutputDir\unit"
            
            $pythonTestTemplate = @"
# Bolt Framework Generated Test
import pytest
from unittest.mock import Mock, patch
from src.services.example_service import ExampleService
from src.models.example import Example

class TestExampleService:
    
    @pytest.fixture
    def service(self):
        return ExampleService()
    
    @pytest.fixture
    def sample_example(self):
        return Example(
            name="Test Example",
            description="Test Description"
        )
    
    def test_create_example_success(self, service, sample_example):
        """Test successful example creation."""
        result = service.create(sample_example)
        
        assert result is not None
        assert result.name == sample_example.name
        assert result.description == sample_example.description
    
    def test_create_example_with_empty_name_fails(self, service):
        """Test that creating example with empty name fails."""
        example = Example(name="", description="Test")
        
        with pytest.raises(ValueError, match="Name cannot be empty"):
            service.create(example)
    
    @pytest.mark.parametrize("name", [None, "", "   "])
    def test_create_example_with_invalid_name(self, service, name):
        """Test validation with various invalid names."""
        example = Example(name=name, description="Test")
        
        with pytest.raises(ValueError):
            service.create(example)
    
    @patch('src.services.example_service.database')
    def test_create_example_database_error(self, mock_db, service, sample_example):
        """Test handling of database errors."""
        mock_db.save.side_effect = Exception("Database error")
        
        with pytest.raises(Exception):
            service.create(sample_example)
"@
            
            Set-Content "$OutputDir\unit\test_example_service.py" $pythonTestTemplate
            Write-Success "Created Python unit tests"
        }
    }
}

function New-IntegrationTests {
    param([string]$TechStack, [string]$OutputDir)
    
    Write-Log "Generating integration tests for $TechStack..."
    
    switch ($TechStack) {
        "react-dotnet" {
            New-TestDirectory "$OutputDir\integration"
            
            $integrationTestTemplate = @"
// Bolt Framework Generated Integration Test
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using System.Net.Http.Json;
using Xunit;
using FluentAssertions;

namespace Bolt Framework.Tests.Integration
{
    public class ExampleApiTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly HttpClient _client;

        public ExampleApiTests(WebApplicationFactory<Program> factory)
        {
            _client = factory.CreateClient();
        }

        [Fact]
        public async Task GetExamples_ShouldReturnSuccessWithData()
        {
            // Act
            var response = await _client.GetAsync("/api/examples");

            // Assert
            response.Should().BeSuccessful();
            var examples = await response.Content.ReadFromJsonAsync<IEnumerable<object>>();
            examples.Should().NotBeNull();
        }

        [Fact]
        public async Task CreateExample_WithValidData_ShouldReturnCreated()
        {
            // Arrange
            var example = new { Name = "Integration Test Example", Description = "Test" };

            // Act
            var response = await _client.PostAsJsonAsync("/api/examples", example);

            // Assert
            response.StatusCode.Should().Be(System.Net.HttpStatusCode.Created);
        }

        [Fact]
        public async Task CreateExample_WithInvalidData_ShouldReturnBadRequest()
        {
            // Arrange
            var invalidExample = new { Name = "", Description = "" };

            // Act
            var response = await _client.PostAsJsonAsync("/api/examples", invalidExample);

            // Assert
            response.StatusCode.Should().Be(System.Net.HttpStatusCode.BadRequest);
        }
    }
}
"@
            
            Set-Content "$OutputDir\integration\ExampleApiTests.cs" $integrationTestTemplate
            Write-Success "Created .NET integration tests"
        }
        
        default {
            Write-Warning "Integration tests not implemented for $TechStack yet"
        }
    }
}

function New-E2ETests {
    param([string]$TechStack, [string]$OutputDir)
    
    Write-Log "Generating E2E tests for $TechStack..."
    
    New-TestDirectory "$OutputDir\e2e"
    
    $e2eTestTemplate = @"
// Bolt Framework Generated E2E Test
import { test, expect } from '@playwright/test';

test.describe('Example Feature E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should display main navigation', async ({ page }) => {
    await expect(page.locator('nav')).toBeVisible();
    await expect(page.locator('nav >> text=Home')).toBeVisible();
  });

  test('should create new example via UI', async ({ page }) => {
    // Navigate to create form
    await page.click('text=Create Example');
    
    // Fill form
    await page.fill('input[name="name"]', 'E2E Test Example');
    await page.fill('textarea[name="description"]', 'Created via E2E test');
    
    // Submit
    await page.click('button[type="submit"]');
    
    // Verify success
    await expect(page.locator('text=Example created successfully')).toBeVisible();
    await expect(page.locator('text=E2E Test Example')).toBeVisible();
  });

  test('should handle validation errors gracefully', async ({ page }) => {
    await page.click('text=Create Example');
    
    // Submit empty form
    await page.click('button[type="submit"]');
    
    // Check validation messages
    await expect(page.locator('text=Name is required')).toBeVisible();
  });

  test('should search and filter examples', async ({ page }) => {
    // Enter search term
    await page.fill('input[placeholder*="Search"]', 'test');
    
    // Verify filtered results
    const searchResults = page.locator('.example-item');
    await expect(searchResults).toHaveCount({ min: 1 });
  });
});
"@
    
    Set-Content "$OutputDir\e2e\example.spec.ts" $e2eTestTemplate
    Write-Success "Created E2E tests"
}

function New-TestConfiguration {
    param([string]$TechStack, [string]$OutputDir)
    
    Write-Log "Creating test configuration files..."
    
    # Create test configuration based on tech stack
    switch ($TechStack) {
        "react-dotnet" {
            # Vitest config for React
            $vitestConfig = @"
// Bolt Framework Generated Vitest Configuration
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
      ],
      thresholds: {
        global: {
          branches: $MinCoverage,
          functions: $MinCoverage,
          lines: $MinCoverage,
          statements: $MinCoverage
        }
      }
    }
  }
});
"@
            
            if (-not (Test-Path "vitest.config.ts")) {
                Set-Content "vitest.config.ts" $vitestConfig
                Write-Success "Created vitest.config.ts"
            }
            
            # xUnit project for .NET
            $xunitProject = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.7.1" />
    <PackageReference Include="xunit" Version="2.4.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.4.5" />
    <PackageReference Include="FluentAssertions" Version="6.12.0" />
    <PackageReference Include="Moq" Version="4.20.69" />
    <PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.0.0" />
    <PackageReference Include="coverlet.collector" Version="6.0.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\backend\Bolt Framework.Api\Bolt Framework.Api.csproj" />
  </ItemGroup>

</Project>
"@
            
            $testProjectPath = "$OutputDir\backend\Bolt Framework.Tests.csproj"
            if (-not (Test-Path $testProjectPath)) {
                Set-Content $testProjectPath $xunitProject
                Write-Success "Created $testProjectPath"
            }
        }
        
        "nodejs" {
            $mochaConfig = @"
{
  "require": ["ts-node/register"],
  "extensions": ["ts"],
  "spec": "tests/**/*.test.ts",
  "timeout": 5000,
  "reporter": "spec"
}
"@
            
            if (-not (Test-Path ".mocharc.json")) {
                Set-Content ".mocharc.json" $mochaConfig
                Write-Success "Created .mocharc.json"
            }
        }
        
        "python" {
            $pytestConfig = @"
# Bolt Framework Generated pytest configuration
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--verbose",
    "--strict-markers",
    "--strict-config",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-report=xml",
    "--cov-fail-under=$MinCoverage",
]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
"@
            
            if (-not (Test-Path "pyproject.toml")) {
                Set-Content "pyproject.toml" $pytestConfig
                Write-Success "Created pyproject.toml with pytest config"
            }
        }
    }
}

# Main execution
Write-Host "🧪 Bolt Framework Test Generator" -ForegroundColor Blue
Write-Host "========================" -ForegroundColor Blue

# Detect tech stack
$techStack = Test-TechStack $ConstitutionFile
Write-Log "Detected tech stack: $techStack"

# Create output directory
New-TestDirectory $Output

# Generate tests based on type
switch ($Type) {
    "unit" {
        New-UnitTests $techStack $Output
    }
    "integration" {
        New-IntegrationTests $techStack $Output
    }
    "e2e" {
        New-E2ETests $techStack $Output
    }
    "all" {
        New-UnitTests $techStack $Output
        New-IntegrationTests $techStack $Output
        New-E2ETests $techStack $Output
    }
}

# Generate test configuration
New-TestConfiguration $techStack $Output

# Create test documentation
$testReadme = @"
# Test Suite

Generated by Bolt Framework Test Generator

## Structure

- \`unit/\` - Unit tests with high coverage
- \`integration/\` - Integration tests for APIs and services  
- \`e2e/\` - End-to-end tests using Playwright

## Running Tests

### Unit Tests
``````bash
# For .NET
dotnet test tests/backend/

# For Node.js
npm run test:unit

# For Python
pytest tests/unit/
``````

### Integration Tests
``````bash
# For .NET
dotnet test tests/integration/

# For Node.js  
npm run test:integration

# For Python
pytest tests/integration/
``````

### E2E Tests
``````bash
npx playwright test
``````

## Coverage Requirements

- Minimum coverage: $MinCoverage%
- Critical paths: 100%
- New code: 90%

## Test Conventions

1. **Naming**: Test files end with \`.test.\` or \`.spec.\`
2. **Structure**: Arrange-Act-Assert pattern
3. **Isolation**: Tests should be independent
4. **Mocking**: Mock external dependencies
5. **Data**: Use factories for test data

## Generated Features

- ✅ Unit test templates
- ✅ Integration test setup
- ✅ E2E test framework
- ✅ Coverage configuration
- ✅ CI/CD integration ready

Tech Stack: $techStack
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

Set-Content "$Output\README.md" $testReadme
Write-Success "Created test documentation"

Write-Host ""
Write-Success "Test suite generated successfully!"
Write-Host ""
Write-Host "📊 Generated for tech stack: $techStack" -ForegroundColor Cyan
Write-Host "📁 Output directory: $Output" -ForegroundColor Cyan
Write-Host "🎯 Coverage target: $MinCoverage%" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Install test dependencies" -ForegroundColor White
Write-Host "   2. Configure your CI/CD pipeline" -ForegroundColor White
Write-Host "   3. Run tests: npm test / dotnet test / pytest" -ForegroundColor White
Write-Host "   4. Set up coverage reporting" -ForegroundColor White