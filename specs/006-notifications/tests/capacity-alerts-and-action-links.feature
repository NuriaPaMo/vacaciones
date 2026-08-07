# Scenario: backend-only
# Step definitions: tests/Notifications.ReqnrollTests/StepDefinitions/NotificationSteps.cs

@feature-006 @notifications @capacity-alerts @action-links
Feature: Capacity Alert Notifications and Action Links
  As a department manager and as a project manager
  I want to receive proactive alerts and actionable email links
  So that I can take action without searching for the request

  Background:
    Given the notification templates are seeded
    And the critical capacity threshold is 70%
    And the warning threshold is 65%

  @smoke @P1
  Scenario: DM receives warning alert when capacity crosses 65-70% threshold
    Given the capacity for "Engineering" on "2026-08-12" crosses 67%
    When the "CapacityWarningThresholdCrossed" event is consumed
    Then an email alert is sent to the department manager "laura.sanchez@company.com"
    And the email contains the affected date "2026-08-12" and capacity percentage 67%

  @regression @P1
  Scenario: DM and all affected PMs receive critical alert when capacity exceeds 70%
    Given the capacity for "Engineering" on "2026-08-12" crosses 75%
    When the "CapacityCriticalThresholdCrossed" event is consumed
    Then an email is sent to "laura.sanchez@company.com" (DM)
    And an email is sent to all project managers in "Engineering"
    And a Teams message is sent to each recipient (BR-100)

  @regression @P1
  Scenario: System deduplicates capacity alerts for the same period and level
    Given a capacity alert was already sent for "Engineering" on "2026-08-12" at "Warning" level
    When another "CapacityWarningThresholdCrossed" event fires for the same date
    Then no duplicate alert email is sent
    And the "CapacityAlert" deduplication record prevents re-alerting

  @smoke @P1
  Scenario: Action link in email navigates to the correct request page
    Given an email with action link is sent for request "REQ-001" to "carlos.ruiz@company.com"
    When "carlos.ruiz@company.com" clicks the action link from the email
    Then the link validates successfully
    And the user is redirected to the vacation request detail page for "REQ-001"

  @regression @P1
  Scenario: Action link is user-scoped and rejects different user
    Given an action link was generated for "carlos.ruiz@company.com"
    When "laura.sanchez@company.com" attempts to use the same link
    Then the link validation fails with "INVALID_TOKEN"

  @regression @P1
  Scenario: Action link expires after 7 days
    Given an action link was generated 8 days ago for "carlos.ruiz@company.com"
    When "carlos.ruiz@company.com" clicks the link
    Then the link is rejected as expired
    And the user is redirected to the login page with the return URL preserved

  @regression
  Scenario: Teams delivery failure does not block email delivery
    Given the Teams API returns an error
    When a critical capacity alert notification is processed
    Then the email notification is still sent successfully
    And the Teams failure is logged but does not affect the workflow
