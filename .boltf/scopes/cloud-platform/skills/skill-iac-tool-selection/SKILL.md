---
name: skill-iac-tool-selection
description: Choose Infrastructure as Code tool (Bicep, Terraform, Pulumi, ARM Templates) for Azure deployments based on team skills, multi-cloud strategy, and operational needs. Use when starting new projects, evaluating Bicep vs Terraform tradeoffs, implementing infrastructure modules, or migrating from ARM templates. Critical architectural decision affecting all infrastructure automation.
---

# IaC Tool Selection

## When to Use This Skill

This skill helps you navigate infrastructure-as-code tool decisions because the choice between Bicep, Terraform, ARM Templates, Pulumi, and other IaC tools fundamentally impacts development velocity, operational complexity, cloud strategy flexibility, and long-term maintainability of your infrastructure.

Consider this skill when:

1. **Starting a new Azure project requiring infrastructure automation** - You need to understand which IaC tool aligns with your team's expertise (HCL vs. TypeScript vs. declarative DSLs), your cloud commitment (Azure-only vs. multi-cloud), and your operational maturity (managed vs. self-managed state), because the wrong choice can create technical debt, slow iteration cycles, and complicate future migrations.

2. **Evaluating Bicep versus Terraform for Azure deployments** - These are the two primary choices for Azure IaC, with Bicep offering deeper Azure integration and simpler syntax while Terraform provides multi-cloud portability and a mature ecosystem, and the decision affects team productivity, infrastructure complexity, and strategic flexibility over years.

3. **Migrating from legacy ARM Templates to modern IaC** - ARM Templates remain functional but lack modern features like strong typing, modularity, and developer experience improvements found in Bicep (native successor) or Terraform (industry standard), and migration timing depends on technical debt tolerance, team capacity, and new feature requirements.

4. **Implementing infrastructure modules for reusability** - Different IaC tools offer different module systems (Bicep modules, Terraform modules, Pulumi components), and choosing the right approach affects how your team shares infrastructure patterns, enforces governance, and scales infrastructure development across multiple projects.

5. **Establishing multi-cloud infrastructure strategy** - If your architecture spans AWS, Azure, and GCP, or you anticipate cloud migration scenarios, tool selection between cloud-agnostic Terraform/Pulumi versus cloud-native Bicep/CloudFormation becomes a critical architectural decision with long-term vendor lock-in implications.

