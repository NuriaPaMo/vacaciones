# Scenario: backend+frontend (fullstack)
# Step definitions: tests/CapacityManagement.ReqnrollTests/StepDefinitions/CalendarCapacitySteps.cs
# Playwright E2E:   src/frontend/e2e/tests/calendar/team-calendar.spec.ts

@feature-003 @capacity @team-calendar
Feature: Team Calendar View
  As a project manager
  I want to see a visual calendar of my team's vacation schedule
  So that I can assess project coverage at a glance

  Background:
    Given I am authenticated as "carlos.ruiz@company.com" with role "ProjectManager"
    And the following approved vacations exist for "Project Phoenix":
      | employee            | start_date | end_date   | status   |
      | ana.garcia          | 2026-08-10 | 2026-08-14 | Approved |
      | pedro.lopez         | 2026-08-12 | 2026-08-16 | Pending  |

  @smoke @P1
  Scenario: PM views team calendar with vacation periods displayed
    When I navigate to "Team Calendar"
    Then I see a visual calendar with rows for each team member
    And "ana.garcia" shows a vacation period from "2026-08-10" to "2026-08-14"

  @smoke @P1
  Scenario: Calendar colour-codes vacations by status
    When I navigate to "Team Calendar"
    Then the vacation period for "ana.garcia" is displayed in green (Approved)
    And the vacation period for "pedro.lopez" is displayed in yellow (Pending)

  @regression @P1
  Scenario: PM switches between weekly and monthly calendar views
    When I navigate to "Team Calendar"
    And I switch to "Monthly" view
    Then the calendar updates to show the full month layout
    When I switch back to "Weekly" view
    Then the calendar shows the current week only

  @regression @P1
  Scenario: PM filters calendar to a custom date range
    When I navigate to "Team Calendar"
    And I set the date range filter from "2026-08-01" to "2026-08-31"
    Then only vacations within August 2026 are displayed

  @regression @P1
  Scenario: PM can only see their own team members on the calendar
    Given employee "maria.lopez@company.com" belongs to a different project
    When I navigate to "Team Calendar"
    Then "maria.lopez@company.com" is not visible on the calendar

  @regression
  Scenario: Calendar renders in under 1 second for 50 employees over 1 month
    Given "Project Phoenix" has 50 active employees with various vacations
    When I navigate to "Team Calendar" with a 1-month date range
    Then the calendar renders within 1000 milliseconds
