# Scenario: backend+frontend (fullstack)
# Step definitions: tests/ApprovalWorkflow.ReqnrollTests/StepDefinitions/ApprovalWorkflowSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/approval/department-approval.spec.ts

@feature-002 @approval-workflow @department-approval
Feature: Department-Level Approval
  As a department manager
  I want to provide final approval on requests that have passed project-level review
  So that I can ensure department-wide coverage compliance

  Background:
    Given the following employees exist:
      | name           | email                          | role              | department  |
      | Laura Sánchez  | laura.sanchez@company.com      | DepartmentManager | Engineering |
      | Carlos Ruiz    | carlos.ruiz@company.com        | ProjectManager    | Engineering |
      | Ana García     | ana.garcia@company.com         | Employee          | Engineering |
    And I am authenticated as "laura.sanchez@company.com" with role "DepartmentManager"
    And employee "ana.garcia@company.com" has a "PendingDepartmentApproval" vacation request from "2026-08-10" to "2026-08-14"

  @smoke @P1
  Scenario: DM gives final approval to a project-approved request
    When I approve the vacation request for "ana.garcia@company.com" at department level
    Then the request status changes to "Approved"
    And an approval step is recorded at level "Department" with decision "Approved"
    And a "VacationRequestApprovedFinal" event is published

  @smoke @P1
  Scenario: DM rejects a project-approved request with a reason
    When I reject the vacation request for "ana.garcia@company.com" with reason "Summer peak period coverage needed"
    Then the request status changes to "Rejected"
    And a "VacationRequestRejectedFinal" event is published

  @regression @P1
  Scenario: DM queue includes both project-approved and appealed project-rejected requests
    Given employee "pedro.garcia@company.com" has a "RejectedAtProjectLevel" request that was appealed
    When I navigate to my department approval queue
    Then I see the "PendingDepartmentApproval" request from "ana.garcia@company.com"
    And I see the appealed request from "pedro.garcia@company.com"

  @regression @P1
  Scenario: DM sees capacity warning when approving an over-requested period
    Given the capacity for "2026-08-10" to "2026-08-14" is 72%
    When I view the request for "ana.garcia@company.com" in my approval queue
    Then a visual capacity warning is displayed showing "72% capacity"
    And suggested alternative dates are offered

  @regression @P1
  Scenario: Final approval triggers capacity snapshot update
    When I approve the vacation request for "ana.garcia@company.com" at department level
    Then the capacity snapshot for the affected period is recalculated

  @regression
  Scenario: Employee can appeal a project-level rejection to the DM
    Given employee "ana.garcia@company.com" has a "RejectedAtProjectLevel" vacation request
    When employee "ana.garcia@company.com" appeals the rejection
    Then the request status changes to "PendingDepartmentApproval"
    And the request appears in the DM approval queue
