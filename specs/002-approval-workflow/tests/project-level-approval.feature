# Scenario: backend+frontend (fullstack)
# Step definitions: tests/ApprovalWorkflow.ReqnrollTests/StepDefinitions/ApprovalWorkflowSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/approval/project-approval.spec.ts

@feature-002 @approval-workflow @project-approval
Feature: Project-Level Approval
  As a project manager
  I want to approve or reject vacation requests from my team members
  So that I can ensure adequate project coverage before escalating to department level

  Background:
    Given the following employees exist:
      | name           | email                         | role           | project         |
      | Carlos Ruiz    | carlos.ruiz@company.com       | ProjectManager | Project Phoenix |
      | Ana García     | ana.garcia@company.com        | Employee       | Project Phoenix |
    And I am authenticated as "carlos.ruiz@company.com" with role "ProjectManager"
    And employee "ana.garcia@company.com" has a "Pending" vacation request from "2026-08-10" to "2026-08-14"

  @smoke @P1
  Scenario: PM approves a pending request advancing it to department level
    When I approve the vacation request for "ana.garcia@company.com"
    Then the request status changes to "PendingDepartmentApproval"
    And an approval step is recorded at level "Project" with decision "Approved"
    And a "VacationRequestApprovedAtProjectLevel" event is published

  @smoke @P1
  Scenario: PM rejects a request with a mandatory reason
    When I reject the vacation request for "ana.garcia@company.com" with reason "Critical project deadline"
    Then the request status changes to "RejectedAtProjectLevel"
    And an approval step is recorded at level "Project" with decision "Rejected"
    And the rejection reason "Critical project deadline" is stored

  @smoke @P1
  Scenario: PM views approval queue showing only their project members
    Given employee "maria.lopez@company.com" with role "Employee" belongs to project "Project Atlas"
    And employee "maria.lopez@company.com" has a "Pending" vacation request
    When I navigate to my approval queue
    Then I see the request from "ana.garcia@company.com"
    And I do not see the request from "maria.lopez@company.com"

  @regression @P1
  Scenario: PM cannot reject a request without providing a reason
    When I attempt to reject the vacation request with an empty reason
    Then the rejection is blocked with error "Rejection reason is required"

  @regression @P1
  Scenario: PM cannot reject with a reason shorter than 10 characters
    When I attempt to reject the vacation request with reason "Too short"
    Then the rejection is blocked with validation error on the reason field

  @regression @P1
  Scenario: Approved request at project level shows status Pending Department Approval
    When I approve the vacation request for "ana.garcia@company.com"
    Then the request status displayed is "Pending Department Approval"
    And the DM has not yet acted on the request

  @regression
  Scenario: Approval queue displays required fields per item
    When I navigate to my approval queue
    Then each queue item shows employee name, dates, total days, submission date, and capacity impact
