---
name: skill-cicd-pipeline-azure
description: 'Orchestrate CI/CD decisions for Azure-oriented projects by reading the constitution first and routing work to GitHub Actions or Azure DevOps pipeline skills. Use when designing CI/CD, selecting the pipeline provider, choosing deployment strategy, defining quality gates, or coordinating infrastructure and application delivery. Critical because CI/CD decisions affect every scope and should come from Article XI instead of ad-hoc preferences.'
---

# CI/CD Pipeline Azure Orchestrator

> **Constitution Articles**: Article XI §11.1-11.4 (CI/CD Platform, Pipeline Stages, Deployment Strategy, Branch Strategy)
> **Bundled Resources**: [Routing Examples](references/code-examples.md) • [Microsoft Learn](references/microsoft-learn.md)

## Why This Skill Exists

This skill is the **transversal entry point** for CI/CD decisions in Bolt Framework projects. It should not behave like a giant warehouse of YAML snippets. Its job is to read the constitution, understand which delivery constraints the project has already ratified, and then route the work to the provider-specific skill that can produce the concrete pipeline assets.

That separation matters because CI/CD choices are cross-cutting: they affect application delivery, infrastructure validation, security checks, branch policies, approvals, rollback strategy, and operational stability. If those choices live in scattered prompts or in the agent body, they drift. If they come from Article XI, they stay governed.

## When to Use This Skill

Use this skill when you need to:

- **Design or update CI/CD architecture** for a Bolt project and the first question is still “what should the pipeline look like here?”
- **Translate Article XI into an executable pipeline shape** including stages, deployment promotions, and approval flow
- **Decide between GitHub Actions and Azure DevOps Pipelines** based on constitution, repository context, and work-management setup
- **Choose deployment strategy** such as rolling, blue-green, canary, or feature-flag-driven rollout
- **Coordinate application and infrastructure delivery** so build, test, IaC validation, and deployment happen coherently
- **Route implementation to the correct provider skill** instead of duplicating provider-specific details in the orchestration layer

## Constitution-First Checks

Before proposing any pipeline design, read the following in order:

1. `/.boltf/memory/constitution.md`
2. If present, the structured decisions described by `/.boltf/available-skills/bolt-framework/skill-bolt-setup-constitution/SKILL.md`, especially `decisions.cicd.platform`

Extract at least these signals from Article XI:

- **Platform**: `GitHub Actions` or `Azure DevOps Pipelines`
- **Application stages**: build, lint/format, unit tests, integration tests, architecture tests, mutation tests, security scan, container build, container scan
- **Infrastructure stages**: IaC lint, validation, security scan, cost estimation, compliance check
- **Deployment stages**: dev, uat, pre, prod and their triggers
- **Deployment strategy**: rolling, blue-green, canary, feature flags
- **Branch strategy**: GitFlow, GitHub Flow, or trunk-based

If a structured decisions file is missing, use the constitution text as the source of truth. If the constitution itself does not resolve the platform, ask for clarification or infer a provisional recommendation from repository hosting and surrounding governance, but make that inference explicit.

## Provider Routing

Once the constitution is understood, route work like this:

### Route to GitHub Actions

Use `/.boltf/available-skills/github/github-actions-templates/SKILL.md` when:

- Article XI selects **GitHub Actions**
- the repository is GitHub-native and no constitutional exception overrides that choice
- the user needs reusable workflows, job matrices, environment protections, or OIDC-based Azure deployment from GitHub

### Route to Azure DevOps Pipelines

Use `/.boltf/available-skills/azdo/skill-azdo-pipeline-templates/SKILL.md` when:

- Article XI selects **Azure DevOps Pipelines**
- the project depends on Azure DevOps environments, approvals, service connections, or multi-stage deployment jobs
- the user needs Azure Pipelines YAML, stage conditions, gated promotions, or infrastructure pipelines implemented with Azure DevOps tasks

### What This Skill Should Not Do

- Do **not** inline full production-ready provider templates unless a tiny skeleton is enough to explain the routing choice.
- Do **not** override constitution decisions because one provider looks more convenient.
- Do **not** duplicate provider-specific implementation guidance that belongs in the GitHub or Azure DevOps skill.

## Delivery Design Guidance

After routing, keep the design conversation anchored to the constitution:

- **Stage set** should match the mandated quality gates and environment promotions.
- **Deployment strategy** should match the hosting target: App Service slots for blue-green, Container Apps revisions for canary, AKS for rolling, feature flags when dark launches are required.
- **Authentication** should prefer passwordless federation (OIDC / workload identity) over long-lived secrets.
- **Infrastructure delivery** should align with the chosen IaC tool and include validation before apply.
- **Rollback and verification** should be part of the pipeline shape, not an afterthought.

## How to Proceed

1. **Read Article XI first** and list the decisions that actually constrain the pipeline.
2. **Summarize those decisions back to the user** so the CI/CD proposal is visibly traceable to the constitution.
3. **Choose the provider path** using the routing rules above.
4. **Load the provider skill** and let it supply the concrete templates, tasks, examples, and implementation guidance.
5. **Return to orchestration level** to verify that the concrete pipeline still matches the constitution across stages, approvals, environments, and deployment strategy.
6. **Escalate to adjacent specialists when needed**:
   - testing gates → `Bolt Testing`
   - deployment telemetry and release verification → `Bolt Monitoring`

## Delegation Map

```text
User request
  ↓
Bolt CI/CD agent
  ↓
skill-cicd-pipeline-azure (this skill)
  ↓
Read Article XI and related decisions
  ↓
Choose provider
  ├─ GitHub Actions → github-actions-templates
  └─ Azure DevOps Pipelines → skill-azdo-pipeline-templates
  ↓
Generate provider-specific pipeline assets
  ↓
Validate back against constitution
```

## Bundled Resources

- **[Routing Examples](references/code-examples.md)** - compact constitution-to-provider scenarios, stage mapping examples, and escalation patterns for the orchestration layer
- **[Microsoft Learn Resources](references/microsoft-learn.md)** - official documentation grouped by provider, deployment strategy, environments, and security posture

Use these resources to guide the orchestration decision. For concrete provider templates, switch to the delegated provider skill.
