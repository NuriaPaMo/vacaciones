# CI/CD Pipeline Azure - Routing Examples

These examples are intentionally lightweight. They help the orchestration layer translate Article XI into a provider decision and then hand off to the correct skill. Full provider templates belong in the provider-specific skills.

---

## Example 1: Constitution Clearly Selects GitHub Actions

### Constitution signal

```text
Article XI
- CI/CD Platform: GitHub Actions
- Deployment Strategy: Blue-Green
- Branch Strategy: GitHub Flow
```

### Orchestrator outcome

```text
Route to /.boltf/available-skills/github/github-actions-templates/SKILL.md

Carry forward these constraints:
- production protection rules in GitHub Environments
- staging slot swap or equivalent blue-green workflow
- branch triggers aligned to GitHub Flow
- IaC validation stages mandated by Article XI
```

### Why

The constitution already made the provider choice. The orchestrator should not reopen it; it should translate that choice into the GitHub-specific implementation path.

---

## Example 2: Constitution Clearly Selects Azure DevOps Pipelines

### Constitution signal

```text
Article XI
- CI/CD Platform: Azure DevOps Pipelines
- Deployment Strategy: Canary
- Deployment stages: dev → uat → pre → prod
```

### Orchestrator outcome

```text
Route to /.boltf/available-skills/azdo/skill-azdo-pipeline-templates/SKILL.md

Carry forward these constraints:
- multi-stage YAML with explicit stage dependencies
- Azure DevOps environments and approvals
- canary-capable deployment design for the selected Azure hosting target
- application and infrastructure stages required by Article XI
```

### Why

Azure DevOps-specific constructs such as environments, approvals, deployment jobs, and service connections belong in the provider skill, not here.

---

## Example 3: Constitution Missing the Provider

### Available signals

- repository hosted in GitHub
- work management uses Azure Boards
- Article XI stages are defined, but platform checkbox is still unresolved

### Orchestrator outcome

```text
Do not silently hard-code the provider.

1. State that Article XI does not yet resolve the platform.
2. Offer a provisional recommendation:
   - GitHub Actions if repository-native automation is preferred
   - Azure DevOps Pipelines if Azure Boards / approvals / service connections are primary drivers
3. Ask for clarification or propose a constitution amendment.
```

### Why

The orchestration layer should reduce ambiguity, not hide it.

---

## Example 4: Mapping Article XI to Pipeline Shape

| Article XI Decision             | Orchestrator Interpretation                   | Delegated Provider Concern                     |
| ------------------------------- | --------------------------------------------- | ---------------------------------------------- |
| Build enabled                   | pipeline needs a build stage                  | exact tasks/jobs                               |
| Unit tests + coverage threshold | test stage must enforce threshold             | test commands and report publishing            |
| IaC validation enabled          | infra validation stage required before deploy | Bicep/Terraform provider syntax                |
| Deploy Prod = manual approval   | production release must be gated              | GitHub environment reviewers or AzDO approvals |
| Blue-Green                      | zero-downtime rollout required                | slots, revisions, or deployment job strategy   |

Use this table as a mental model: the orchestrator decides **what must exist**; the provider skill decides **how it is expressed**.

---

## Example 5: Escalation Pattern

```text
Orchestrator identifies:
- mutation tests are constitutionally required
- post-deploy telemetry validation is required

Delegation chain:
1. Route to provider skill for pipeline structure
2. Ask Bolt Testing to shape the testing gates
3. Ask Bolt Monitoring to shape release verification and observability checks
4. Reconcile the full design back against Article XI
```

This keeps CI/CD design coherent across adjacent quality and observability concerns.
