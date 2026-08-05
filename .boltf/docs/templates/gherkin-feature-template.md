# Gherkin Feature Template

> **BOLT Framework Stage:** DISCOVERY - BDD Scenarios
> **Format:** Gherkin (Cucumber)

---

## Feature File: `{feature-name}.feature`

```gherkin
# language: en
# encoding: UTF-8

@{epic-tag} @{feature-tag}
Feature: {Feature Name}
  As a {role/persona}
  I want {goal/desire}
  So that {benefit/value}

  # ============================================================
  # BACKGROUND - Common setup for all scenarios
  # ============================================================

  Background:
    Given {common precondition 1}
    And {common precondition 2}

  # ============================================================
  # SCENARIO 1: Happy Path / Main Success Scenario
  # ============================================================

  @happy-path @smoke
  Scenario: {Descriptive scenario name for happy path}
    Given {initial context}
    And {additional context}
    When {action taken by user}
    And {additional action}
    Then {expected outcome}
    And {additional verification}

  # ============================================================
  # SCENARIO 2: Alternative Path
  # ============================================================

  @alternative
  Scenario: {Descriptive scenario name for alternative}
    Given {initial context}
    When {alternative action}
    Then {alternative outcome}

  # ============================================================
  # SCENARIO 3: Error Handling
  # ============================================================

  @error-handling @negative
  Scenario: {Descriptive scenario name for error case}
    Given {initial context}
    When {action that causes error}
    Then {error message or behavior}
    And {system state after error}

  # ============================================================
  # SCENARIO 4: Boundary Conditions
  # ============================================================

  @boundary
  Scenario: {Descriptive scenario for boundary condition}
    Given {context at boundary}
    When {action at limit}
    Then {expected behavior at boundary}

  # ============================================================
  # SCENARIO OUTLINE: Data-Driven Tests
  # ============================================================

  @data-driven
  Scenario Outline: {Parameterized scenario description}
    Given {context with <parameter1>}
    When {action with <parameter2>}
    Then {outcome with <expected_result>}

    Examples: Valid inputs
      | parameter1 | parameter2 | expected_result |
      | value1a    | value2a    | result_a        |
      | value1b    | value2b    | result_b        |
      | value1c    | value2c    | result_c        |

    Examples: Edge cases
      | parameter1 | parameter2 | expected_result |
      | empty      | minimum    | edge_result     |
      | maximum    | special    | limit_result    |

  # ============================================================
  # SCENARIO: Integration Point
  # ============================================================

  @integration @external-service
  Scenario: {Scenario involving external system}
    Given {external system is available}
    And {precondition for integration}
    When {action triggering integration}
    Then {expected response from external system}
    And {local system state updated}

  # ============================================================
  # SCENARIO: Security
  # ============================================================

  @security @authentication
  Scenario: {Security-related scenario}
    Given {user with specific permissions}
    When {user attempts action}
    Then {appropriate security response}

  # ============================================================
  # SCENARIO: Performance (for documentation, actual perf tests elsewhere)
  # ============================================================

  @performance @non-functional
  Scenario: {Performance expectation scenario}
    Given {system under normal load}
    When {user performs action}
    Then {response time is within acceptable limits}
```

---

## Step Definitions Template

### Given Steps (Context/Preconditions)

```text
Given {actor} is logged in as {role}
Given the {entity} with {attribute} "{value}" exists
Given the system is in {state} state
Given {number} {entities} exist in the system
Given the following {entities} exist:
  | column1 | column2 | column3 |
  | value1  | value2  | value3  |
```

### When Steps (Actions)

```text
When {actor} navigates to {page/endpoint}
When {actor} clicks the {element} button
When {actor} enters "{value}" in the {field} field
When {actor} submits the {form} form
When {actor} selects "{option}" from {dropdown}
When {actor} {action} the {entity} with {attribute} "{value}"
When the system receives a {event} event
When {time period} has passed
```

### Then Steps (Outcomes/Assertions)

```text
Then {actor} should see "{message}"
Then the {entity} should be {state}
Then the {attribute} should be "{expected_value}"
Then the system should display {element}
Then the response status should be {code}
Then the {entity} count should be {number}
Then {actor} should be redirected to {page}
Then the following {entities} should exist:
  | column1 | column2 |
  | value1  | value2  |
Then {actor} should receive an email with subject "{subject}"
Then the audit log should contain "{action}"
```

---

## Tags Reference

### Priority Tags

- `@critical` - Must pass for release
- `@high` - Important functionality
- `@medium` - Standard functionality
- `@low` - Nice to have

### Type Tags

- `@smoke` - Smoke tests
- `@regression` - Regression suite
- `@happy-path` - Main success scenarios
- `@negative` - Error/failure scenarios
- `@boundary` - Edge cases
- `@data-driven` - Parameterized tests

### Layer Tags

- `@ui` - User interface tests
- `@api` - API tests
- `@integration` - Integration tests
- `@e2e` - End-to-end tests

### Non-Functional Tags

- `@security` - Security tests
- `@performance` - Performance expectations
- `@accessibility` - Accessibility tests

### Execution Control

- `@wip` - Work in progress (skip)
- `@skip` - Temporarily disabled
- `@manual` - Manual test only
- `@flaky` - Known flaky test

---

## Best Practices

### DO

- Write scenarios from user's perspective
- Use business language, not technical jargon
- Keep scenarios independent (no dependencies)
- One scenario = one test case = one assertion focus
- Use Background for common setup
- Use tags for filtering and organization

### DON'T

- Don't include implementation details
- Don't use "click button X, enter Y in field Z" (too UI-specific)
- Don't create dependencies between scenarios
- Don't repeat steps that should be in Background
- Don't use generic names like "Test scenario 1"

---

## Mapping to BOLT Framework Artifacts

| Gherkin  | BOLT Framework Artifact |
| -------- | ----------------------- |
| Feature  | Feature Specification   |
| Scenario | Use Case Flow           |
| Given    | Preconditions           |
| When     | Actor Actions           |
| Then     | Postconditions          |
| Examples | Test Data               |

---

*Generated by Bolt Gherkin Agent*
