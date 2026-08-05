# Security Policies Azure - Microsoft Learn Resources

Curated official Microsoft documentation for implementing security policies with Managed Identity, Key Vault, Azure Policy, RBAC, Microsoft Defender for Cloud, and security best practices.

---

## Managed Identity

### Core Documentation

- [What are managed identities?](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview) - Managed Identity overview
- [Managed identities for Azure resources](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/managed-identities-overview) - System-assigned vs user-assigned
- [Configure managed identities](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities) - Create and manage identities

### Authentication with Managed Identity

- [Authenticate with Azure SDK using DefaultAzureCredential](https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication) - DefaultAzureCredential authentication chain
- [Use managed identities with Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity) - App Service Managed Identity setup
- [Use managed identities with Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/managed-identity) - Container Apps Managed Identity
- [Use managed identities with Azure Functions](https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity?tabs=portal%2Chttp#add-a-system-assigned-identity) - Functions Managed Identity

---

## Azure Key Vault

### Core Documentation

- [What is Azure Key Vault?](https://learn.microsoft.com/en-us/azure/key-vault/general/overview) - Key Vault overview (secrets, keys, certificates)
- [Quickstart: Azure Key Vault secret client library for .NET](https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-net) - .NET SDK quickstart
- [Key Vault security](https://learn.microsoft.com/en-us/azure/key-vault/general/security-features) - Security features and best practices

### Access Control

- [Azure RBAC for Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide) - RBAC vs access policies
- [Grant permission to applications to access Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-access-policy) - Managed Identity access
- [Key Vault RBAC permission model](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-migration) - Migrate from access policies to RBAC

### Secret Management

- [About secrets](https://learn.microsoft.com/en-us/azure/key-vault/secrets/about-secrets) - Secret versioning, expiration, rotation
- [Rotate secrets automatically](https://learn.microsoft.com/en-us/azure/key-vault/secrets/tutorial-rotation-dual) - Automated secret rotation
- [Monitor Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/monitor-key-vault) - Logging and auditing

---

## Azure Policy

### Core Documentation

- [What is Azure Policy?](https://learn.microsoft.com/en-us/azure/governance/policy/overview) - Azure Policy overview
- [Understand Azure Policy effects](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects) - Deny, Audit, Append, Modify effects
- [Policy definition structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure) - JSON structure for custom policies

### Policy Enforcement

- [Create custom policy definitions](https://learn.microsoft.com/en-us/azure/governance/policy/tutorials/create-custom-policy-definition) - Custom policy creation
- [Policy initiatives (policy sets)](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure) - Group multiple policies
- [Assign policies](https://learn.microsoft.com/en-us/azure/governance/policy/assign-policy-portal) - Assign at subscription or resource group

### Built-In Policies

- [Built-in policy definitions](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies) - Azure Policy built-in definitions catalog
- [Regulatory compliance built-in initiatives](https://learn.microsoft.com/en-us/azure/governance/policy/samples/iso-27001) - ISO 27001, NIST, PCI-DSS compliance

---

## Azure Role-Based Access Control (RBAC)

### Core Documentation

- [What is Azure RBAC?](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview) - RBAC overview
- [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) - Catalog of built-in roles
- [Steps to assign an Azure role](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-steps) - RBAC assignment workflow

### Custom Roles

- [Create custom roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles) - Define custom RBAC roles
- [Azure custom roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles-portal) - Create via Portal, CLI, Bicep

### Best Practices

- [Best practices for Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices) - Least privilege, scope management
- [Troubleshoot Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting) - Common RBAC issues

---

## Microsoft Defender for Cloud

### Core Documentation

- [What is Microsoft Defender for Cloud?](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction) - Defender overview (formerly Azure Security Center)
- [Defender for Cloud plans](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction#defender-plans) - Free vs Standard tier features
- [Enable Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security) - Enable Standard tier

### Threat Protection

- [Defender for Servers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-servers-introduction) - VM threat protection, JIT access
- [Defender for App Service](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-app-service-introduction) - App Service security alerts
- [Defender for SQL](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-introduction) - SQL vulnerability assessment, threat detection
- [Defender for Storage](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-storage-introduction) - Malware scanning, anomaly detection
- [Defender for Containers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-introduction) - Kubernetes security, vulnerability scanning

### Security Recommendations

- [Security recommendations](https://learn.microsoft.com/en-us/azure/defender-for-cloud/review-security-recommendations) - Prioritized recommendations
- [Remediate recommendations](https://learn.microsoft.com/en-us/azure/defender-for-cloud/implement-security-recommendations) - Fix security issues
- [Secure score](https://learn.microsoft.com/en-us/azure/defender-for-cloud/secure-score-security-controls) - Security posture scoring

### Compliance

- [Regulatory compliance dashboard](https://learn.microsoft.com/en-us/azure/defender-for-cloud/regulatory-compliance-dashboard) - Compliance reporting (PCI-DSS, ISO 27001, SOC 2)
- [Continuous export](https://learn.microsoft.com/en-us/azure/defender-for-cloud/continuous-export) - Export alerts/recommendations to Log Analytics, Event Hubs

---

## Security Best Practices

### Azure Security Baseline

- [Azure security baseline](https://learn.microsoft.com/en-us/security/benchmark/azure/overview) - Microsoft Cloud Security Benchmark
- [Security baselines for Azure services](https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview) - Per-service security guidance

### Identity and Access

- [Passwordless authentication](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-passwordless) - Eliminate passwords (Managed Identity, FIDO2, Windows Hello)
- [Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview) - Conditional access policies for Azure AD
- [Privileged Identity Management (PIM)](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) - Just-in-time (JIT) privileged access

### Network Security

- [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/overview) - Network-level firewall
- [Network Security Groups (NSG)](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview) - Subnet/NIC firewall rules
- [Azure Private Link](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview) - Private connectivity to Azure services
- [DDoS Protection](https://learn.microsoft.com/en-us/azure/ddos-protection/ddos-protection-overview) - DDoS mitigation

### Data Protection

- [Encryption at rest](https://learn.microsoft.com/en-us/azure/security/fundamentals/encryption-atrest) - Azure Storage, SQL, Cosmos DB encryption
- [Encryption in transit](https://learn.microsoft.com/en-us/azure/security/fundamentals/encryption-overview#encryption-in-transit) - TLS 1.2+, HTTPS enforcement
- [Customer-managed keys (CMK)](https://learn.microsoft.com/en-us/azure/security/fundamentals/encryption-models#customer-managed-keys) - Bring your own encryption keys

### Application Security

- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Web application security risks
- [Secure development lifecycle](https://www.microsoft.com/en-us/securityengineering/sdl) - Microsoft SDL practices
- [Web application firewall (WAF)](https://learn.microsoft.com/en-us/azure/web-application-firewall/overview) - Application Gateway WAF, Front Door WAF

---

## Security Headers

### HTTP Security Headers

- [Content Security Policy (CSP)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) - Prevent XSS attacks
- [HTTP Strict Transport Security (HSTS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security) - Force HTTPS
- [X-Content-Type-Options](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options) - Prevent MIME-sniffing
- [X-Frame-Options](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options) - Prevent clickjacking
- [Referrer-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy) - Control referrer header
- [Permissions-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy) - Disable unused browser features

### CORS Configuration

- [Configure CORS for Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-rest-api#enable-cors) - CORS setup
- [CORS with Azure Storage](https://learn.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services) - Blob Storage CORS

---

## Secrets Management Best Practices

### Secret Rotation

- [Automate rotation of Key Vault secrets](https://learn.microsoft.com/en-us/azure/key-vault/secrets/tutorial-rotation) - Event Grid + Azure Functions rotation
- [Secret expiration](https://learn.microsoft.com/en-us/azure/key-vault/secrets/about-secrets#secret-attributes) - Set expiration dates on secrets

### Secret Access

- [Avoid secrets in source code](https://learn.microsoft.com/en-us/azure/key-vault/secrets/secrets-best-practices#avoid-storing-secrets-in-code) - Use Key Vault, not code/config
- [Application configuration best practices](https://learn.microsoft.com/en-us/azure/architecture/best-practices/app-configuration) - Environment variables, Key Vault references

---

## Threat Modeling

### Microsoft Threat Modeling Tool

- [Threat Modeling Tool](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool) - Download and usage guide
- [Threat modeling](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-getting-started) - Getting started with threat modeling

---

## Compliance and Governance

### Azure Compliance

- [Azure compliance documentation](https://learn.microsoft.com/en-us/azure/compliance/) - Compliance offerings (GDPR, HIPAA, SOC 2, ISO 27001)
- [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center) - Compliance and privacy information
- [Azure Service Trust Portal](https://servicetrust.microsoft.com/) - Audit reports and compliance documents

---

**Note**: Always reference official Microsoft Learn documentation for up-to-date security guidance, RBAC role definitions, and Azure Policy built-in definitions. Cross-reference with OWASP, NIST, and CIS benchmarks for industry-standard security practices.
