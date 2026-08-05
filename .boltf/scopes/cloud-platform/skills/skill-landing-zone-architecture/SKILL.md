---
name: skill-landing-zone-architecture
description: Design Azure Landing Zones following Cloud Adoption Framework (CAF) with management groups, hub-spoke networking, and centralized governance. Use when implementing enterprise-scale Azure foundations, choosing between Landing Zone vs simple workload infrastructure, or deploying with ALZ-Bicep/Terraform. Critical for enterprise deployments - affects governance, networking, and subscription organization.
---

# Azure Landing Zone Architecture

---

## When to Use This Skill

Use this skill when you are:

1. **Designing the foundational Azure environment for an enterprise or organization** — because Azure Landing Zones provide pre-configured governance, networking, identity, and management structures following Cloud Adoption Framework best practices, and understanding when to adopt landing zone patterns vs. ad-hoc subscription design prevents future governance debt, security gaps, and operational complexity at scale.

2. **Evaluating whether to use Azure Landing Zone accelerators (Portal, ALZ-Bicep, Terraform) vs. custom Infrastructure as Code** — because accelerators provide opinionated architectures with 80% of common enterprise requirements pre-configured, while custom IaC offers flexibility for unique organizational needs, and choosing the right starting point affects implementation speed, maintainability, and alignment with CAF guidance.

3. **Architecting multi-subscription Azure environments with centralized governance and networking** — because landing zones define management group hierarchies (Platform, Landing Zones, Corp, Online), Azure Policy assignments for compliance enforcement, hub-spoke VNet topology for shared services, and RBAC patterns for least-privilege access, and understanding these foundational decisions guides scalable architecture that avoids subscription sprawl and inconsistent security posture.

4. **Implementing hub-spoke network topology with Azure Firewall for centralized connectivity** — because landing zones prescribe hub VNet containing Azure Firewall, VPN Gateway, and shared services, with spoke VNets for application workloads connected via peering and forced tunneling through firewall, and evaluating this pattern vs. virtual WAN or flat networking informs connectivity strategy for hybrid cloud and internet egress control.

5. **Establishing governance at scale with Azure Policy, tagging standards, and RBAC inheritance** — because landing zones use management group-scoped policies to enforce resource location restrictions, require tags for cost allocation, deny public IP creation in Corp environments, and automatically assign diagnostic settings, and understanding policy-driven governance prevents manual configuration drift and audit failures across hundreds of subscriptions.

6. **Planning subscription organization strategy (Platform vs. Landing Zones, Corp vs. Online segmentation)** — because landing zones separate Platform subscriptions (Identity, Management, Connectivity) from workload Landing Zone subscriptions (Corp for internal apps, Online for internet-facing apps), and this segmentation enables isolation between infrastructure teams and application teams, cost allocation by business unit, and different security controls per workload sensitivity.

7. **Migrating from unmanaged Azure environments to enterprise-ready landing zones** — because brownfield scenarios require assessing existing subscriptions, networking, policies, and RBAC against landing zone design principles, planning migration path (greenfield landing zone + migrate workloads, or retrofit existing subscriptions), and understanding refactoring effort vs. starting fresh ensures successful transition without disrupting production workloads.

---

## Decision Framework: Selecting Landing Zone Approach

Choosing the right Azure Landing Zone implementation depends on your organizational size, governance requirements, existing infrastructure, and team capabilities. Use this framework to guide your approach:

```text
┌─────────────────────────────────────────────────────────┐
│ Need enterprise-scale Azure foundation?                │
└─────────────────────────────────────────────────────────┘
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
       ▼                   ▼                   ▼
   Greenfield          Brownfield          Small-scale
   (no existing        (existing           (< 10 subs)
    infrastructure)     subscriptions)         │
       │                   │                   ▼
       │                   │               Start simple
       │                   │               • Hub-spoke
       ▼                   ▼               • Basic policies
   Use accelerator?    Assess gap          • Tag strategy
       │               with CAF
   ┌───┴───┐               │
   │       │               │
   ▼       ▼               ▼
Portal   ALZ-Bicep     Retrofit or
Accelerator  /Terraform    migrate?
   │       │           ┌───┴───┐
   │       │           │       │
   ▼       ▼           ▼       ▼
Fast     Modular    Retrofit  Migrate
setup    infra      existing  to new
• GUI    • Bicep    • Policy  • Greenfield
• Opinionated • Git-based • Networking • Clean start
```

**Key Questions to Guide Selection**:

