# Scenario: backend+frontend (fullstack)
# Step definitions: tests/VacationManagement.ReqnrollTests/StepDefinitions/VacationRequestSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/vacation-requests/vacation-request-submission.spec.ts

@feature-001 @vacation-request @submission
Feature: Submit Vacation Request
  As an authenticated employee
  I want to submit a vacation request with start and end dates
  So that I can formally request time off through the system

  Background:
    Given I am authenticated as employee "ana.garcia@company.com" with role "Employee"
    And the employee has a vacation balance of 20 available days
    And today is "2026-08-07"

  @smoke @P1
  Scenario: Employee submits a valid vacation request
    When I submit a vacation request from "2026-08-10" to "2026-08-14"
    Then a vacation request is created with status "Pending"
    And the total business days calculated is 5
    And a confirmation response contains the request id

  @smoke @P1
  Scenario: System calculates total business days excluding weekends
    When I submit a vacation request from "2026-08-10" to "2026-08-16"
    Then the total business days calculated is 5
    And the weekend days "2026-08-15" and "2026-08-16" are excluded from the count

  @smoke @P1
  Scenario: Employee selects dates using the visual calendar
    Given I am on the new vacation request form
    When I select "2026-08-10" as the start date on the calendar
    And I select "2026-08-14" as the end date on the calendar
    Then the date range "2026-08-10" to "2026-08-14" is highlighted on the calendar
    And the label shows "5 business days"

  @regression @P1
  Scenario: System rejects request when start date is same as or after end date
    When I submit a vacation request from "2026-08-14" to "2026-08-10"
    Then the submission fails with error code "DATE_VALIDATION_ERROR"
    And no vacation request is created

  @regression @P1
  Scenario: System prevents duplicate overlapping request
    Given I have an existing "Pending" vacation request from "2026-08-10" to "2026-08-14"
    When I submit a vacation request from "2026-08-12" to "2026-08-18"
    Then the submission fails with error code "OVERLAPPING_REQUEST"

  @regression @P1
  Scenario: System rejects request when vacation balance is insufficient
    Given the employee has a vacation balance of 3 available days
    When I submit a vacation request from "2026-08-10" to "2026-08-21"
    Then the submission fails with error code "INSUFFICIENT_BALANCE"
    And the error response includes remaining balance of 3 days

  @regression @P1
  Scenario: Employee attaches optional notes to the request
    When I submit a vacation request from "2026-08-10" to "2026-08-14" with notes "Summer family trip"
    Then a vacation request is created with status "Pending"
    And the notes "Summer family trip" are persisted with the request

  Scenario Outline: System validates minimum advance notice (BR-002)
    Given today is "<today>"
    When I submit a vacation request starting on "<start_date>"
    Then the submission result is "<result>"
    Examples:
      | today      | start_date | result   |
      | 2026-08-07 | 2026-08-07 | rejected |
      | 2026-08-07 | 2026-08-08 | accepted |
      | 2026-08-07 | 2026-08-10 | accepted |
      | 2026-08-07 | 2026-09-01 | accepted |
