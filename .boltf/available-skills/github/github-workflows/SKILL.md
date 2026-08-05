---
name: github-workflows
description:
  'Create, update, and manage GitHub workflows and GitHub Actions using MCP tools. Use this skill
  when users want to create or update GitHub workflows, or create Status Checks for a commit to
  pass. Triggers on requests like "create a new GitHub Workflow", "create a Status Check", "update
  the CI workfflow", or any GitHub Actions management task.'
---

# GitHub Workflows an Actions

Manage GitHub workflows and actions using the `@modelcontextprotocol/server-github` MCP server.

## Available MCP Tools

| Tool                                        | Purpose                                                          |
| ------------------------------------------- | ---------------------------------------------------------------- |
| `mcp_github_get_workflow`                   | Get workflow details                                             |
| `mcp_github_get_workflow_run`               | Gets workflow run details                                        |
| `mcp_github_get_workflow_job`               | Fetch workflow job details                                       |
| `mcp_github_download_workflow_run_artifact` | Download a workflow run artifact                                 |
| `mcp_github_get_workflow_run_usage`         | Get workflow run usage                                           |
| `mcp_github_get_workflow_run_logs_url`      | Get workflow run logs URL                                        |
| `mcp_github_actions_list`                   | For listing workflows, runs, jobs, and artifacts                 |
| `mcp_github_actions_run_trigger`            | For triggering, re-running, canceling, or deleting workflow runs |
| `mcp_github_github_support_docs_search`     | For searching GitHub support documentation                       |

## Workflow

1. **Determine action**: Create, update, or query?
2. **Gather context**: Get repo info, existing workflows, runs
3. **Gather workflows**: Review [workflows](../../workflows/)
4. **Evaluate constitution**: Prioritize [constitution digest](.boltf/memory/constitution.digest.md)
5. **Evaluate architecture**: Follow [architecture guidelines](../../docs/architecture/README.md)
6. **Evaluate ADRs**: Follow relevant [ADRs](../../docs/adr/)
7. **Prefer reusable workflows**: Check for existing reusable workflows or consider if creating one
   is beneficial
8. **Execute**: Call the appropriate MCP tool
9. **Validate**: Review the run results, logs, and artifacts and decide accordingly

## Tips

- Ask for missing critical information rather than guessing
- Prefer reusable workflows when possible
- Read and follow GitHub Actions best practices
- Validate YAML syntax before creating or updating workflows
- Always prefer octokit and GitHub Actions over custom scripts