- Do you have existing Azure subscriptions or starting fresh? (Greenfield vs. brownfield)
- Does your team prefer GUI-based deployment or Infrastructure as Code? (Portal vs. Bicep/Terraform)
- Do you need multi-cloud consistency or Azure-native tooling? (Terraform vs. ALZ-Bicep)
- Are you comfortable with opinionated architectures or need customization? (Accelerator vs. custom IaC)
- Does your organization require compliance frameworks (PCI-DSS, HIPAA, FedRAMP)? (Policy-driven governance essential)

---

## Scoring Model: Landing Zone Implementation Approaches

| Implementation Approach         | Speed  | Flexibility | CAF Alignment | Git-based IaC | Multi-cloud  | Custom Requirements |
| ------------------------------- | ------ | ----------- | ------------- | ------------- | ------------ | ------------------- |
| **Portal Accelerator**          | Fast   | Low         | Full          | No            | No           | Limited             |
| **ALZ-Bicep**                   | Medium | Medium      | Full          | Yes           | No (Azure)   | Moderate            |
| **CAF Terraform Landing Zones** | Medium | High        | Full          | Yes           | Yes          | High                |
| **Custom Bicep/Terraform**      | Slow   | Very High   | Partial       | Yes           | Configurable | Complete            |

**Note**: This comparison is a conversation starter, not a rigid calculation. Context matters—**Portal Accelerator** suits rapid greenfield deployments with standard requirements, **ALZ-Bicep** provides modular Bicep for Azure-native IaC, **CAF Terraform** enables multi-cloud consistency with Terraform expertise, and **Custom IaC** fits unique organizational constraints but requires CAF mapping effort.

---

## Azure Landing Zone Architecture Explained

### What it enables

**Enterprise-scale foundation** providing management group hierarchies, hub-spoke networking, policy-driven governance, centralized identity, and platform automation patterns following Cloud Adoption Framework, optimized for secure, compliant, and scalable Azure adoption.

### When it fits

- **Enterprise or large organization** deploying workloads across multiple subscriptions (10+ subscriptions)
- **Regulatory compliance requirements** (HIPAA, PCI-DSS, FedRAMP, ISO 27001) requiring policy enforcement
- **Hybrid connectivity** to on-premises via ExpressRoute or VPN with centralized firewall
- **Multi-team environment** where platform team manages infrastructure, application teams deploy workloads
- **Cost allocation needs** requiring subscription segmentation by business unit, cost center, or project

### Key characteristics

**Management Group Hierarchy**: Tree structure organizing subscriptions. Root → Platform (Identity, Management, Connectivity) + Landing Zones (Corp, Online). Policies and RBAC assigned at management group scope inherit to children.

**Hub-Spoke Networking**: Hub VNet contains Azure Firewall, VPN Gateway, Azure Bastion for shared connectivity. Spoke VNets host application workloads, peer to hub, route traffic through firewall via User-Defined Routes (UDRs).

**Policy-Driven Governance**: Azure Policy assignments at management group scope enforce compliance (allowed regions, required tags, deny public IPs in Corp, enforce diagnostic settings). Policy remediation corrects non-compliant resources automatically.

**Subscription Vending**: Automated subscription creation via API (Enterprise Agreement or Microsoft Customer Agreement) with baseline configuration (networking, policies, RBAC, tags) applied programmatically. Enables self-service for application teams.

**Centralized Logging**: Log Analytics workspace in Management subscription receives diagnostic logs from all subscriptions (Key Vault audit events, NSG flow logs, Azure Firewall logs) for security monitoring and compliance auditing.

**Identity Integration**: Microsoft Entra ID (formerly Azure AD) provides identity foundation. Managed identities for Azure resources eliminate credential management. Platform access RBAC separates infrastructure owners from application deployers.

### Operational considerations

Landing zones excel for enterprise-scale but add complexity for small deployments (<10 subscriptions). Management group structure, policy assignments, and hub networking require platform team to maintain. Best when governance benefits outweigh operational overhead. Not necessary for simple scenarios (single application, single subscription, no compliance requirements).

---

## Landing Zone Design Areas (CAF Pillars)

### 1. Management Group & Subscription Organization

**Purpose**: Hierarchical governance structure for policy and RBAC inheritance.

**Pattern**: Root Management Group → Platform (Identity, Management, Connectivity subscriptions) + Landing Zones (Corp, Online subscriptions for workloads).

**Why it matters**: Policies assigned to "Landing Zones" management group apply to all Corp and Online subscriptions automatically. Separates platform infrastructure from application workloads for cost tracking and RBAC delegation.

---

### 2. Network Topology & Connectivity

