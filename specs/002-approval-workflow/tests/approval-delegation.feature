# Scenario: backend+frontend (fullstack)
# Step definitions: tests/ApprovalWorkflow.ReqnrollTests/StepDefinitions/ApprovalWorkflowSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/approval/delegation.spec.ts

@feature-002 @approval-workflow @delegation
Feature: Approval Delegation
  As an approver (PM or DM)
  I want to delegate my approval authority to another person
  So that vacation requests are not blocked when I am unavailable

  Background:
    Given the following employees exist:
      | name          | email                          | role           | project         |
      | Carlos Ruiz   | carlos.ruiz@company.com        | ProjectManager | Project Phoenix |
      | Maria Fernandez | maria.fernandez@company.com  | ProjectManager | Project Phoenix |
    And I am authenticated as "carlos.ruiz@company.com" with role "ProjectManager"

  @smoke @P1
  Scenario: PM creates a temporary delegation to a designated backup
    When I create a delegation to "maria.fernandez@company.com" from "2026-08-15" to "2026-08-22" at scope "ProjectLevel"
    Then the delegation is created with status "Active"
    And "maria.fernandez@company.com" now has approval authority for "Project Phoenix" during that period

  @smoke @P1
  Scenario: Delegated approval is recorded with both delegate and original approver identities
    Given I have an active delegation to "maria.fernandez@company.com" at scope "ProjectLevel"
    And employee "ana.garcia@company.com" has a "Pending" vacation request
    When "maria.fernandez@company.com" approves the request on my behalf
    Then the approval step records "maria.fernandez@company.com" as the approver
    And the approval step records "carlos.ruiz@company.com" as the original approver
    And the flag "IsDelegate" is true on the approval step

  @regression @P1
  Scenario: Both delegator and delegate can see and act on pending requests
    Given I have an active delegation to "maria.fernandez@company.com" at scope "ProjectLevel"
    And employee "ana.garcia@company.com" has a "Pending" vacation request
    When I navigate to the approval queue as "carlos.ruiz@company.com"
    Then I see the pending request from "ana.garcia@company.com"
    When I navigate to the approval queue as "maria.fernandez@company.com"
    Then I also see the pending request from "ana.garcia@company.com"

  @regression @P1
  Scenario: Delegation automatically expires after the end date
    Given I have a delegation to "maria.fernandez@company.com" from "2026-08-15" to "2026-08-16"
    When the date advances past "2026-08-16"
    Then the delegation status becomes "Expired"
    And "maria.fernandez@company.com" no longer has approval authority

  @regression @P1
  Scenario: Approver revokes a delegation before its end date
    Given I have an active delegation to "maria.fernandez@company.com" until "2026-08-22"
    When I revoke the delegation on "2026-08-18"
    Then the delegation is immediately deactivated
    And "maria.fernandez@company.com" loses approval authority immediately

  @regression @P1
  Scenario: Permanent delegation remains active until explicitly revoked
    When I create a permanent delegation to "maria.fernandez@company.com" without an end date
    Then the delegation is active with no expiry date
    And it remains active until I explicitly revoke it

  @regression
  Scenario: System prevents circular delegation
    Given "maria.fernandez@company.com" has already delegated to "carlos.ruiz@company.com"
    When I attempt to create a delegation from "carlos.ruiz@company.com" to "maria.fernandez@company.com"
    Then the delegation creation fails with error "Circular delegation is not allowed"

  @regression
  Scenario: System enforces maximum one active delegation per approver per scope
    Given I already have an active delegation to "maria.fernandez@company.com" at scope "ProjectLevel"
    When I attempt to create another delegation at scope "ProjectLevel" to "another.person@company.com"
    Then the delegation creation fails with error "An active delegation already exists for this scope"
