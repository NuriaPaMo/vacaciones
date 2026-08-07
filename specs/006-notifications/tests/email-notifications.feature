# Scenario: backend-only
# Step definitions: tests/Notifications.ReqnrollTests/StepDefinitions/NotificationSteps.cs

@feature-006 @notifications @email
Feature: Email Notifications for Workflow Events
  As an employee
  I want to receive email notifications when my vacation request status changes
  So that I am immediately informed without having to check the application

  Background:
    Given the SMTP server is configured and available
    And notification templates are seeded for all event types

  @smoke @P1
  Scenario: PM receives email notification when a new request is submitted
    Given employee "ana.garcia@company.com" submits a vacation request from "2026-08-10" to "2026-08-14"
    When the "VacationRequestSubmitted" event is consumed by the notification handler
    Then an email notification is sent to project manager "carlos.ruiz@company.com"
    And the email contains the request dates, employee name, and an action deep-link

  @smoke @P1
  Scenario: Employee receives approval confirmation email
    Given the vacation request for "ana.garcia@company.com" is finally approved
    When the "VacationRequestApprovedFinal" event is consumed
    Then an email is sent to "ana.garcia@company.com" confirming the approval
    And the email subject matches the "RequestApprovedFinal" template

  @smoke @P1
  Scenario: Employee receives rejection email with reason
    Given the vacation request for "ana.garcia@company.com" is rejected with reason "Peak period"
    When the "VacationRequestRejectedFinal" event is consumed
    Then an email is sent to "ana.garcia@company.com" with the rejection reason "Peak period"
    And the email contains a link back to the application

  @regression @P1
  Scenario: Approvers notified when employee cancels an approved request
    Given "ana.garcia@company.com" cancels an "Approved" vacation request
    When the "VacationRequestCancelled" event is consumed
    Then email notifications are sent to both the PM and the DM
    And the email indicates the request was previously approved

  @regression @P1
  Scenario: Email is delivered within 5 minutes of the triggering event
    When a "VacationRequestSubmitted" event is published at "2026-08-07T10:00:00Z"
    Then the corresponding email is sent before "2026-08-07T10:05:00Z"

  @regression @P1
  Scenario: Failed email delivery is retried up to 3 times
    Given the SMTP server returns an error on the first 2 attempts
    When the notification handler processes the event
    Then the email is retried with exponential backoff
    And the email is successfully sent on the 3rd attempt
    And the notification record is marked "Sent"

  @regression
  Scenario: Email uses Avanade-branded HTML template
    When any workflow email notification is sent
    Then the email body contains Avanade branding elements
    And the email is in HTML format
