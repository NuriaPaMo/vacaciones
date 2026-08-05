#!/bin/bash
# Bolt Framework Test Generator - Intelligent test suite generation

set -e

FEATURE_ID=""
SCAN_COVERAGE=false
TEST_TYPE="all"
OUTPUT_DIR="tests"
CONSTITUTION_FILE=".boltf/memory/constitution.md"
MIN_COVERAGE=80

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --feature)
            FEATURE_ID="$2"
            shift 2
            ;;
        --scan-coverage)
            SCAN_COVERAGE=true
            shift
            ;;
        --type)
            TEST_TYPE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --min-coverage)
            MIN_COVERAGE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --feature ID         Generate tests for specific feature"
            echo "  --scan-coverage      Analyze and generate missing tests"
            echo "  --type TYPE          Test type: unit|integration|e2e|all"
            echo "  --output DIR         Output directory (default: tests)"
            echo "  --min-coverage NUM   Minimum coverage percentage (default: 80)"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

echo "🧪 Bolt Framework Test Generator"
echo "======================="

# Read constitution for test requirements
if [[ -f "$CONSTITUTION_FILE" ]]; then
    CONSTITUTION_COVERAGE=$(grep -i "coverage\|testing" "$CONSTITUTION_FILE" | grep -oE '[0-9]+' | head -1)
    MIN_COVERAGE=${CONSTITUTION_COVERAGE:-$MIN_COVERAGE}
    echo "📋 Constitution requires: ${MIN_COVERAGE}% test coverage"
else
    echo "⚠️  Constitution not found, using default coverage: ${MIN_COVERAGE}%"
fi

# Create test directories
mkdir -p "$OUTPUT_DIR"/{unit,integration,e2e}/{frontend,backend}
mkdir -p "$OUTPUT_DIR"/{fixtures,mocks,utilities}

# Function to generate React component tests
generate_react_tests() {
    local component_file="$1"
    local component_name=$(basename "$component_file" .tsx)
    local test_dir="$OUTPUT_DIR/unit/frontend/components"
    local test_file="$test_dir/${component_name}.test.tsx"

    mkdir -p "$test_dir"

    cat > "$test_file" << EOF
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { ${component_name} } from '../../../../../src/frontend/components/${component_name}';

describe('${component_name}', () => {
  const defaultProps = {
    // Add default props based on component interface
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders correctly with default props', () => {
    render(<${component_name} {...defaultProps} />);
    expect(screen.getByTestId('${component_name.toLowerCase()}')).toBeInTheDocument();
  });

  it('handles user interactions correctly', async () => {
    const mockHandler = vi.fn();
    render(<${component_name} {...defaultProps} onClick={mockHandler} />);

    const button = screen.getByRole('button');
    fireEvent.click(button);

    await waitFor(() => {
      expect(mockHandler).toHaveBeenCalledTimes(1);
    });
  });

  it('displays loading state correctly', () => {
    render(<${component_name} {...defaultProps} isLoading={true} />);
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });

  it('displays error state correctly', () => {
    const errorMessage = 'Test error message';
    render(<${component_name} {...defaultProps} error={errorMessage} />);
    expect(screen.getByText(errorMessage)).toBeInTheDocument();
  });

  it('handles edge cases and boundary conditions', () => {
    render(<${component_name} {...defaultProps} data={[]} />);
    expect(screen.getByText('No data available')).toBeInTheDocument();
  });
});
EOF

    echo "  ⚛️  Generated React test: $test_file"
}

