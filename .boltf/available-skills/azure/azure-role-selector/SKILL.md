---
name: azure-role-selector
description: Find the right Azure RBAC role for an identity with least privilege access. Use when assigning permissions, determining roles, or implementing principle of least privilege. Triggers => "Azure role", "RBAC", "assign permission", "least privilege", "what role for", "access policy Azure", "identity permissions", "contributor vs reader", "custom role Azure", "role assignment", "Azure permissions", "IAM role".
---

Use 'Azure MCP/documentation' tool to find the minimal role definition that matches the desired
permissions the user wants to assign to an identity (If no built-in role matches the desired
permissions, use 'Azure MCP/extension_cli_generate' tool to create a custom role definition with the
desired permissions). Use 'Azure MCP/extension_cli_generate' tool to generate the CLI commands
needed to assign that role to the identity and use the 'Azure MCP/bicepschema' and the 'Azure
MCP/get_bestpractices' tool to provide a Bicep code snippet for adding the role assignment.