**Purpose**: Centralized connectivity with hub-spoke topology.

**Pattern**: Hub VNet (Azure Firewall, VPN Gateway, Bastion) + Spoke VNets (application workloads) connected via peering. User-Defined Routes force spoke traffic through firewall (0.0.0.0/0 → Firewall Private IP).

**Why it matters**: Centralizes egress filtering (block malicious domains), on-premises connectivity (single VPN Gateway shared across spokes), and security monitoring (all traffic logs in Azure Firewall). Alternative: Virtual WAN for global multi-region deployments.

---

### 3. Identity & Access Management

**Purpose**: Centralized identity with least-privilege access.

**Pattern**: Microsoft Entra ID tenant for user/group authentication. Managed identities for Azure resources (no hardcoded credentials). RBAC roles assigned at management group, subscription, or resource group scope with Azure AD groups.

**Why it matters**: Eliminates credential sprawl, enforces MFA, integrates with on-premises Active Directory via Entra Connect. Platform team has Contributor on Platform subscriptions, application teams have Contributor on their Landing Zone subscriptions only.

---

### 4. Governance & Compliance

**Purpose**: Policy-driven compliance at scale.

**Pattern**: Azure Policy assignments at management group scope. Examples: Require "CostCenter" tag, allow only specific Azure regions, deny public IPs in Corp, enforce HTTPS for storage accounts, deploy diagnostic settings automatically.

**Why it matters**: Prevents non-compliant resources at creation time (Policy with Deny effect), automatically remediates existing resources (DeployIfNotExists effect), generates compliance reports for audits. Essential for regulatory frameworks (HIPAA, PCI-DSS).

---

### 5. Management & Monitoring

**Purpose**: Centralized observability and operational insights.

**Pattern**: Log Analytics workspace in Management subscription. Diagnostic settings policy deploys logs automatically to workspace (Azure Firewall, NSG flow logs, Key Vault audit events). Azure Monitor alerts for security events.

**Why it matters**: Single pane of glass for security investigations, compliance audits, and operational troubleshooting across all subscriptions. Retains logs for SIEM ingestion (Microsoft Sentinel) or compliance requirements (90+ days).

---

### 6. Security, Governance, Compliance

**Purpose**: Defense-in-depth security controls.

**Pattern**: Azure Firewall for egress filtering, Network Security Groups (NSGs) for subnet-level micro-segmentation, DDoS Protection Standard for public-facing VNets, Microsoft Defender for Cloud for threat detection, Azure Bastion for secure VM access (no public IPs).

**Why it matters**: Prevents data exfiltration (firewall FQDN filtering), reduces attack surface (NSGs block lateral movement), detects compromised resources (Defender alerts), meets compliance requirements (no public IPs on VMs).

---

### 7. Platform Automation & DevOps

**Purpose**: Infrastructure as Code for repeatable deployments.

**Pattern**: Bicep or Terraform modules in Git repositories. CI/CD pipelines (Azure DevOps, GitHub Actions) deploy management groups, policies, networking via automated pipelines. Subscription vending automates landing zone creation.

**Why it matters**: Treats infrastructure as code (version control, peer review, rollback). Prevents manual Azure Portal changes causing configuration drift. Enables self-service subscription provisioning for application teams.

---

## Landing Zone Deployment Options

### Portal Accelerator

**What it is**: Web UI in Azure Portal guides through questionnaire, deploys landing zone via ARM templates.

**When to use**: Greenfield deployments, teams unfamiliar with IaC, rapid POC, standard requirements fit accelerator assumptions.

**Limitations**: No Git-based workflow, limited customization, updates require redeployment, not recommended for production CI/CD.

**Link**: [Deploy with Portal Accelerator](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fgithub.com%2FAzure%2FEnterprise-Scale%2Ftree%2Fmain%2FeslzArm)

---

### ALZ-Bicep (Azure Landing Zones Bicep)

**What it is**: Modular Bicep modules implementing CAF landing zone patterns. Modules for management groups, policies, hub networking, spoke networking, subscription vending.

**When to use**: Azure-native IaC, team prefers Bicep, Git-based deployments, gradual customization of modules, Azure-only (no multi-cloud).

**Advantages**: Native Bicep support, modular design (use only needed modules), aligned with CAF, active Microsoft support.