# Function to generate .NET controller tests
generate_dotnet_tests() {
    local controller_file="$1"
    local controller_name=$(basename "$controller_file" .cs)
    local test_dir="$OUTPUT_DIR/unit/backend/controllers"
    local test_file="$test_dir/${controller_name}Tests.cs"

    mkdir -p "$test_dir"

    cat > "$test_file" << EOF
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using FluentAssertions;
using System.Net;
using System.Net.Http.Json;

namespace Bolt Framework.Api.Tests.Controllers
{
    public class ${controller_name}Tests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;
        private readonly HttpClient _client;

        public ${controller_name}Tests(WebApplicationFactory<Program> factory)
        {
            _factory = factory;
            _client = _factory.CreateClient();
        }

        [Fact]
        public async Task Get_ReturnsSuccessStatusCode()
        {
            // Arrange
            var endpoint = "/api/${controller_name.Replace("Controller", "").ToLowerInvariant()}";

            // Act
            var response = await _client.GetAsync(endpoint);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
        }

        [Fact]
        public async Task Post_WithValidData_ReturnsCreated()
        {
            // Arrange
            var endpoint = "/api/${controller_name.Replace("Controller", "").ToLowerInvariant()}";
            var validData = new
            {
                // Add valid test data properties
            };

            // Act
            var response = await _client.PostAsJsonAsync(endpoint, validData);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.Created);
        }

        [Theory]
        [InlineData("")]
        [InlineData(null)]
        public async Task Post_WithInvalidData_ReturnsBadRequest(string invalidValue)
        {
            // Arrange
            var endpoint = "/api/${controller_name.Replace("Controller", "").ToLowerInvariant()}";
            var invalidData = new
            {
                Name = invalidValue
            };

            // Act
            var response = await _client.PostAsJsonAsync(endpoint, invalidData);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task Delete_ExistingItem_ReturnsNoContent()
        {
            // Arrange - First create an item
            var createEndpoint = "/api/${controller_name.Replace("Controller", "").ToLowerInvariant()}";
            var testItem = new { /* test data */ };
            var createResponse = await _client.PostAsJsonAsync(createEndpoint, testItem);
            var createdItem = await createResponse.Content.ReadFromJsonAsync<dynamic>();

            // Act - Delete the item
            var deleteEndpoint = \$"/api/${controller_name.Replace("Controller", "").ToLowerInvariant()}/{createdItem?.Id}";
            var deleteResponse = await _client.DeleteAsync(deleteEndpoint);

            // Assert
            deleteResponse.StatusCode.Should().Be(HttpStatusCode.NoContent);
        }
    }
}
EOF

    echo "  🔵 Generated .NET test: $test_file"
}

# Function to generate API integration tests
generate_integration_tests() {
    local feature_spec="$1"
    local test_dir="$OUTPUT_DIR/integration"
    local test_file="$test_dir/${FEATURE_ID}_integration.test.js"

    mkdir -p "$test_dir"

    cat > "$test_file" << EOF
// Integration tests for feature: $FEATURE_ID
// Generated from: $feature_spec

describe('${FEATURE_ID} Integration Tests', () => {
  let testServer;
  let testDatabase;

  beforeAll(async () => {
    // Setup test environment
    testServer = await startTestServer();
    testDatabase = await setupTestDatabase();
  });

  afterAll(async () => {
    // Cleanup test environment
    await testServer.close();
    await testDatabase.cleanup();
  });

  beforeEach(async () => {
    // Reset database state
    await testDatabase.reset();
  });

  describe('Happy Path Scenarios', () => {
    it('completes full user workflow successfully', async () => {
      // Test the complete user journey
      const response = await request(testServer)
        .post('/api/workflow')
        .send({
          // Test data from feature spec
        })
        .expect(200);

      expect(response.body).toMatchObject({
        success: true,
        // Expected response structure
      });
    });
  });

  describe('Error Scenarios', () => {
    it('handles invalid input gracefully', async () => {
      const response = await request(testServer)
        .post('/api/workflow')
        .send({
          // Invalid test data
        })
        .expect(400);

      expect(response.body.error).toBeDefined();
    });

    it('handles server errors gracefully', async () => {
      // Simulate server error condition
      await testDatabase.simulateError();

      const response = await request(testServer)
        .post('/api/workflow')
        .send({
          // Valid test data
        })
        .expect(500);

      expect(response.body.error).toContain('Internal server error');
    });
  });

  describe('Performance Requirements', () => {
    it('responds within acceptable time limits', async () => {
      const startTime = Date.now();

      await request(testServer)
        .get('/api/performance-critical-endpoint')
        .expect(200);

      const responseTime = Date.now() - startTime;
      expect(responseTime).toBeLessThan(500); // 500ms SLA
    });
  });
});
EOF

    echo "  🔗 Generated integration test: $test_file"
}

# Function to generate E2E tests
generate_e2e_tests() {
    local feature_spec="$1"
    local test_dir="$OUTPUT_DIR/e2e"
    local test_file="$test_dir/${FEATURE_ID}_e2e.spec.ts"

    mkdir -p "$test_dir"

    cat > "$test_file" << EOF
// E2E tests for feature: $FEATURE_ID
// Generated from: $feature_spec

import { test, expect } from '@playwright/test';

test.describe('${FEATURE_ID} E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('user can complete main workflow', async ({ page }) => {
    // Step 1: Navigate to feature
    await page.click('[data-testid="nav-${FEATURE_ID}"]');
    await expect(page).toHaveURL(/.*${FEATURE_ID}.*/);

    // Step 2: Fill in required information
    await page.fill('[data-testid="input-field"]', 'test data');

    // Step 3: Submit form
    await page.click('[data-testid="submit-button"]');

    // Step 4: Verify success
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
  });

  test('displays appropriate error messages', async ({ page }) => {
    await page.click('[data-testid="nav-${FEATURE_ID}"]');

    // Submit without required data
    await page.click('[data-testid="submit-button"]');

    // Verify error message
    await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
  });

  test('works on mobile devices', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });

    await page.click('[data-testid="nav-${FEATURE_ID}"]');

    // Verify mobile layout
    await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible();
  });

  test('handles offline scenarios', async ({ page, context }) => {
    await context.setOffline(true);

    await page.click('[data-testid="nav-${FEATURE_ID}"]');

    // Verify offline handling
    await expect(page.locator('[data-testid="offline-message"]')).toBeVisible();
  });
});
EOF

    echo "  🌐 Generated E2E test: $test_file"
}

