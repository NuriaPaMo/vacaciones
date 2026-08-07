# Scenario: backend+frontend (fullstack)
# Step definitions: tests/ReportingAdmin.ReqnrollTests/StepDefinitions/ReportingAdminSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/reporting/vacation-history-report.spec.ts

@feature-007 @reporting @vacation-history
Feature: Vacation History Report
  As a department manager
  I want to generate a report of all vacations by employee, date range, and status
  So that I can analyze vacation patterns and plan for coverage needs

  Background:
    Given I am authenticated as "laura.sanchez@company.com" with role "DepartmentManager"
    And the department "Engineering" has historical vacation data for 2026

  @smoke @P1
  Scenario: DM navigates to reports and applies filters
    When I navigate to "Reports > Vacation History"
    Then I can filter by: date range, department, project, employee, and status
    And the filter panel is visible

  @smoke @P1
  Scenario: Filtered report displays correct columns
    When I generate a vacation history report for the current year
    Then the report shows: employee name, dates, total days, status, and approvers
    And results are scoped to my department only

  @regression @P1
  Scenario: Report is scoped to DM's department only
    Given employee "other.dept@company.com" belongs to a different department
    When I generate the vacation history report
    Then "other.dept@company.com" does not appear in the report

  @regression @P1
  Scenario: Report can be exported to CSV
    When I generate a vacation history report
    And I click "Export" and select "CSV"
    Then a CSV file is downloaded with the report data

  @regression @P1
  Scenario: Report generation completes within 5 seconds for 1 year of data
    Given the department has 1 year of vacation history (approximately 500 records)
    When I generate the report without date filters
    Then the report results appear within 5000 milliseconds

  @regression
  Scenario: Administrator can view reports across all departments
    Given I am authenticated as "admin@company.com" with role "Administrator"
    When I generate a vacation history report without a department filter
    Then the report includes vacations from all departments
