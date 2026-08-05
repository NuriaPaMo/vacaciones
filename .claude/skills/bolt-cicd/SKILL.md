---
name: bolt-cicd
description: "DevOps integration, deployment automation and pipeline management for Bolt Framework projects. Constitution-first routing: extracts Article XI decisions, orchestrates via `skill-cicd-pipeline-azure`, then routes to GitHub Actions or Azure DevOps Pipelines provider skill. Triggers: 'CI/CD', 'pipeline', 'deployment automation', 'GitHub Actions', 'Azure DevOps Pipelines', 'release pipeline', 'pipeline design', '/bolt-cicd'."
---

# Bolt CI/CD — Methodology

DevOps specialist for Bolt Framework projects. Designs and coordinates
CI/CD pipelines, deployment strategies and infrastructure automation
**through constitution-first routing**.

## Operating model

Work in this order:

1. **Read the constitution first** and extract Article XI decisions.
2. **Use `skill-cicd-pipeline-azure` as the orchestration layer**.
3. **Route to the provider skill**:
   - GitHub Actions → `github-actions-templates`.
   - Azure DevOps Pipelines → `skill-azdo-pipeline-templates`.
4. **Validate the concrete pipeline back against the constitution**.
5. **Handoff when needed**:
   - testing gates → `bolt-testing`.
   - deployment observability / release verification → `bolt-monitoring`.

## Constitution-first rules

Never choose the CI/CD provider from personal preference if Article XI
already defines it.

Always extract at least:

- CI/CD platform.
- Application and infrastructure stages.
- Deployment environments and triggers.
- Deployment strategy.
- Branch strategy.

If the constitution does not resolve the provider, say so explicitly and
ask for clarification or make a clearly labelled provisional
recommendation.

## Provider scope

Aligned with providers supported by the Bolt constitution and CI/CD
orchestration skill:

- **GitHub Actions**.
- **Azure DevOps Pipelines**.

GitLab CI or Jenkins are constitutional exceptions / future extensions,
not the default path.

## Do / Don't

### ✅ Do

- Interpret CI/CD requirements through Article XI.
- Coordinate provider selection via the orchestration skill.
- Align pipeline design with deployment strategy, branch strategy, and
  quality gates.
- Connect CI/CD decisions to testing, monitoring, and infrastructure
  delivery.
- Keep the final recommendation coherent across all scopes.

### ❌ Don't

- Embed giant provider templates directly in this skill.
- Duplicate guidance that already belongs in the provider skills.
- Bypass the orchestration skill and jump straight to provider syntax
  without checking the constitution.

## Delivery checklist

Before finalizing a CI/CD design, confirm:

- Provider matches constitution.
- Application stages match Article XI.
- Infrastructure stages match Article XI.
- Promotion flow matches environment triggers and approvals.
- Rollout strategy matches the hosting target.
- Authentication avoids long-lived secrets where federation is available.
- Verification and rollback are part of the design.

## Typical coordination flow

```text
User asks for CI/CD help
  ↓
Read constitution / Article XI
  ↓
Load skill-cicd-pipeline-azure
  ↓
Route to provider skill
  ├─ GitHub Actions → github-actions-templates
  └─ Azure DevOps Pipelines → skill-azdo-pipeline-templates
  ↓
Produce pipeline design or assets
  ↓
Validate against constitution
  ↓
Handoff to bolt-testing / bolt-monitoring if needed
```

Use the provider skills for the actual templates and concrete
implementation examples.

- GitHub path → `.boltf/available-skills/github/github-actions-templates/SKILL.md`.
- Azure DevOps path → `.boltf/available-skills/azdo/skill-azdo-pipeline-templates/SKILL.md`.

Keep this skill focused on orchestration, governance, and cross-skill
coordination.

## Related agents (next steps)

- → `bolt-testing`: configure testing gates in the pipeline.
- → `bolt-monitoring`: setup deployment monitoring & alerting.
- → `bolt-infra`: provision underlying infrastructure (IaC pipelines).
- → `bolt-constitution`: amend Article XI if needed.
