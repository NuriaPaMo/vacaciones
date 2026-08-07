# Scenario: backend+frontend (fullstack)
# Step definitions: tests/CapacityManagement.ReqnrollTests/StepDefinitions/CalendarCapacitySteps.cs
# Playwright E2E:   src/frontend/e2e/tests/calendar/heat-map.spec.ts

@feature-003 @capacity @heat-map
Feature: Capacity Heat Map
  As a department manager
  I want to see a heat map showing vacation coverage percentage by period
  So that I can identify over-requested periods before approving new requests

  Background:
    Given I am authenticated as "laura.sanchez@company.com" with role "DepartmentManager"
    And the department "Engineering" has 10 active employees
    And the critical capacity threshold is configured as 70%

  @smoke @P1
  Scenario: DM views daily capacity percentage on the heat map
    Given 5 employees have approved vacations covering "2026-08-12"
    When I navigate to the capacity heat map for "Engineering"
    Then the cell for "2026-08-12" shows 50% capacity

  @smoke @P1
  Scenario: Cell shows green for capacity 0-50%
    Given 4 employees have approved vacations covering "2026-08-11"
    When I navigate to the capacity heat map
    Then the cell for "2026-08-11" is displayed in green

  @smoke @P1
  Scenario: Cell shows red for capacity exceeding 70%
    Given 8 employees have approved vacations covering "2026-08-12"
    When I navigate to the capacity heat map
    Then the cell for "2026-08-12" is displayed in red with a critical alert icon
    And the capacity displayed is 80%

  @regression @P1
  Scenario: DM drills into critical cell to see contributing employees
    Given 8 employees have approved vacations covering "2026-08-12"
    When I navigate to the capacity heat map
    And I click on the critical cell for "2026-08-12"
    Then I see the list of 8 employees contributing to over-capacity

  @regression @P1
  Scenario: System suggests alternative dates when period is over-requested
    Given 8 employees have approved vacations covering "2026-08-12"
    When I click on the critical cell for "2026-08-12"
    Then the system suggests alternative date ranges with capacity below 70%

  @regression @P1
  Scenario: Heat map recalculates when administrator changes threshold
    Given the critical threshold is changed from 70% to 75%
    And 7 out of 10 employees have approved vacations covering "2026-08-12"
    When I navigate to the capacity heat map
    Then the cell for "2026-08-12" is displayed in yellow (70% < threshold of 75%)

  Scenario Outline: Heat map colours reflect correct capacity bands (BR-040)
    Given <on_vacation> out of 10 employees have vacations on "2026-08-12"
    When I view the heat map cell for "2026-08-12"
    Then the cell colour is "<colour>"
    Examples:
      | on_vacation | colour |
      | 2           | green  |
      | 5           | green  |
      | 6           | yellow |
      | 7           | orange |
      | 8           | red    |
