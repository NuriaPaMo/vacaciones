# Azure Landing Zone Architecture - Microsoft Learn Resources

> **Curated Documentation**: Official Microsoft documentation for Azure Landing Zones, Cloud Adoption Framework, governance, networking, and enterprise-scale architectures.

---

## Azure Landing Zones Overview

### Getting Started

- [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure landing zone accelerator](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/implementation-options)
- [Choose an Azure landing zone option](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/choose-landing-zone-option)
- [Azure landing zone design areas](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas)

### Architecture & Design

- [Azure landing zone architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas#platform-landing-zones-vs-application-landing-zones)
- [Conceptual architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/architecture)
- [Platform vs. application landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas#platform-landing-zones-vs-application-landing-zones)

---

## Cloud Adoption Framework (CAF)

### Methodology

- [Microsoft Cloud Adoption Framework for Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Ready methodology](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/)
- [Azure best practices for enterprise readiness](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/)

### Planning & Strategy

- [Define your naming convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Resource naming and tagging decision guide](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Develop your naming and tagging strategy](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming-and-tagging-decision-guide)

---

## Management Groups & Subscriptions

### Management Group Hierarchy

- [Organize your resources with management groups](https://learn.microsoft.com/en-us/azure/governance/management-groups/overview)
- [Management group and subscription organization](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org)
- [Create management groups with Bicep](https://learn.microsoft.com/en-us/azure/governance/management-groups/create-management-group-bicep)

### Subscription Strategy

- [Azure subscription decision guide](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/initial-subscriptions)
- [Scale with multiple Azure subscriptions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/scale-subscriptions)
- [Subscription vending](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending)

---

## Networking

### Hub-Spoke Topology

- [Hub-spoke network topology in Azure](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Implement a secure hybrid network](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/dmz/secure-vnet-dmz)
- [Network topology and connectivity](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/network-topology-and-connectivity)

### Virtual Network Architecture

- [Define an Azure network topology](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/define-an-azure-network-topology)
- [Virtual network peering](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Plan for IP addressing](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/plan-for-ip-addressing)

### Azure Firewall

- [Azure Firewall overview](https://learn.microsoft.com/en-us/azure/firewall/overview)
- [Azure Firewall in hub-spoke topology](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/infrastructure/firewalls-multi-regions)
- [Deploy Azure Firewall using Bicep](https://learn.microsoft.com/en-us/azure/firewall/quick-create-bicep)
- [Azure Firewall forced tunneling](https://learn.microsoft.com/en-us/azure/firewall/forced-tunneling)

### Private Connectivity

- [Azure VPN Gateway](https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways)
- [Azure ExpressRoute](https://learn.microsoft.com/en-us/azure/expressroute/expressroute-introduction)
- [Private Link and Private Endpoints](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview)

### Connectivity Patterns

- [Connectivity to Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/connectivity-to-azure)
- [Connectivity to on-premises](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/connectivity-to-other-locations)
- [Traditional Azure networking topology](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/traditional-azure-networking-topology)

---

## Governance & Compliance

### Azure Policy

- [What is Azure Policy?](https://learn.microsoft.com/en-us/azure/governance/policy/overview)
- [Azure Policy definition structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Assign policies with Bicep](https://learn.microsoft.com/en-us/azure/governance/policy/assign-policy-bicep)
- [Policy-driven governance](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/governance)

### Policy Initiatives

- [Azure Policy initiative definitions](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure)
- [Built-in policy definitions](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)
- [Built-in initiatives](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-initiatives)

### Compliance & Security

- [Regulatory compliance in Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/regulatory-compliance)
- [Microsoft Cloud Security Benchmark](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)
- [Security, governance, and compliance disciplines](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/governance-security-compliance)

---

## Identity & Access Management

### Microsoft Entra ID

- [Identity and access management](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access)
- [Microsoft Entra ID in landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access-landing-zones)
- [Managed identities for Azure resources](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)

### Role-Based Access Control (RBAC)

- [What is Azure RBAC?](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)
- [Assign Azure roles using Bicep](https://learn.microsoft.com/en-us/azure/role-based-access-control/quickstart-role-assignments-bicep)
- [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [Platform access for landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access-platform-access)

---

## Management & Monitoring

### Centralized Logging

- [Management and monitoring for landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/management)
- [Design a Log Analytics workspace architecture](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/workspace-design)
- [Diagnostic settings in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings)

### Azure Monitor

- [Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)
- [Monitor hybrid and multicloud environments](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/monitor/)
- [Management baseline in Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/considerations/platform)

### Platform Automation

- [Platform automation and DevOps](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/platform-automation-devops)
- [Infrastructure as Code with Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)
- [Azure landing zone Bicep modules](https://github.com/Azure/ALZ-Bicep)

---

## Security

### Azure Security Center / Microsoft Defender

- [Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction)
- [Security baseline for Azure](https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview)
- [Secure score in Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/secure-score-security-controls)

### Network Security

- [Network Security Groups (NSGs)](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure DDoS Protection](https://learn.microsoft.com/en-us/azure/ddos-protection/ddos-protection-overview)
- [Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview)

### Data Protection

- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview)
- [Encryption at rest in Azure](https://learn.microsoft.com/en-us/azure/security/fundamentals/encryption-atrest)
- [Azure confidential computing](https://learn.microsoft.com/en-us/azure/confidential-computing/overview)

---

## Business Continuity & Disaster Recovery

### BCDR Strategy

- [Business continuity and disaster recovery](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-business-continuity-disaster-recovery)
- [Azure Site Recovery](https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-overview)
- [Backup and restore plan for Azure infrastructure](https://learn.microsoft.com/en-us/azure/architecture/framework/resiliency/backup-and-recovery)

### High Availability

- [Availability zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)
- [Azure regions and availability zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support)
- [Mission-critical baseline architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-intro)

---

## Cost Management

### FinOps & Cost Optimization

- [Cost Management discipline](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/govern/cost-management/)
- [Azure cost management and billing](https://learn.microsoft.com/en-us/azure/cost-management-billing/)
- [Design to optimize costs](https://learn.microsoft.com/en-us/azure/well-architected/cost/design-price)

### Tagging & Resource Organization

- [Use tags to organize resources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources)
- [Tag inheritance with Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies#tags)
- [Cost allocation with tags](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/cost-mgt-best-practices#organize-and-tag-your-resources)

---

## Deployment & Implementation

### Azure CLI & PowerShell

- [Deploy landing zones with Azure CLI](https://learn.microsoft.com/en-us/cli/azure/deployment)
- [Azure PowerShell for management groups](https://learn.microsoft.com/en-us/powershell/azure/manage-subscriptions-azureps)

### Infrastructure as Code

- [Azure Resource Manager (ARM) templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
- [Bicep overview](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)
- [Terraform on Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/overview)

### ALZ Accelerators

- [Enterprise-Scale Landing Zone on GitHub](https://github.com/Azure/Enterprise-Scale)
- [Deploy enterprise-scale with Bicep](https://github.com/Azure/ALZ-Bicep)
- [Deploy enterprise-scale with Terraform](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale)
- [Azure landing zone portal accelerator](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/deploy-landing-zones-with-portal)

---

## Migration & Modernization

### Cloud Migration

- [Azure migrate and modernize](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/migrate/)
- [Migration to Azure guidance](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/migrate/azure-migration-guide/)
- [Prepare landing zones for cloud migration](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/migrate-landing-zone)

---

## Reference Architectures

### Multi-Region & Global

- [Multi-region web app with failover](https://learn.microsoft.com/en-us/azure/architecture/web-apps/app-service/architectures/multi-region)
- [Baseline architecture for AKS](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks/baseline-aks)
- [Mission-critical baseline](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-intro)

### Industry-Specific

- [Financial services landing zone](https://learn.microsoft.com/en-us/industry/financial-services/financial-services-landing-zone)
- [Healthcare landing zone](https://learn.microsoft.com/en-us/industry/healthcare/healthcare-landing-zone)
- [Retail landing zone](https://learn.microsoft.com/en-us/industry/retail/)

---

## Learning Paths & Training

### Microsoft Learn Modules

- [Build a cloud governance strategy](https://learn.microsoft.com/en-us/training/modules/build-cloud-governance-strategy-azure/)
- [Design an enterprise governance strategy](https://learn.microsoft.com/en-us/training/modules/enterprise-governance/)
- [Manage resource organization](https://learn.microsoft.com/en-us/training/modules/manage-resource-organization/)

### Certifications

- [Microsoft Certified: Azure Solutions Architect Expert](https://learn.microsoft.com/en-us/certifications/azure-solutions-architect/)
- [Microsoft Certified: Azure Administrator Associate](https://learn.microsoft.com/en-us/certifications/azure-administrator/)

---

## Community & Support

### GitHub Repositories

- [Azure Landing Zones (Enterprise-Scale)](https://github.com/Azure/Enterprise-Scale)
- [ALZ Bicep Modules](https://github.com/Azure/ALZ-Bicep)
- [CAF Terraform Landing Zones](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale)
- [Azure Verified Modules](https://github.com/Azure/Azure-Verified-Modules)

### Documentation & Samples

- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)
- [Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)

---

## Best Practices & Guidance

### Design Principles

- [Design principles for Azure landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-principles)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Azure architecture design principles](https://learn.microsoft.com/en-us/azure/well-architected/pillars)

### Operational Excellence

- [Operational excellence with Azure landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/management)
- [DevOps with landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/platform-automation-devops)
- [Monitoring strategy](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/strategy/monitoring-strategy)