# Scan existing code and generate tests
if [[ $SCAN_COVERAGE == true || $TEST_TYPE == "all" || $TEST_TYPE == "unit" ]]; then
    echo "🔍 Scanning for components to test..."

    # Find React components
    if [[ -d "src/frontend" ]]; then
        echo "⚛️  Scanning React components..."
        find src/frontend -name "*.tsx" -not -path "*/node_modules/*" | while read -r file; do
            if [[ -f "$file" ]] && grep -q "export.*function\|export.*const.*=.*(" "$file"; then
                generate_react_tests "$file"
            fi
        done
    fi

    # Find .NET controllers
    if [[ -d "src/backend" ]]; then
        echo "🔵 Scanning .NET controllers..."
        find src/backend -name "*Controller.cs" -not -path "*/bin/*" -not -path "*/obj/*" | while read -r file; do
            if [[ -f "$file" ]]; then
                generate_dotnet_tests "$file"
            fi
        done
    fi
fi

# Generate feature-specific tests
if [[ -n "$FEATURE_ID" ]]; then
    echo "📋 Generating tests for feature: $FEATURE_ID"

    FEATURE_SPEC="specs/${FEATURE_ID}/feature.md"
    if [[ -f "$FEATURE_SPEC" ]]; then
        if [[ $TEST_TYPE == "all" || $TEST_TYPE == "integration" ]]; then
            generate_integration_tests "$FEATURE_SPEC"
        fi

        if [[ $TEST_TYPE == "all" || $TEST_TYPE == "e2e" ]]; then
            generate_e2e_tests "$FEATURE_SPEC"
        fi
    else
        echo "⚠️  Feature spec not found: $FEATURE_SPEC"
    fi
fi

# Generate test configuration files
echo "⚙️  Creating test configuration files..."

# Jest configuration (if Node.js backend)
if [[ -f "src/backend/package.json" ]]; then
    cat > jest.config.js << 'EOF'
module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.test.js',
    '!src/**/node_modules/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js']
};
EOF
fi

# Playwright configuration (for E2E tests)
cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
EOF

# Create test utilities
cat > "$OUTPUT_DIR/utilities/test-helpers.ts" << 'EOF'
// Common test utilities and helpers

export const mockUser = {
  id: '12345',
  email: 'test@example.com',
  name: 'Test User'
};

export const mockApiResponse = (data: any, status = 200) => ({
  status,
  json: () => Promise.resolve(data),
  ok: status >= 200 && status < 300
});

export const waitForElement = async (selector: string, timeout = 5000) => {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const element = document.querySelector(selector);
    if (element) return element;
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  throw new Error(`Element ${selector} not found within ${timeout}ms`);
};

export const setupTestDatabase = async () => {
  // Database setup for integration tests
  // Implementation depends on database type
};

export const cleanupTestDatabase = async () => {
  // Database cleanup for integration tests
  // Implementation depends on database type
};
EOF

# Create test data fixtures
cat > "$OUTPUT_DIR/fixtures/test-data.json" << 'EOF'
{
  "users": [
    {
      "id": "user-1",
      "email": "john.doe@example.com",
      "name": "John Doe",
      "role": "user"
    },
    {
      "id": "admin-1",
      "email": "admin@example.com",
      "name": "Admin User",
      "role": "admin"
    }
  ],
  "products": [
    {
      "id": "product-1",
      "name": "Test Product",
      "price": 99.99,
      "category": "electronics"
    }
  ]
}
EOF

echo ""
echo "✅ Test generation completed!"
echo ""
echo "📊 Generated test structure:"
echo "   📁 $OUTPUT_DIR/"
echo "   ├── unit/           # Unit tests"
echo "   ├── integration/    # Integration tests"
echo "   ├── e2e/           # End-to-end tests"
echo "   ├── fixtures/      # Test data"
echo "   └── utilities/     # Test helpers"
echo ""
echo "🎯 Next Steps:"
echo "   1. Install test dependencies:"
echo "      npm install --save-dev @testing-library/react vitest @playwright/test"
echo "   2. Review and customize generated tests"
echo "   3. Run tests: npm test"
echo "   4. Check coverage: npm run test:coverage"
echo ""
echo "📋 Coverage target: ${MIN_COVERAGE}% (from constitution)"