# Scenario: backend+frontend (fullstack)
# Step definitions: tests/ReportingAdmin.ReqnrollTests/StepDefinitions/ReportingAdminSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/admin/system-configuration.spec.ts

@feature-007 @admin @system-configuration
Feature: System Configuration
  As an administrator
  I want to configure system parameters through an admin interface
  So that I can manage the system without developer intervention

  Background:
    Given I am authenticated as "admin@company.com" with role "Administrator"

  @smoke @P1
  Scenario: Admin accesses the configuration panel
    When I navigate to the admin panel
    Then I see configuration options for: capacity thresholds, escalation timeframes, and batch job schedules

  @smoke @P1
  Scenario: Admin changes the critical capacity threshold
    When I change the global critical threshold from 70% to 75%
    Then the configuration is saved with new value 75%
    And future capacity calculations use the new threshold of 75%

  @regression @P1
  Scenario: Configuration change takes effect immediately without restart
    When I change the escalation reminder threshold from 3 days to 5 days
    Then the new value is active immediately
    And the next escalation check uses the 5-day threshold

  @regression @P1
  Scenario: Admin updates a notification template
    When I edit the "RequestApprovedFinal" email template subject to "Your vacation is confirmed!"
    Then future approval notification emails use the subject "Your vacation is confirmed!"

  @regression @P1
  Scenario: Configuration change is recorded in the audit trail with before/after values
    When I change the critical threshold from 70% to 75%
    Then an audit entry is created with:
      | field       | value     |
      | ActionType  | ConfigChanged |
      | OldValues   | {"value":"70"} |
      | NewValues   | {"value":"75"} |

  @regression @P1
  Scenario: Admin sets a department-specific threshold overriding the global default
    When I set a department-specific critical threshold of 80% for "Engineering"
    Then the "Engineering" department uses threshold 80%
    And other departments continue to use the global threshold of 70%

  Scenario Outline: Threshold validation enforces bounds
    When I attempt to set the critical threshold to <value>%
    Then the configuration update result is "<result>"
    Examples:
      | value | result   |
      | 0     | rejected |
      | 1     | accepted |
      | 100   | accepted |
      | 101   | rejected |
      | 75    | accepted |
