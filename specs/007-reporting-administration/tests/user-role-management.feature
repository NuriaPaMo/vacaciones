# Scenario: backend+frontend (fullstack)
# Step definitions: tests/ReportingAdmin.ReqnrollTests/StepDefinitions/ReportingAdminSteps.cs
# Playwright E2E:   src/frontend/e2e/tests/admin/user-management.spec.ts

@feature-007 @admin @user-management
Feature: User and Role Management
  As an administrator
  I want to manage user roles and delegation assignments
  So that I can control who has approval authority and system access

  Background:
    Given I am authenticated as "admin@company.com" with role "Administrator"
    And the following employees exist:
      | name         | email                          | role           |
      | Ana García   | ana.garcia@company.com         | Employee       |
      | Carlos Ruiz  | carlos.ruiz@company.com        | ProjectManager |

  @smoke @P1
  Scenario: Admin searches for a user and views their details
    When I search for "ana.garcia@company.com" in the user management panel
    Then I see "ana.garcia@company.com" with role "Employee"
    And I see their department, projects, and active delegations

  @regression @P1
  Scenario: Admin promotes an employee to Project Manager role
    When I change "ana.garcia@company.com" role from "Employee" to "ProjectManager"
    Then "ana.garcia@company.com" now has role "ProjectManager"
    And a role change audit entry is created with old role "Employee" and new role "ProjectManager"

  @regression @P1
  Scenario: Admin deactivates an employee account
    When I deactivate "ana.garcia@company.com"
    Then "ana.garcia@company.com" is marked as inactive
    And "ana.garcia@company.com" cannot log in or submit new requests

  @regression @P1
  Scenario: Admin views and revokes an active delegation
    Given "carlos.ruiz@company.com" has an active delegation to "backup@company.com"
    When I view the delegation list in the admin panel
    Then I see the delegation for "carlos.ruiz@company.com" to "backup@company.com"
    When I revoke that delegation
    Then "backup@company.com" immediately loses approval authority

  @regression @P1
  Scenario: System prevents deactivating the last administrator
    Given "admin@company.com" is the only active administrator
    When I attempt to deactivate "admin@company.com"
    Then the operation is rejected with error "Cannot deactivate the last administrator"

  @regression
  Scenario: Role change audit is automatically recorded
    When I change "carlos.ruiz@company.com" role to "DepartmentManager"
    Then the audit trail contains an entry with ActionType "RoleChanged"
    And the entry shows old value "ProjectManager" and new value "DepartmentManager"

  @regression
  Scenario: Deactivated employees retain their historical vacation data
    When I deactivate "ana.garcia@company.com"
    Then all past vacation requests for "ana.garcia@company.com" remain in the system
    And the audit trail is preserved for the deactivated user
