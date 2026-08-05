# Azure DevOps Pipeline Templates - Code Examples

These examples explain how to select and adapt the Azure DevOps templates bundled with this skill. Use them together with the files in `templates/`.

---

## Example 1: Application CI/CD Pipeline

### Use when

- Article XI selects Azure DevOps Pipelines
- application stages such as build, lint, tests, and deploy are required
- one artifact should be promoted through environments

### Start from

- `templates/azure-pipelines-app-ci.yml`

### Adapt these elements

- branch triggers to match the constitution's branch strategy
- test commands and coverage publication to match quality gates
- environment names and approval expectations
- deployment job target (App Service, Container Apps, etc.)

### Design note

This pattern works best when application delivery is the primary concern and infrastructure is either stable or handled separately.

---

## Example 2: Blue-Green App Service Deployment

### Use when

- Article XI requires **blue-green** strategy
- hosting target is Azure App Service
- pre-production validation must happen before traffic swap

### Start from

- `templates/azure-pipelines-appservice-bluegreen.yml`

### Adapt these elements

- App Service name and resource group
- staging slot smoke tests
- production approval boundary
- rollback or swap-back verification behavior

### Design note

Use deployment jobs and environments so the release history and approval model stay explicit instead of being hidden in shell logic.

---

## Example 3: Infrastructure Pipeline with Bicep

### Use when

- Article XI enables IaC lint and IaC validation
- infrastructure needs a separate approval path or audit trail
- Azure-native IaC is implemented with Bicep

### Start from

- `templates/azure-pipelines-infra-bicep.yml`

### Adapt these elements

- service connection name
- resource group and location variables
- Bicep entry point and parameter files
- post-validation / pre-deploy approval requirements

### Design note

Publishing validation outputs or what-if artifacts is often worth it in Azure DevOps because it improves reviewability before apply.

---

## Example 4: Mapping Article XI to Azure DevOps Concepts

| Article XI Requirement           | Azure DevOps Concept                                        |
| -------------------------------- | ----------------------------------------------------------- |
| Manual production approval       | Environment approval                                        |
| Rolling deployment               | Deployment job strategy                                     |
| IaC validation                   | Dedicated validation stage with Azure CLI or ARM/Bicep task |
| Security scan                    | Separate quality gate stage or task group                   |
| Promotion dev → uat → pre → prod | Multi-stage pipeline with `dependsOn`                       |

Use this table when translating constitution language into Azure DevOps YAML structure.

---

## Example 5: When to Split App and Infra Pipelines

Prefer **separate pipelines** when:

- infrastructure changes are infrequent but risky
- different teams approve infrastructure and app changes
- Terraform state or Bicep deployment review has its own governance

Prefer a **combined pipeline** when:

- the service is small and app + infra must move together
- environment provisioning and app rollout are tightly coupled
- the team needs one release history instead of two parallel ones

The right answer is not always technical purity; it is usually governance plus operability.
