# Scenario: backend-only
# Step definitions: tests/ServiceNowIntegration.ReqnrollTests/StepDefinitions/ServiceNowIntegrationSteps.cs

@feature-005 @servicenow @import @monitoring
Feature: Balance Import and Export Monitoring
  As the system scheduler and as an administrator
  I want to import vacation balances from ServiceNow and monitor integration health
  So that employees see accurate balances and IT can troubleshoot failures

  Background:
    Given I am authenticated as "admin@company.com" with role "Administrator"
    And the ServiceNow balance import is configured to run at "6:00 AM"

  @smoke @P1
  Scenario: Import job fetches vacation balance for all active employees
    Given 487 active employees exist in the system
    When the nightly balance import job runs at "6:00 AM"
    Then the import job queries ServiceNow for all 487 employee balances
    And each employee's VacationTotalDays, VacationUsedDays are updated
    And BalanceUpdatedAt is set to the current timestamp

  @regression @P1
  Scenario: System uses stale balance data when ServiceNow is unavailable
    Given the ServiceNow API is unavailable (circuit breaker open)
    When the nightly balance import job attempts to run
    Then the import job is skipped
    And a warning is logged indicating stale balance data is being used
    And employees can still submit requests using the last known balance

  @smoke @P1
  Scenario: Admin views last export job status from the admin panel
    Given the last export job completed on "2026-08-07T04:15:00Z" with TotalExported=12
    When I GET "/api/admin/servicenow/export/status"
    Then the response shows status "Completed"
    And the response shows TotalExported=12 and ErrorCount=0

  @regression @P1
  Scenario: Admin views failed export records with details
    Given the last export job has 2 failed records for employees "err1@company.com" and "err2@company.com"
    When I GET "/api/admin/servicenow/export/failed"
    Then the response lists 2 failed records
    And each record shows employee name, dates, error message, and retry count

  @regression @P1
  Scenario: Admin manually retries a permanently failed export record
    Given an export record for "ana.garcia@company.com" has status "MaxRetriesExceeded"
    When I POST to "/api/admin/servicenow/export/{recordId}/retry"
    Then the export record's retry count is reset
    And the record is re-queued for export

  @regression
  Scenario: Alert sent to admin when export error rate exceeds 5%
    Given the export job processes 50 records with 3 permanent failures
    When the export job completes
    Then an "ExportJobCompleted" event is published with ErrorCount=3
    And a notification alert is triggered because error rate is 6% (exceeds 5% threshold)
