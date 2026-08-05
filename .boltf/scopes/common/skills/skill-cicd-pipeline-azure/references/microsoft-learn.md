# CI/CD Pipeline Azure - Microsoft Learn Resources

Curated documentation for the **orchestration layer**. These links help the skill reason about provider choice, approvals, strategies, and security posture before delegating to the provider-specific skill.

---

## Constitution-to-Provider Decision Support

- [Deploy to Azure using GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/github/github-actions) - good high-level overview when Article XI points toward GitHub-native delivery
- [Azure Pipelines documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/) - good high-level overview when Article XI points toward Azure DevOps-native delivery
- [YAML pipeline schema](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/) - reference for Azure Pipelines structure
- [GitHub Actions documentation](https://docs.github.com/en/actions) - reference for workflow structure and environment controls

Use this group when the question is still “which provider path fits the constitution?” rather than “what exact YAML should I write?”

---

## Authentication and Security Posture

- [Use GitHub Actions to connect to Azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure) - OIDC / workload identity for GitHub Actions
- [Configure OpenID Connect in Azure for GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure) - GitHub-side OIDC setup
- [Azure Resource Manager service connection using workload identity federation](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure#create-an-azure-resource-manager-service-connection-using-workload-identity-federation) - Azure DevOps equivalent
- [Secure Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/overview) - overall security posture for Azure Pipelines
- [Security hardening for GitHub Actions](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions) - GitHub-specific hardening guidance

These links support the orchestration rule that passwordless federation is preferred over long-lived secrets.

---

## Environments, Approvals, and Promotion Flow

- [Using environments for deployment in GitHub Actions](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) - reviewers, protection rules, deployment history
- [Azure DevOps environments](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments) - environments, checks, and deployment history
- [Approvals in Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals) - manual approval configuration
- [Stages in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/stages) - explicit stage design and dependencies

Use these when Article XI defines promotion flow or approval requirements that the provider skill must implement.

---

## Deployment Strategies

- [Deployment slots for App Service](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots) - blue-green on App Service
- [Deployment jobs in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs) - `runOnce`, `rolling`, and deployment-specific orchestration
- [Container Apps revisions and traffic splitting](https://learn.microsoft.com/en-us/azure/container-apps/revisions-manage#traffic-splitting) - canary-style rollout for Container Apps
- [Canary deployment pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/deployment-stamp#canary-deployment) - architectural framing for gradual rollout

Use these when the constitution defines rollout strategy and the provider skill needs a hosting-aligned implementation pattern.

---

## Infrastructure Pipeline Alignment

- [Deploy Bicep with GitHub Actions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions) - GitHub-side Bicep delivery
- [Deploy Bicep with Azure Pipelines](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-azure-pipelines) - Azure DevOps-side Bicep delivery
- [Deploy Terraform using GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/terraform/deploy-terraform-using-github-actions) - Terraform in GitHub Actions
- [Terraform task for Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/terraform-task-v4) - Terraform integration in Azure Pipelines

These links help the orchestrator verify that provider choice still supports the constitutionally required IaC stages.

---

## Quality Gates and Verification

- [Publish test results in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/publish-test-results-v2) - quality reporting in Azure DevOps
- [Code coverage results in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/test/review-code-coverage-results) - coverage reporting
- [Workflow run logs in GitHub Actions](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/using-workflow-run-logs) - provider-side troubleshooting
- [Pipeline report in Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/pipelines/reports/pipelinereport) - deployment and pipeline analytics

Use these when validating whether the concrete provider pipeline can satisfy the constitution's quality gates and release verification expectations.
