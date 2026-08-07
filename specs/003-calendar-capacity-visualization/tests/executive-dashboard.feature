# Scenario: backend+frontend (fullstack)
# Step definitions: tests/CapacityManagement.ReqnrollTests/StepDefinitions/CalendarCapacitySteps.cs
# Playwright E2E:   src/frontend/e2e/tests/calendar/dashboard.spec.ts

@feature-003 @capacity @dashboard
Feature: Executive Dashboard
  As a department manager
  I want a dashboard showing key vacation metrics and alerts
  So that I can quickly understand the current vacation landscape

  Background:
    Given I am authenticated as "laura.sanchez@company.com" with role "DepartmentManager"
    And the department "Engineering" has 10 active employees
    And today is "2026-08-07"

  @smoke @P1
  Scenario: DM views current vacation metrics on dashboard
    Given 3 employees have approved vacations including today "2026-08-07"
    When I open the department dashboard
    Then the metric "Current on vacation" shows 3
    And the metric "Available employees" shows 7
    And the metric "Pending approvals" shows the count of pending requests

  @smoke @P1
  Scenario: Dashboard highlights over-requested periods in next 90 days
    Given the period "2026-09-01" to "2026-09-05" has 80% capacity
    When I open the department dashboard
    Then a warning card is displayed for the over-requested period in September

  @regression @P1
  Scenario: Dashboard shows average approval time for last 30 days
    Given in the last 30 days approvals had the following durations in business days: 1, 2, 3, 4
    When I open the department dashboard
    Then the metric "Average approval time" shows 2.5 days

  @regression @P1
  Scenario: Dashboard data loads in under 2 seconds
    When I open the department dashboard
    Then all dashboard widgets are fully rendered within 2000 milliseconds

  @regression
  Scenario: DM can export dashboard metrics to PDF
    When I open the department dashboard
    And I click the "Export" button
    Then a PDF report is generated with the current dashboard metrics

  @regression
  Scenario: PM sees project-scoped dashboard data
    Given I am authenticated as "carlos.ruiz@company.com" with role "ProjectManager"
    When I open the dashboard
    Then I only see metrics for "Project Phoenix"
    And I do not see data from other departments
