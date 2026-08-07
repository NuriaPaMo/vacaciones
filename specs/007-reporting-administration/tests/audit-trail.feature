# Scenario: backend+frontend (fullstack)
# Step definitions: tests/ReportingAdmin.ReqnrollTests/StepDefinitions/ReportingAdminSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/reporting/audit-trail.spec.ts

@feature-007 @reporting @audit-trail
Feature: Audit Trail
  As an auditor
  I want to access a complete, searchable log of all system actions
  So that I can verify compliance with vacation policies and regulations

  Background:
    Given I am authenticated as "auditor@company.com" with role "Administrator"
    And the system has been recording audit entries for all actions

  @smoke @P1
  Scenario: Auditor views all system actions in the audit trail
    When I navigate to the audit trail
    Then I see entries for all user actions: create, approve, reject, cancel, delegate, configure
    And entries are displayed in reverse chronological order

  @smoke @P1
  Scenario: Each audit entry contains required fields
    Given a vacation request was submitted by "ana.garcia@company.com" at "2026-08-07T09:00:00Z"
    When I view the corresponding audit entry
    Then the audit entry contains:
      | field           | value                       |
      | Timestamp       | 2026-08-07T09:00:00Z        |
      | UserIdentity    | ana.garcia@company.com      |
      | ActionType      | Created                     |
      | EntityType      | VacationRequest             |

  @regression @P1
  Scenario: Auditor searches audit trail by user
    When I filter the audit trail by user "ana.garcia@company.com"
    Then only audit entries performed by "ana.garcia@company.com" are shown

  @regression @P1
  Scenario: Auditor searches audit trail by action type
    When I filter the audit trail by action type "Approved"
    Then only approval audit entries are shown

  @regression @P1
  Scenario: Integration and background job events are included in audit trail
    When I navigate to the audit trail
    Then I can see entries for AD sync job executions
    And entries for ServiceNow export operations
    And entries for escalation triggers

  @regression @P1
  Scenario: Audit trail is append-only and cannot be modified
    Given an audit entry exists with id "AUDIT-001"
    When I attempt to update or delete that audit entry via the API
    Then the operation is rejected with HTTP 405 Method Not Allowed

  @regression
  Scenario: Audit log records are retained for 7 years
    Given audit entries older than 7 years do not exist
    When I query the audit trail for records from 8 years ago
    Then no results are returned
    But records from 6 years ago are returned (within retention period)
