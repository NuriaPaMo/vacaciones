# Scenario: backend+frontend (fullstack)
# Step definitions: tests/VacationManagement.ReqnrollTests/StepDefinitions/VacationRequestSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/vacation-requests/vacation-request-tracking.spec.ts

@feature-001 @vacation-request @tracking
Feature: Track Vacation Request Status
  As an authenticated employee
  I want to see the current status of all my vacation requests
  So that I know which are pending, approved, rejected, or cancelled

  Background:
    Given I am authenticated as employee "ana.garcia@company.com" with role "Employee"
    And the employee has the following vacation requests:
      | dates                        | status    |
      | 2026-08-10 to 2026-08-14     | Pending   |
      | 2026-07-01 to 2026-07-05     | Approved  |
      | 2026-06-15 to 2026-06-16     | Rejected  |

  @smoke @P1
  Scenario: Employee views list of all their vacation requests
    When I navigate to "My Requests"
    Then I see a list of 3 vacation requests
    And each request shows dates, total days, status, and submission date

  @smoke @P1
  Scenario: Request list is ordered by submission date newest first
    When I navigate to "My Requests"
    Then the first request in the list is the most recently submitted
    And the list is sorted by submission date descending

  @regression @P1
  Scenario: Employee views status timeline for a specific request
    Given I have a vacation request with the following status history:
      | from_status | to_status | actor               | reason         |
      |             | Pending   | ana.garcia          |                |
      | Pending     | Rejected  | carlos.ruiz@company | Coverage gap   |
    When I click on that vacation request to view details
    Then I see a timeline showing 2 status transitions
    And the rejection entry shows the reason "Coverage gap"

  @regression @P1
  Scenario: Employee filters requests by status
    When I navigate to "My Requests"
    And I filter by status "Approved"
    Then only the request with status "Approved" is shown
    And requests with other statuses are hidden

  @regression
  Scenario: Empty state when employee has no requests
    Given I am authenticated as employee "newbie@company.com" with role "Employee"
    And the employee has no vacation requests
    When I navigate to "My Requests"
    Then I see the empty state message "No vacation requests yet. Submit your first request."

  Scenario Outline: Status badges use correct colour coding
    Given I have a vacation request with status "<status>"
    When I navigate to "My Requests"
    Then the status badge for that request displays colour "<colour>"
    Examples:
      | status    | colour |
      | Pending   | yellow |
      | Approved  | green  |
      | Rejected  | red    |
      | Cancelled | grey   |