6. **Evaluating imperative versus declarative infrastructure approaches** - Pulumi and AWS CDK offer imperative programming with real languages (TypeScript, Python, C#) providing familiar abstractions and testing patterns, while Bicep and Terraform use declarative DSLs optimized for infrastructure state management, and the choice depends on team skills and infrastructure complexity.

7. **Selecting IaC tools for complex enterprise landing zones** - Enterprise-scale Azure deployments require sophisticated governance, multi-subscription management, and policy enforcement, and different IaC tools provide varying levels of support for Azure's Cloud Adoption Framework patterns, resource hierarchies, and management group structures.

---

## Decision Framework

### IaC Tool Selection Tree

```text
┌────────────────────────────────────────────┐
│ What is your cloud strategy?              │
└───────────┬────────────────────────────────┘
            │
      ┌─────┴──────┬──────────────────┐
      │            │                  │
  Azure-only   Multi-cloud      Hybrid
      │            │            (Azure + on-prem)
      │            │                  │
      ▼            ▼                  ▼
┌──────────┐  ┌──────────┐     ┌──────────────┐
│ Team     │  │Terraform │     │    Bicep     │
│ skills?  │  │ (primary │     │      +       │
└──┬───┬───┘  │ choice)  │     │  Terraform   │
   │   │      └──────────┘     └──────────────┘
 JSON HCL/                            │
  DSL  Code                           │
   │   │                              │
   ▼   ▼                              ▼
Bicep Programming         ┌────────────────────┐
       Language?          │ Evaluate hybrid    │
           │              │ approach based on  │
      ┌────┴────┐         │ service maturity   │
      │         │         └────────────────────┘
  Familiar  Prefer
   with     Strong
   IaC DSL  Typing
      │         │
      ▼         ▼
  Terraform  Pulumi
             (TypeScript,
              Python, C#)
```

### Language/Approach Selection

```text
┌────────────────────────────────────────┐
│ Team's primary development language?   │
└───────────┬────────────────────────────┘
            │
    ┌───────┴───────┬──────────┬──────────┐
    │               │          │          │
Python/.NET    JavaScript/    None       Go
TypeScript     TypeScript   (Ops team)    │
    │               │          │          │
    ▼               ▼          ▼          ▼
Pulumi          Pulumi      Terraform   Terraform
(Python)        (TS)        or Bicep    (HCL native)
   │               │            │           │
   └───────────────┴────────────┴───────────┘
                    │
              ┌─────▼─────┐
              │ Need      │
              │ multi-    │
              │ cloud?    │
              └──┬────┬───┘
                 │    │
                YES  NO
                 │    │
                 ▼    ▼
            Terraform Bicep
            Pulumi    (if Azure-
                      native pref)
```

---

## Scoring Model: IaC Tool Comparison

Use this as a **conversation starter** to explore trade-offs, not as a rigid calculation. Scores reflect typical Azure-centric scenarios—your context may shift priorities.

| Tool              | Azure Native | Multi-Cloud | Language Familiarity  | Ecosystem/Maturity  | Learning Curve | State Management     | IDE Support |
| ----------------- | ------------ | ----------- | --------------------- | ------------------- | -------------- | -------------------- | ----------- |
| **Bicep**         | ⭐⭐⭐⭐⭐   | ⭐          | ⭐⭐⭐ (DSL)          | ⭐⭐⭐⭐            | ⭐⭐⭐⭐⭐     | ⭐⭐⭐⭐⭐ (managed) | ⭐⭐⭐⭐⭐  |
| **Terraform**     | ⭐⭐⭐⭐     | ⭐⭐⭐⭐⭐  | ⭐⭐⭐ (HCL)          | ⭐⭐⭐⭐⭐          | ⭐⭐⭐         | ⭐⭐⭐ (self-mgd)    | ⭐⭐⭐⭐    |
| **ARM Templates** | ⭐⭐⭐⭐⭐   | ⭐          | ⭐⭐ (JSON)           | ⭐⭐⭐⭐⭐ (legacy) | ⭐⭐           | ⭐⭐⭐⭐⭐ (managed) | ⭐⭐⭐      |
| **Pulumi**        | ⭐⭐⭐⭐     | ⭐⭐⭐⭐⭐  | ⭐⭐⭐⭐⭐ (TS/Py/C#) | ⭐⭐⭐⭐            | ⭐⭐⭐⭐       | ⭐⭐⭐ (self-mgd)    | ⭐⭐⭐⭐⭐  |
| **AWS CDK**       | ⭐⭐         | ⭐⭐⭐      | ⭐⭐⭐⭐⭐ (TS/Py/C#) | ⭐⭐⭐⭐            | ⭐⭐⭐         | ⭐⭐⭐ (CFN-based)   | ⭐⭐⭐⭐    |

**Key Trade-offs:**

- **Azure Native**: Bicep and ARM Templates are first-party Microsoft tools with same-day support for new Azure features
- **Multi-Cloud**: Terraform and Pulumi support AWS, GCP, Azure, and hundreds of providers; Bicep is Azure-only
- **Language Familiarity**: Pulumi uses real programming languages developers already know; Bicep/Terraform use domain-specific languages
- **Ecosystem/Maturity**: Terraform has largest community, module registry, and tooling ecosystem; Bicep is newer but rapidly maturing
- **Learning Curve**: Bicep's syntax is simplest; Terraform requires HCL fluency; Pulumi requires programming language expertise
- **State Management**: Bicep has no state files (ARM tracks state); Terraform/Pulumi require explicit state backend configuration
- **IDE Support**: All tools have VS Code extensions; Bicep and Pulumi offer strongest IntelliSense and type-checking

---

## IaC Tool Patterns

### Bicep (Azure-Native Declarative Language)

**Primary Use Case**: Azure-only projects prioritizing simplicity, Azure-native integration, and teams familiar with Infrastructure as Code concepts but wanting cleaner syntax than ARM Templates.

**Key Characteristics:**

- Azure Resource Manager's native successor to JSON ARM Templates
- Decompile ARM → Bicep for modernization (az bicep decompile)
- No state files (Azure Resource Manager tracks deployment state)
- Strong typing with IntelliSense for all Azure resources
- Modular design with Bicep modules stored in Azure Container Registry
- Same-day support for new Azure features (day-zero support)
- Integrated with Azure CLI and PowerShell

**When Bicep Makes Sense:**

- Your infrastructure is 100% Azure (no AWS, GCP, or on-premises)
- Your team prefers declarative syntax over imperative code
- You want minimal operational overhead (no state file management)
- You need immediate access to new Azure features on release day
- Your organization standardizes on Microsoft tooling
- You're migrating from ARM Templates and want natural evolution
- Developer experience is prioritized (excellent VS Code extension)

**Technical Considerations:**

- Bicep compiles to ARM Templates (ARM is the deployment layer)
- Module registry requires Azure Container Registry for private modules
- Multi-region deployments require separate deployment orchestration
- Limited support for drift detection (Azure Resource Graph queries needed)
- Cannot deploy non-Azure resources (e.g., GitHub, Datadog)
- Template specs enable enterprise distribution of reusable infrastructure patterns
- Bicep CLI integrates with CI/CD pipelines (GitHub Actions, Azure Pipelines)

### Terraform (Multi-Cloud Declarative Language)

**Primary Use Case**: Multi-cloud or cloud-agnostic infrastructure requiring mature ecosystem, extensive provider support, and teams familiar with HashiCorp tooling or HCL syntax.

**Key Characteristics:**

- Industry-standard multi-cloud IaC with 3000+ providers (AWS, Azure, GCP, Kubernetes, GitHub, Datadog, etc.)
- Mature module registry (Terraform Registry) with community contributions
- State management with remote backends (Azure Storage, Terraform Cloud, S3)
- Plan/apply workflow with detailed change previews
- Extensive ecosystem (Sentinel for policy, Terraform Cloud for collaboration)
- Strong community with proven patterns and extensive documentation

**When Terraform Makes Sense:**

- You need multi-cloud infrastructure (Azure + AWS, Azure + GCP)
- Your architecture includes non-Azure resources (GitHub repos, Datadog monitors, Kubernetes manifests)
- You anticipate future cloud migration or hybrid scenarios
- Your team has HCL expertise or values declarative infrastructure
- You need advanced features like workspaces, remote state locking, Sentinel policies
- You want to leverage community modules from Terraform Registry
- Your organization already uses HashiCorp products (Vault, Consul)

**Technical Considerations:**

- State file management is critical (remote backends, state locking)
- Azure provider (azurerm) sometimes lags 1-2 weeks behind new Azure features
- HCL learning curve for teams unfamiliar with HashiCorp ecosystem
- Plan output provides excellent visibility into infrastructure changes
- Import command allows migrating existing resources to Terraform management
- Workspaces enable multi-environment management (dev, staging, prod)
- Terraform Cloud/Enterprise adds collaboration, RBAC, private registry

### ARM Templates (Legacy JSON Format)

**Primary Use Case**: Existing Azure deployments using ARM Templates; new projects should prefer Bicep as ARM's successor.

**Key Characteristics:**

- Original Azure IaC format (JSON-based)
- Verbose syntax compared to Bicep (Bicep compiles to ARM)
- Azure Resource Manager's native deployment format
- Full feature parity with Bicep (same underlying engine)
- Template specs for distribution of reusable templates

**When ARM Templates Make Sense:**

- You have extensive existing ARM Template investments
- Your tooling generates ARM Templates programmatically
- You're maintaining legacy infrastructure without modernization budget
- Your deployment pipelines are tightly coupled to ARM JSON format
- You need compatibility with older Azure CLI/PowerShell versions

**Technical Considerations:**

- Bicep is the recommended migration path (decompile command available)
- JSON syntax is verbose and error-prone compared to Bicep
- Limited IntelliSense and IDE support compared to modern alternatives
- Linked templates require external storage (Storage Account or Template Specs)
- Same deployment engine as Bicep (no performance differences)
- No new feature development (Microsoft investing in Bicep instead)

### Pulumi (Imperative Multi-Cloud Framework)

**Primary Use Case**: Infrastructure requiring programming language abstractions, complex logic, or teams with strong software engineering backgrounds preferring imperative code over declarative DSLs.

**Key Characteristics:**

- Real programming languages (TypeScript, Python, C#, Go, Java)
- Object-oriented abstractions with classes, interfaces, inheritance
- Standard testing frameworks (Jest, PyTest, xUnit)
- Component model for reusable infrastructure patterns
- Pulumi Service (SaaS) or self-hosted backends for state management
- Native Azure provider with support for ARM-based resources

**When Pulumi Makes Sense:**

- Your team consists of software engineers preferring code over DSLs
- You need complex infrastructure logic (loops, conditionals, functions)
- You want to unit test infrastructure with familiar testing frameworks
- You require shared libraries and packages (npm, PyPI, NuGet)
- Your organization values programming language over configuration language
- You need multi-cloud with imperative control flow
- You want to apply software engineering practices to infrastructure

**Technical Considerations:**

- State management similar to Terraform (remote backends required)
- Pulumi Service offers SaaS backend with secrets management
- Learning curve includes programming language + Pulumi SDK concepts
- Azure Native provider provides comprehensive Azure coverage
- Strongly typed infrastructure with compile-time validation (TypeScript, C#)
- Integration with existing software projects (shared code, libraries)
- Requires programming language runtime (Node.js, Python, .NET)

### AWS CDK (Cloud Development Kit)

**Primary Use Case**: AWS-centric deployments with Azure as secondary cloud; not recommended for Azure-first architectures.

**Key Characteristics:**

- AWS's imperative IaC using TypeScript, Python, Java, C#, Go
- Compiles to CloudFormation (AWS equivalent of ARM Templates)
- Limited Azure support (requires CloudFormation-style adapters)
- Strong AWS ecosystem integration

**When AWS CDK Makes Sense (for Azure):**

- Your primary cloud is AWS with Azure as secondary
- Your team is deeply invested in AWS CDK patterns
- You're using CDK for Terraform (CDKTF) with Azure provider
- Multi-cloud abstraction via CDK constructs

**Technical Considerations:**

- Azure support via CDKTF (CDK for Terraform) rather than native
- Not a recommended choice for Azure-first architectures
- Consider Pulumi instead for multi-cloud imperative infrastructure
- CloudFormation model doesn't align well with Azure Resource Manager

---

## Module & Reusability Patterns

### Bicep Modules

Bicep modules enable encapsulation of infrastructure patterns and sharing across projects.

**Pattern Characteristics:**

- Modules are .bicep files consumed via `module` keyword
- Module registry (Azure Container Registry) for private distribution
- Parameters and outputs define module interface
- Public registry coming for community modules

**When to Use Bicep Modules:**

- Standardizing App Service + SQL Database patterns across teams
- Encapsulating networking configurations (VNets, subnets, NSGs)
- Distributing organization-specific infrastructure patterns
- Enforcing governance through approved modules

### Terraform Modules

Terraform modules are the core reusability pattern with public registry and versioning.

**Pattern Characteristics:**

- Modules are directories with .tf files
- Terraform Registry hosts public modules (versioned)
- Input variables and outputs define contracts
- Module composition enables complex infrastructure

**When to Use Terraform Modules:**

- Building multi-tier architectures (network, data, compute layers)
- Sharing modules across teams via private registry
- Leveraging community modules for common patterns
- Implementing DRY principles for infrastructure

---

## State Management Patterns

### Terraform State Backend (Azure Storage)

Terraform requires explicit state backend configuration for team collaboration.

**Pattern Characteristics:**

- State stored in Azure Storage Account blob container
- State locking via blob leases prevents concurrent modifications
- Shared state enables team collaboration
- Sensitive data encrypted at rest

**Critical Considerations:**

- State contains sensitive information (connection strings, passwords)
- Backend configuration cannot use variables (chicken-and-egg problem)
- Workspace concept enables environment isolation (dev, prod)
- State corruption risks require backup strategies

### Bicep State Management (Implicit)

Bicep has no state files; Azure Resource Manager tracks deployment state internally.

**Pattern Characteristics:**

- ARM deployment history stores parameters and templates
- No state file to secure, back up, or lock
- Deployment history retained for 800 deployments per resource group
- Drift detection via Azure Resource Graph queries

**Operational Advantages:**

- Zero operational overhead for state management
- No risk of state file corruption or loss
- No backend configuration required
- Automatic state consistency (ARM-managed)

---

## Common Pitfalls

### Terraform State File Exposure

**Problem**: State files stored locally or in unsecured locations expose sensitive infrastructure details and secrets.

**Solution**: Always use remote backends with encryption (Azure Storage with encryption at rest) and restrict access via RBAC. Consider Terraform Cloud for managed state with encryption and audit logs.

### Bicep Lack of Drift Detection

**Problem**: Bicep doesn't provide built-in drift detection for manual Azure Portal changes.

**Solution**: Use Azure Resource Graph queries, Azure Policy for governance, or third-party tools. Consider implementing scheduled `az deployment group what-if` checks.

### Terraform azurerm Provider Lag

**Problem**: New Azure features unavailable in Terraform for 1-2 weeks post-release.

**Solution**: Use Bicep for cutting-edge features, Terraform for stable infrastructure. Hybrid approach (Bicep for Azure-specific, Terraform for multi-cloud) viable.

### Over-Engineering with Pulumi

**Problem**: Treating infrastructure like application code leads to over-abstraction and complexity.

**Solution**: Balance DRY principles with infrastructure readability. Infrastructure should be boring and explicit, not clever and abstract.

### ARM Template Migration Paralysis

**Problem**: Delaying modernization due to large ARM Template investment.

**Solution**: Incremental migration via `az bicep decompile`. Decompile one template at a time, test, migrate. No need for big-bang migration.

---

## Quick Reference

| Scenario                          | Recommended Tool  | Alternative        | Notes                                        |
| --------------------------------- | ----------------- | ------------------ | -------------------------------------------- |
| Azure-only greenfield project     | Bicep             | Terraform          | Bicep for simplicity, Terraform for features |
| Multi-cloud infrastructure        | Terraform         | Pulumi             | Terraform maturity, Pulumi for code-first    |
| AWS + Azure multi-cloud           | Terraform         | Pulumi, CDKTF      | Terraform ecosystem strongest for both       |
| Complex logic (loops, conditions) | Pulumi            | Terraform for_each | Pulumi for programming constructs            |
| Existing ARM Template estate      | Bicep (decompile) | Continue ARM       | Bicep is natural evolution                   |
| Team with Python/TS/C# expertise  | Pulumi            | Terraform, Bicep   | Leverage existing language skills            |
| Enterprise landing zones (Azure)  | Bicep, Terraform  | Pulumi             | CAF patterns available for both              |
| Rapid Azure prototyping           | Bicep             | Terraform          | Bicep faster for Azure-only                  |
| Infrastructure shared as library  | Terraform modules | Pulumi packages    | Terraform Registry most mature               |
| Zero operational overhead         | Bicep             | Terraform Cloud    | Bicep no state, TF Cloud managed state       |

---

## Bundled Resources

This skill includes bundled resources that are loaded progressively:

- **references/code-examples.md**: Complete infrastructure examples including Bicep (App Service + SQL), Terraform (Container Apps + Cosmos DB), ARM Templates (Azure Functions + Storage), Pulumi (AKS + Redis), module patterns, state management configuration, and CI/CD integration workflows
- **references/microsoft-learn.md**: Curated documentation covering Bicep, Terraform on Azure, ARM Templates, Pulumi, Azure Resource Manager fundamentals, IaC best practices, testing strategies, CI/CD automation, migration guides, and community resources