**Link**: [ALZ-Bicep on GitHub](https://github.com/Azure/ALZ-Bicep)

---

### CAF Terraform Landing Zones

**What it is**: Terraform modules implementing CAF landing zone patterns with HCL configuration.

**When to use**: Multi-cloud strategy (Azure + AWS/GCP), existing Terraform expertise, need Terraform state management, HashiCorp ecosystem integration.

**Advantages**: Multi-cloud consistency, mature Terraform ecosystem (providers, modules), state management with remote backends (Azure Storage, Terraform Cloud).

**Link**: [CAF Terraform on GitHub](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale)

---

### Custom Bicep / Terraform

**What it is**: Build landing zone IaC from scratch or heavily customize accelerator modules.

**When to use**: Unique organizational requirements not met by accelerators, existing custom IaC patterns, brownfield retrofit, learning opportunity.

**Trade-offs**: Full flexibility but slower time-to-value, requires CAF alignment effort, ongoing maintenance burden, risk of deviating from best practices.

---

## Quick Reference: Landing Zone Architecture Decisions

| Decision Area                | Recommended Pattern                     | When to Deviate                                  |
| ---------------------------- | --------------------------------------- | ------------------------------------------------ |
| Management group structure   | Platform + Landing Zones (Corp/Online)  | <10 subscriptions: simplified hierarchy          |
| Network topology             | Hub-spoke with Azure Firewall           | Global scale: Virtual WAN; simple: flat VNet     |
| Policy assignment scope      | Management group (inherited to subs)    | POC: subscription-level only                     |
| Centralized logging          | Log Analytics in Management sub         | Distributed teams: regional workspaces           |
| Subscription per workload    | Yes (isolation, cost allocation)        | Single app, low complexity: shared subscription  |
| Azure Firewall in hub        | Yes (egress filtering, on-prem routing) | No hybrid connectivity: Application Gateway only |
| Corp vs. Online segmentation | Yes (internal vs. internet-facing)      | All workloads internal: single Landing Zones MG  |

---

## Common Pitfalls

**Implementing landing zones for small environments (<10 subscriptions)**: Landing zone overhead (management groups, hub networking, policy management) outweighs benefits for simple deployments. Alternative: single subscription with hub VNet and basic policies. Reserve landing zones for multi-subscription enterprise-scale.

**Customizing accelerators extensively before understanding defaults**: Portal Accelerator and ALZ-Bicep provide 80% of enterprise needs. Start with defaults, validate in non-production, then customize incrementally. Premature customization breaks CAF alignment and complicates future updates.

**Mixing manual Azure Portal changes with Infrastructure as Code**: Manual policy assignments, RBAC grants, or networking changes outside IaC pipelines cause configuration drift. Enforce principle: all infrastructure changes via Git commits and CI/CD pipelines. Use Azure Policy to audit or deny manual changes.

**Ignoring brownfield assessment before retrofitting landing zones**: Existing subscriptions may have conflicting policies, incompatible networking (no route tables for forced tunneling), or RBAC not aligned with landing zone roles. Assess gap with CAF "Landing Zone Review" tool before retrofitting. Migration may be simpler than retrofit.

**Not planning for subscription vending from the start**: Manual subscription provisioning doesn't scale beyond 10-20 subscriptions. Design subscription vending automation early (Bicep/Terraform modules + CI/CD pipeline) for self-service. Automates network peering, policy assignments, RBAC, tagging.

**Forcing hub-spoke topology when Virtual WAN is better fit**: Hub-spoke suits single-region or regional hub-spoke with limited inter-region traffic. Virtual WAN fits global architectures with any-to-any connectivity, SD-WAN integration, and centralized routing across all regions. Evaluate before committing.

**Setting overly restrictive policies without exemption process**: Policies like "deny public IPs" or "allowed regions only" block legitimate scenarios (Azure Firewall public IP, Bastion public IP, testing in unsupported regions). Define policy exemption workflow (approval process, temporary exemptions, audit trail) before enforcing restrictive policies.

---

## Bundled Resources

This skill references:

- **[references/code-examples.md](references/code-examples.md)**: Bicep examples for management group hierarchies, hub-spoke VNet topology with peering, Azure Firewall deployment with application/network rules, Azure Policy assignments at management group scope, DDoS Protection plan, resource tagging strategies, subscription vending patterns, and centralized logging with diagnostic settings demonstrating enterprise-scale landing zone infrastructure.
- **[references/microsoft-learn.md](references/microsoft-learn.md)**: Curated documentation for Azure Landing Zones overview, Cloud Adoption Framework (CAF) methodology, management group organization, hub-spoke networking architecture, Azure Policy governance, identity and access management, centralized monitoring, security baseline, deployment accelerators (Portal, ALZ-Bicep, Terraform), migration strategies, reference architectures, and CAF best practices with official Microsoft Learn references and GitHub repositories.
