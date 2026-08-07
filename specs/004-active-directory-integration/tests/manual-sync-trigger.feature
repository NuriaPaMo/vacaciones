# Scenario: backend-only
# Step definitions: tests/IdentitySync.ReqnrollTests/StepDefinitions/AdSyncSteps.cs

@feature-004 @ad-sync @manual-sync
Feature: Manual Sync Trigger and Monitoring
  As an administrator
  I want to manually trigger an AD synchronization and monitor sync health
  So that I can immediately reflect organizational changes and troubleshoot failures

  Background:
    Given I am authenticated as "admin@company.com" with role "Administrator"
    And no AD sync job is currently running

  @smoke @P1
  Scenario: Administrator triggers a manual AD sync
    When I POST to "/api/admin/ad-sync/trigger"
    Then the response status is 202 Accepted
    And a new sync job is created with type "Manual"
    And the response body contains the job id

  @smoke @P1
  Scenario: Admin views the last sync job status
    Given the last sync job completed successfully on "2026-08-07T02:30:00Z" processing 487 employees
    When I GET "/api/admin/ad-sync/status"
    Then the response shows status "Completed"
    And the response shows TotalProcessed=487 and ErrorCount=0

  @regression @P1
  Scenario: System prevents duplicate manual sync while one is running
    Given a sync job is already "Running"
    When I POST to "/api/admin/ad-sync/trigger"
    Then the response status is 409 Conflict
    And the response body contains "Sync already running"

  @regression @P1
  Scenario: System enforces rate limit of 1 manual sync per hour
    Given a manual sync ran successfully 30 minutes ago
    When I attempt to trigger another manual sync
    Then the response status is 429 Too Many Requests
    And the response indicates when the next sync is allowed

  @smoke @P1
  Scenario: Admin views sync history for the last 30 days
    Given 5 sync jobs have completed in the last 30 days
    When I GET "/api/admin/ad-sync/history"
    Then the response contains 5 sync job summary records
    And each record shows type, status, start time, and counts

  @regression @P1
  Scenario: Admin views specific failed records from a sync job
    Given the last sync job has 3 failed records
    When I GET "/api/admin/ad-sync/{jobId}/errors"
    Then the response lists the 3 failed records with their AD id and error message

  @regression
  Scenario: Sync failure alert sent to admin when error rate exceeds 5%
    Given the AD sync processes 100 employees with 6 errors
    When the sync job completes
    Then a "SyncJobCompleted" event is published with ErrorCount=6
    And a notification alert is triggered because error rate is 6% (exceeds 5% threshold)
