---
name: skill-azdo-pipeline-templates
description: Create Azure DevOps Pipelines templates for Azure-oriented application and infrastructure delivery. Use when Article XI selects Azure DevOps Pipelines, when you need multi-stage YAML, environments and approvals, service connections or workload identity, or when translating quality gates into `azure-pipelines.yml`. Critical because Azure DevOps-specific pipeline design should live in a dedicated provider skill instead of being embedded in the CI/CD orchestrator.
---

# Azure DevOps Pipeline Templates

> **Provider Scope**: Azure DevOps Pipelines
> **Expected Entry Point**: Usually delegated from `skill-cicd-pipeline-azure`
> **Bundled Resources**: [Code Examples](references/code-examples.md) • [Microsoft Learn](references/microsoft-learn.md) • [Templates](templates/)

## When to Use

Use this skill when the constitution or orchestration layer has already determined that **Azure DevOps Pipelines** is the selected CI/CD platform and you need to turn that decision into concrete pipeline assets.

Typical situations:

- **Create a new `azure-pipelines.yml`** for application delivery
- **Design a multi-stage promotion flow** across dev, uat, pre, and prod
- **Configure Azure DevOps environments and approvals** so release governance matches Article XI
- **Implement infrastructure delivery** with Bicep or Terraform in Azure Pipelines
- **Model quality gates** such as linting, tests, security scan, coverage, or smoke tests using Azure DevOps tasks and deployment jobs
- **Choose between service connections, workload identity federation, and task composition** for Azure-native delivery

## Pipeline Patterns

Azure DevOps Pipelines is strongest when you need explicit stage orchestration, environment-level approvals, deployment history, reusable templates, and enterprise governance that is deeply integrated with Azure.

Use these patterns depending on the constitution and hosting target:

- **Single application pipeline** for build → test → deploy flows with one artifact promoted through environments
- **Multi-stage promotion pipeline** when Article XI defines explicit environment progression and approvals
- **Application + infrastructure split** when application delivery and IaC delivery need different triggers or approval paths
- **Deployment jobs** when the release needs environment tracking, approvals, checks, or rolling strategy semantics
- **Template-based composition** when multiple repositories or services need a shared Azure Pipelines structure

## Authentication and Service Connections

Prefer the safest viable authentication model:

- **Workload Identity Federation** when available, because it removes long-lived secrets and aligns with least-privilege guidance
- **Azure Resource Manager service connections** for deployment tasks and Azure CLI tasks
- **Azure Key Vault-backed variable groups** when secrets must be consumed across stages or pipelines

Avoid designing pipelines that depend on static secrets unless a platform limitation forces it. If you must use secrets, make the trade-off explicit and keep the blast radius narrow.

## Approvals and Environments

Use Azure DevOps environments when Article XI requires gated promotion or clear deployment history.

Typical mapping:

- `development` → automatic deploy on integration branch
- `uat` / `staging` → deployment with smoke or integration validation
- `pre` → controlled release rehearsal with manual approval
- `production` → protected deployment with explicit approvals and post-deploy verification

Keep approvals and checks close to the environment boundary instead of scattering them through ad-hoc conditions.

## Infrastructure Pipeline Guidance

When Article XI enables infrastructure stages, design them as first-class citizens:

- **IaC lint** before validation
- **IaC validation / plan / what-if** before apply
- **Security scan** before promotion
- **Cost or compliance checks** when required by the constitution
- **Artifact or plan publication** when auditability matters

For implementation details, use the bundled templates and code examples rather than improvising task sequences each time.

## How to Proceed

1. **Confirm Azure DevOps is the selected provider**. If not, stop and go back to the orchestration skill.
2. **Extract constraints from Article XI**: stages, environments, rollout strategy, branch strategy, and gates.
3. **Choose a starting template** from `templates/`:
   - `azure-pipelines-app-ci.yml`
   - `azure-pipelines-appservice-bluegreen.yml`
   - `azure-pipelines-infra-bicep.yml`
4. **Adapt the template** so names, environments, tasks, and approval points match the constitution.
5. **Use `references/code-examples.md`** for rationale and pattern selection, not just syntax.
6. **Use `references/microsoft-learn.md`** when you need task semantics, YAML schema details, or Azure DevOps environment guidance.
7. **Return to the orchestration layer** to verify the final pipeline still matches the constitution.

## Bundled Resources

- **[Code Examples](references/code-examples.md)** - provider-specific patterns for application, deployment, and infrastructure pipelines in Azure DevOps
- **[Microsoft Learn Resources](references/microsoft-learn.md)** - official documentation for Azure Pipelines YAML, service connections, deployment jobs, and IaC integration
- **`templates/`** - starter YAML templates organized by delivery scenario so examples and reusable scaffolds do not get mixed into the main skill body

Keep this skill provider-specific. If the question becomes “should we be on Azure DevOps at all?”, go back to `skill-cicd-pipeline-azure`.
