# Azure DevOps Pipeline Templates - Microsoft Learn Resources

Curated documentation for the Azure DevOps provider skill.

---

## Core YAML and Pipeline Concepts

- [Azure Pipelines documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/) - Azure DevOps Pipelines overview
- [YAML schema reference](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/) - complete YAML schema
- [Stages](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/stages) - stage design, dependencies, and conditions
- [Deployment jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs) - deployment-specific jobs and strategies
- [Templates](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/templates) - reusable YAML templates

---

## Environments and Approvals

- [Environments](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments) - environment model, deployment history, checks
- [Approvals](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals) - approval flows and checks
- [Gates](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/approvals/gates) - automated quality and release gates

---

## Azure Authentication and Service Connections

- [Service connections](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints) - service connection overview
- [Connect to Azure](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure) - Azure Resource Manager service connections
- [Workload Identity Federation for Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure#create-an-azure-resource-manager-service-connection-using-workload-identity-federation) - passwordless authentication setup
- [Variable groups](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups) - shared variables across pipelines
- [Link Key Vault to variable groups](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups#link-secrets-from-an-azure-key-vault) - secret integration pattern

---

## Azure Deployment Tasks

- [Azure Web App task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-web-app-v1) - App Service deployment
- [Azure Resource Manager template deployment task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-resource-manager-template-deployment-v3) - ARM/Bicep deployment support
- [Azure CLI task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-cli-v2) - Azure CLI execution in pipelines
- [Docker task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/docker-v2) - image build and push

---

## Infrastructure as Code

- [Deploy Bicep with Azure Pipelines](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-azure-pipelines) - Bicep delivery in Azure DevOps
- [Terraform task v4](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/terraform-task-v4) - Terraform integration
- [Build Docker images in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/ecosystems/containers/build-image) - container build guidance

---

## Quality, Reporting, and Troubleshooting

- [Publish test results](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/publish-test-results-v2) - test report publishing
- [Code coverage results](https://learn.microsoft.com/en-us/azure/devops/pipelines/test/review-code-coverage-results) - coverage reporting
- [Pipeline report](https://learn.microsoft.com/en-us/azure/devops/pipelines/reports/pipelinereport) - pipeline analytics
- [Troubleshoot pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/troubleshooting/troubleshooting) - common failure modes and remediation

Use these references to validate Azure DevOps task semantics, environment behavior, and security posture while adapting the bundled templates.
