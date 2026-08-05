---
name: gherkin-reqnroll
description: BDD with Gherkin syntax and Reqnroll for .NET acceptance testing
---

# Gherkin & Reqnroll BDD Testing

## When to Use

- Writing acceptance tests from user stories and acceptance criteria
- Creating executable specifications with stakeholders
- Validating business requirements through BDD scenarios
- Generating step definitions for .NET projects with Reqnroll
- The User or an agent needs to automate acceptance testing using Gherkin for .NET projects.

## Quick Start

```bash
# Install Reqnroll (SpecFlow successor for .NET)
dotnet add package Reqnroll
dotnet add package Reqnroll.xUnit

# Generate feature file
# Location: specs/{feature-name}/tests/{feature}.feature
```

## Feature File Structure

```gherkin
# language: en
@feature-tag @epic-tag
Feature: User Authentication
  As a registered user
  I want to log in with my credentials
  So that I can access my account

  # Link to specification
  # Spec: ../requirements/requirements.md
  # User Story: US-001

  Background:
    Given the application is running
    And the database is initialized

  # ============================================
  # User Story: US-001 - Login Flow
  # ============================================

  @US-001 @AC-001.1 @happy-path
  Scenario: Successful login with valid credentials
    Given I am on the login page
    And I have a valid account with email "user@example.com"
    When I enter email "user@example.com"
    And I enter password "SecurePass123!"
    And I click the "Login" button
    Then I should be redirected to "/dashboard"
    And I should see welcome message "Welcome back"

  @US-001 @AC-001.2 @validation
  Scenario: Reject login with invalid password
    Given I am on the login page
    When I enter email "user@example.com"
    And I enter password "WrongPassword"
    And I click the "Login" button
    Then I should see error "Invalid credentials"
    And I should remain on the login page

  @US-001 @AC-001.3 @edge-case
  Scenario Outline: Handle login with various invalid inputs
    Given I am on the login page
    When I enter email "<email>"
    And I enter password "<password>"
    And I click the "Login" button
    Then I should see error "<error_message>"

    Examples: Invalid credentials
      | email              | password    | error_message       |
      |                    | password123 | Email is required   |
      | user@example.com   |             | Password is required|
      | invalid-email      | password123 | Invalid email format|
```

## Step Definitions (.NET/Reqnroll)

```csharp
// File: tests/StepDefinitions/AuthenticationSteps.cs
using Reqnroll;
using Xunit;

namespace TimeTracking.AcceptanceTests.StepDefinitions;

[Binding]
public class AuthenticationSteps
{
    private readonly ScenarioContext _scenarioContext;
    private readonly WebApplicationFactory _factory;
    private HttpClient _client;
    private HttpResponseMessage _response;

    public AuthenticationSteps(
        ScenarioContext scenarioContext,
        WebApplicationFactory factory)
    {
        _scenarioContext = scenarioContext;
        _factory = factory;
        _client = _factory.CreateClient();
    }

    [Given(@"I am on the login page")]
    public async Task GivenIAmOnTheLoginPage()
    {
        _response = await _client.GetAsync("/login");
        Assert.Equal(HttpStatusCode.OK, _response.StatusCode);
    }

    [Given(@"I have a valid account with email ""(.*)""")]
    public async Task GivenIHaveAValidAccount(string email)
    {
        // Seed test data
        await SeedUserAsync(email, "SecurePass123!");
    }

    [When(@"I enter email ""(.*)""")]
    public void WhenIEnterEmail(string email)
    {
        _scenarioContext["email"] = email;
    }

    [When(@"I enter password ""(.*)""")]
    public void WhenIEnterPassword(string password)
    {
        _scenarioContext["password"] = password;
    }

    [When(@"I click the ""(.*)"" button")]
    public async Task WhenIClickButton(string buttonName)
    {
        var credentials = new
        {
            Email = _scenarioContext.Get<string>("email"),
            Password = _scenarioContext.Get<string>("password")
        };

        _response = await _client.PostAsJsonAsync("/api/auth/login", credentials);
        _scenarioContext["response"] = _response;
    }

    [Then(@"I should be redirected to ""(.*)""")]
    public void ThenIShouldBeRedirectedTo(string expectedPath)
    {
        var location = _response.Headers.Location?.ToString();
        Assert.Contains(expectedPath, location);
    }

    [Then(@"I should see error ""(.*)""")]
    public async Task ThenIShouldSeeError(string expectedError)
    {
        var content = await _response.Content.ReadAsStringAsync();
        Assert.Contains(expectedError, content);
    }
}
```

## Reqnroll Configuration

```json
// reqnroll.json
{
  "language": {
    "feature": "en"
  },
  "bindingCulture": {
    "name": "en-US"
  },
  "stepAssemblies": [
    {
      "assembly": "TimeTracking.AcceptanceTests"
    }
  ],
  "trace": {
    "traceSuccessfulSteps": true,
    "traceTimings": true,
    "minTracedDuration": "0:0:0.1"
  }
}
```

## Best Practices

### Scenario Writing

- **One scenario per acceptance criterion**: Map @AC-XXX.Y tags
- **Use Background** for common preconditions
- **Scenario Outline** for data-driven tests with Examples
- **Tag consistently**: `@feature @user-story @AC-id @type`
- **Link to specs**: Add comments with spec file paths

### Step Definitions

- **Reusable steps**: Share steps across features
- **ScenarioContext**: Store state between steps
- **Avoid UI coupling**: Test through APIs when possible
- **One assertion per Then**: Clear failure messages
- **Async/await**: Use for I/O operations

### Organization

```text
tests/
├── Features/
│   ├── Authentication.feature
│   ├── TimeTracking.feature
│   └── Reports.feature
├── StepDefinitions/
│   ├── AuthenticationSteps.cs
│   ├── TimeTrackingSteps.cs
│   └── CommonSteps.cs
├── Hooks/
│   └── TestHooks.cs
└── Support/
    ├── WebApplicationFactory.cs
    └── TestDataSeeder.cs
```

## Running Tests

```bash
# Run all acceptance tests
dotnet test --filter Category=Acceptance

# Run specific feature
dotnet test --filter FullyQualifiedName~Authentication

# Run with specific tag
dotnet test --filter Category=happy-path

# Generate HTML report (with Reqnroll.Reports)
dotnet test && reqnroll-report
```

## Integration with Bolt Framework

### From User Story to Gherkin

1. Read `specs/{feature}/requirements/requirements.md`
2. Extract user stories and acceptance criteria
3. Generate Feature file with scenarios
4. Map each AC to a Scenario with tag `@AC-{id}`
5. Generate step definition skeleton

### Tagging Strategy

| Tag Type   | Example                                    | Purpose                    |
| ---------- | ------------------------------------------ | -------------------------- |
| Feature    | `@time-tracking`                           | Group by feature           |
| User Story | `@US-001`                                  | Link to user story         |
| AC         | `@AC-001.1`                                | Map to acceptance criteria |
| Type       | `@happy-path`, `@validation`, `@edge-case` | Test categorization        |
| Priority   | `@critical`, `@high`                       | Execution priority         |

## References

- [Reqnroll Documentation](https://docs.reqnroll.net/)
- [Gherkin Syntax](https://cucumber.io/docs/gherkin/reference/)
- [BDD Best Practices](https://cucumber.io/docs/bdd/)
