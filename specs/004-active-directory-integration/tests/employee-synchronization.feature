# Scenario: backend-only
# Step definitions: tests/IdentitySync.ReqnrollTests/StepDefinitions/AdSyncSteps.cs

@feature-004 @ad-sync @employee-sync
Feature: Nightly Employee Synchronization
  As the system scheduler
  I want to synchronize employee data from Active Directory every night
  So that the vacation system always reflects the current organizational structure

  Background:
    Given the AD sync is configured to run at "2:00 AM"
    And Microsoft Graph API is available and returns valid employee data

  @smoke @P1
  Scenario: Scheduled sync fetches all employees from AD
    When the scheduled AD sync job runs at "2:00 AM"
    Then the sync job calls the Microsoft Graph API to fetch all users
    And the sync job is created with status "Running"

  @smoke @P1
  Scenario: New employees in AD are created in the system with Active status
    Given AD contains a new employee with email "newbie@company.com" not yet in the system
    When the AD sync job runs
    Then a new employee record is created for "newbie@company.com" with status "Active"
    And the employee's role defaults to "Employee"

  @smoke @P1
  Scenario: Sync job writes a summary log on completion
    Given the AD sync job processes 500 employees
    When the sync job completes
    Then a sync job record is written with fields: TotalProcessed, Created, Updated, Deactivated, ErrorCount
    And the sync job status is "Completed" or "CompletedWithErrors"

  @regression @P1
  Scenario: Employees removed from AD are soft-deleted
    Given employee "former@company.com" is disabled in AD (accountEnabled=false)
    And "former@company.com" exists in the system with status "Active"
    When the AD sync job runs
    Then "former@company.com" is marked as "Inactive" in the system
    And the employee record is NOT hard-deleted

  @regression @P1
  Scenario: Department change in AD updates the employee's department assignment
    Given employee "ana.garcia@company.com" belongs to department "Engineering" in the system
    And in AD "ana.garcia@company.com" now belongs to department "Marketing"
    When the AD sync job runs
    Then "ana.garcia@company.com" is reassigned to department "Marketing" in the system

  @regression @P1
  Scenario: Failed records are retried up to 3 times with exponential backoff
    Given the Graph API returns an error for employee "error@company.com" on the first 2 attempts
    And it succeeds on the 3rd attempt
    When the AD sync job processes that employee
    Then the employee is successfully created after 3 attempts
    And the error is recorded with retry count 2 before final success

  @regression
  Scenario: Sync completes within 30 minutes for 500 employees
    Given AD contains 500 active employees
    When the sync job starts
    Then the sync job completes within 30 minutes
