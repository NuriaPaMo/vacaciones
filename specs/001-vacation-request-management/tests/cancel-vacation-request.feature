# Scenario: backend+frontend (fullstack)
# Step definitions: tests/VacationManagement.ReqnrollTests/StepDefinitions/VacationRequestSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/vacation-requests/vacation-request-cancellation.spec.ts

@feature-001 @vacation-request @cancellation
Feature: Cancel Vacation Request
  As an authenticated employee
  I want to cancel a vacation request I previously submitted
  So that I can withdraw my request if my plans change

  Background:
    Given I am authenticated as employee "ana.garcia@company.com" with role "Employee"

  @smoke @P1
  Scenario: Employee cancels a pending request directly
    Given I have a "Pending" vacation request from "2026-08-10" to "2026-08-14"
    When I cancel that vacation request
    Then the request status changes to "Cancelled"
    And a status transition record is created with actor "ana.garcia" and from status "Pending"

  @smoke @P1
  Scenario: Employee cancels an approved request with confirmation
    Given I have an "Approved" vacation request from "2026-08-10" to "2026-08-14"
    When I click "Cancel" on that vacation request
    Then a confirmation dialog is displayed asking to confirm cancellation
    When I confirm the cancellation
    Then the request status changes to "Cancelled"

  @regression @P1
  Scenario: Cancellation of approved request triggers notification to approvers
    Given I have an "Approved" vacation request from "2026-08-10" to "2026-08-14"
    When I confirm cancellation of that request
    Then a "RequestCancelled" event is published to the Service Bus
    And the event contains the previous status "Approved"

  @regression @P1
  Scenario: Cancel button is not shown for rejected or already cancelled requests
    Given I have a "Rejected" vacation request from "2026-08-10" to "2026-08-14"
    When I view that vacation request
    Then no "Cancel" action button is visible

  @regression @P1
  Scenario: Employee dismisses the cancellation confirmation dialog
    Given I have an "Approved" vacation request from "2026-08-10" to "2026-08-14"
    When I click "Cancel" on that vacation request
    And the confirmation dialog appears
    And I click "Keep Request" to dismiss
    Then the request status remains "Approved"
    And no status transition record is created

  @regression
  Scenario: System prevents cancellation of another employee's request
    Given employee "pedro.lopez@company.com" has a "Pending" vacation request
    When I attempt to cancel that request as "ana.garcia@company.com"
    Then the cancellation is rejected with HTTP 403 "FORBIDDEN"

  @regression
  Scenario: Double-click on Cancel does not create two cancellations
    Given I have a "Pending" vacation request from "2026-08-10" to "2026-08-14"
    When I rapidly double-click "Cancel" on that vacation request
    Then only one status transition is created
    And the final status is "Cancelled"
