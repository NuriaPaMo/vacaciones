# Scenario: backend-only
# Step definitions: tests/ServiceNowIntegration.ReqnrollTests/StepDefinitions/ServiceNowIntegrationSteps.cs

@feature-005 @servicenow @export
Feature: Nightly Vacation Export to ServiceNow
  As the system scheduler
  I want to export all newly-approved vacations to ServiceNow every night
  So that the corporate ITSM system reflects current vacation records

  Background:
    Given the ServiceNow export is configured to run at "4:00 AM"
    And the ServiceNow Table API is available

  @smoke @P1
  Scenario: Export job queries all approved unexported requests
    Given 3 vacation requests are "Approved" and not yet exported
    When the nightly export job runs at "4:00 AM"
    Then the export job queries requests with status "Approved" and IsExported=false
    And an export job record is created with status "Running"

  @smoke @P1
  Scenario: Approved requests are POSTed to ServiceNow Table API
    Given 2 vacation requests are "Approved" and not yet exported
    When the nightly export job runs
    Then each request is POSTed to the ServiceNow Table API with correct field mapping
    And the response sys_id from ServiceNow is stored on each export record

  @smoke @P1
  Scenario: Successfully exported request is marked as exported with timestamp
    Given 1 vacation request is "Approved" and not yet exported
    When the nightly export job completes successfully
    Then the vacation request has IsExported=true
    And ExportedAt is set to the current timestamp
    And the ServiceNow sys_id is stored on the request

  @regression @P1
  Scenario: Cancelled previously-exported request triggers removal in ServiceNow
    Given a vacation request was previously exported with ServiceNow sys_id "SYS001"
    And the request has since been "Cancelled"
    When the nightly export job runs
    Then a DELETE request is sent to ServiceNow for record "SYS001"

  @regression @P1
  Scenario: Failed export record is retried up to 3 times
    Given 1 vacation request needs to be exported
    And the ServiceNow API returns error on first 2 attempts and succeeds on the 3rd
    When the nightly export job runs
    Then the export record is created with RetryCount=2 and Status="Succeeded"

  @regression @P1
  Scenario: Export job writes a summary log on completion
    Given 5 requests are approved and ready to export
    When the nightly export job completes
    Then the export job record shows TotalExported=5, TotalUpdated=0, TotalDeleted=0, ErrorCount=0

  @regression
  Scenario: Failed record does not block the rest of the batch
    Given 3 vacation requests need to be exported
    And the ServiceNow API permanently fails for the 2nd record
    When the nightly export job runs
    Then the 1st and 3rd records are successfully exported
    And the 2nd record is marked "MaxRetriesExceeded"
    And the export job status is "CompletedWithErrors"
