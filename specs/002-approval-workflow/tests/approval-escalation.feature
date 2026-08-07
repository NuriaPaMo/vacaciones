# Scenario: backend-only (escalation is a background service)
# Step definitions: tests/ApprovalWorkflow.ReqnrollTests/StepDefinitions/ApprovalWorkflowSteps.cs

@feature-002 @approval-workflow @escalation
Feature: Approval Escalation
  As a department manager
  I want the system to alert me when requests have been pending too long
  So that no vacation request is forgotten or indefinitely delayed

  Background:
    Given the escalation thresholds are configured as reminder=3 days, escalation=5 days
    And employee "ana.garcia@company.com" has a "Pending" vacation request submitted 1 day ago
    And the request is awaiting project-level approval from "carlos.ruiz@company.com"

  @smoke @P1
  Scenario: System sends a reminder to PM after 3 business days
    Given the vacation request has been pending for 3 business days
    When the escalation background service runs
    Then an "EscalationReminder" event is published targeting "carlos.ruiz@company.com"
    And an escalation event record is created with type "Reminder"

  @regression @P1
  Scenario: System escalates to DM and enables bypass after 5 business days
    Given the vacation request has been pending for 5 business days
    When the escalation background service runs
    Then an "EscalationDirect" event is published targeting the department manager
    And the department manager can approve or reject the request directly
    And the PM retains their approval authority (BR-032)

  @regression @P1
  Scenario: Escalation event is recorded in the audit trail with timestamp
    Given the vacation request has been pending for 5 business days
    When the escalation background service runs
    Then an escalation event record is created with the current timestamp
    And the escalation is traceable via the audit trail

  @regression @P1
  Scenario: Escalation thresholds are configurable by administrators
    Given an administrator changes the reminder threshold to 5 days
    And a vacation request has been pending for 3 business days
    When the escalation background service runs
    Then no reminder is sent because the threshold is now 5 days

  @regression
  Scenario: Escalation does not auto-approve the request
    Given the vacation request has been pending for 5 business days
    When the escalation background service runs
    Then the request status remains "Pending"
    And the DM receives an alert but no approval is created automatically

  Scenario Outline: Escalation calculates pending days using business days only (BR-034)
    Given a request submitted on "<submitted_on>"
    And the escalation check runs on "<check_date>"
    Then the pending business days calculated is <pending_days>
    And the escalation type triggered is "<escalation_type>"
    Examples:
      | submitted_on | check_date | pending_days | escalation_type |
      | 2026-08-03   | 2026-08-06 | 3            | Reminder        |
      | 2026-08-03   | 2026-08-10 | 5            | DirectEscalation|
      | 2026-08-07   | 2026-08-10 | 1            | None            |
      | 2026-08-07   | 2026-08-12 | 3            | Reminder        |
