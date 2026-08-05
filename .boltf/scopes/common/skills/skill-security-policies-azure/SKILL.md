---
name: skill-security-policies-azure
description: Define and enforce security policies with Managed Identity (passwordless authentication), Key Vault (secret management), Azure Policy (governance enforcement), RBAC (least privilege access), Microsoft Defender for Cloud, and security headers. Use when establishing security baseline, configuring authentication, managing secrets, or enforcing compliance. Critical because security policies prevent data breaches, ensure regulatory compliance, and establish organization-wide security standards.
---

# Security Policies Azure

## When to Use This Skill

Invoke this skill when you need to:

- **Implement Managed Identity** for passwordless authentication (eliminate connection strings, service principal secrets)
- **Manage secrets securely** with Azure Key Vault (database passwords, API keys, certificates)
- **Enforce security policies** with Azure Policy (HTTPS-only, allowed regions, required tags, deny public network access)
- **Configure RBAC** for fine-grained access control (grant Managed Identity access to Key Vault, Storage, SQL with least privilege)
- **Enable Microsoft Defender for Cloud** for threat detection, vulnerability assessment, compliance reporting
- **Configure security headers** (HSTS, Content-Security-Policy, X-Frame-Options) to prevent XSS, clickjacking, MIME-sniffing attacks

**Critical because**: Security policies define organization-wide constraints that prevent catastrophic failures—data breaches (PII exposure, ransomware), regulatory non-compliance (GDPR fines, SOC 2 audit failures), insider threats (excessive permissions, unencrypted secrets). Well-designed security policies establish defense in depth: authentication (Managed Identity → no secrets in code), authorization (RBAC → least privilege), data protection (Key Vault + encryption at rest/in transit), network security (Private Link, NSGs, Firewall), monitoring (Defender alerts).

---

## Security Framework: Defense in Depth

### Layer 1: Identity and Authentication

**Managed Identity** (Passwordless):

- **System-assigned**: Automatically created/deleted with resource lifecycle (App Service, Container Apps, VMs)
- **User-assigned**: Standalone identity reused across multiple resources
- **DefaultAzureCredential**: Authentication chain (Managed Identity → Visual Studio → Azure CLI → Environment Variables)

**Eliminates**:

- Connection strings in `appsettings.json`
- Service principal secrets (long-lived credentials = security risk)
- Secret rotation overhead (Managed Identity credentials rotate automatically)

### Layer 2: Authorization (RBAC)

**Role-Based Access Control**:

- **Built-in roles**: Key Vault Secrets User (read secrets), Storage Blob Data Contributor (read/write blobs), SQL DB Contributor
- **Custom roles**: Define precise permissions (actions, dataActions, notActions, notDataActions)
- **Scope**: Apply at subscription, resource group, or individual resource level
- **Principle**: Least privilege—grant minimum permissions required for task

**Example**: App Service Managed Identity → "Key Vault Secrets User" role on Key Vault (read-only access to secrets, cannot modify/delete).

### Layer 3: Data Protection

**Secrets Management**:

- **Azure Key Vault**: Store secrets, keys, certificates with versioning, expiration, soft delete, purge protection
- **Key Vault RBAC**: Replace access policies with RBAC (more granular, consistent with Azure RBAC model)
- **Secret rotation**: Automated rotation via Event Grid + Azure Functions (trigger on expiration, update secret, notify apps)

**Encryption**:

- **At rest**: Azure Storage (AES-256), SQL Database (TDE), Cosmos DB (automatic encryption)
- **In transit**: HTTPS/TLS 1.2+ enforced (Azure Policy: deny HTTP endpoints)
- **Customer-managed keys (CMK)**: Bring your own encryption keys stored in Key Vault (additional control over key lifecycle)

### Layer 4: Network Security

**Network Controls**:

- **Private Link**: Access Azure services (Key Vault, Storage, SQL) via private IP in VNet (no public internet exposure)
- **Network Security Groups (NSG)**: Firewall rules at subnet/NIC level (allow/deny traffic by port, protocol, source IP)
- **Azure Firewall**: Centralized network-level firewall with threat intelligence-based filtering
- **DDoS Protection**: Mitigate volumetric attacks (Standard tier: advanced protection + attack analytics)

### Layer 5: Monitoring and Threat Detection

**Microsoft Defender for Cloud**:

- **Threat protection**: Alerts for suspicious activity (brute-force SSH, malware, data exfiltration)
- **Vulnerability assessment**: Scan VMs, containers, SQL databases for known vulnerabilities (CVEs)
- **Security recommendations**: Prioritized by severity (critical, high, medium, low) with remediation steps
- **Compliance dashboard**: Track adherence to regulatory standards (PCI-DSS, ISO 27001, NIST, HIPAA, SOC 2)
- **Secure score**: Aggregated security posture metric (0-100 scale)

---

## Security Policies Decision Framework

### Decision 1: Authentication Strategy

**Managed Identity** (Recommended):

- **When to use**: Azure-hosted applications (App Service, Container Apps, Functions, VMs) accessing Azure services (Key Vault, Storage, SQL, Cosmos DB, Service Bus)
- **Trade-off**: Limited to Azure resources (cannot use for on-premises databases or third-party SaaS APIs requiring API keys)

**Service Principals** (Fallback):

- **When to use**: CI/CD pipelines (GitHub Actions, Azure DevOps), on-premises applications, non-Azure environments
- **Trade-off**: Requires secret management (client secret or certificate), rotation overhead, higher security risk

**API Keys/Connection Strings** (Avoid):

- **When to use**: Legacy applications, prototyping, local development
- **Trade-off**: High security risk (secrets in code/config), no automatic rotation, difficult audit trail

### Decision 2: Secret Storage

**Azure Key Vault** (Recommended):

- **When to use**: Any secret (database password, API key, certificate, encryption key)
- **Trade-off**: Additional latency for secret retrieval (cache secrets in application memory with 30-minute TTL)

**Environment Variables** (Acceptable for non-sensitive config):

- **When to use**: Non-secret configuration (feature flags, API endpoints, log levels)
- **Trade-off**: Not encrypted, visible in process listings, not suitable for secrets

**Code/Configuration Files** (Never):

- **When to use**: Never (high security risk)
- **Trade-off**: Secrets checked into source control, visible in deployment artifacts, difficult to rotate

### Decision 3: Governance Enforcement

**Azure Policy** (Centralized enforcement):

- **When to use**: Organization-wide standards (HTTPS-only, allowed regions, required tags, deny public network access)
- **Effects**: Deny (block non-compliant resources), Audit (log violations), Append (add missing properties), Modify (change non-compliant resources)
- **Trade-off**: Requires subscription-level permissions, can block deployments if policies too strict

**Manual Reviews** (Ad-hoc validation):

- **When to use**: Small teams, prototyping, non-production environments
- **Trade-off**: Human error, inconsistent enforcement, no automated compliance reporting

---

## How to Proceed

1. **Enable Managed Identity**:
   - App Service/Container Apps: Enable system-assigned identity in Azure Portal (Identity blade)
   - Code: Use `DefaultAzureCredential` from Azure SDK (`Azure.Identity` NuGet package)
   - Test locally: Authenticate via Azure CLI (`az login`) or Visual Studio (signed-in account)

2. **Configure Key Vault**:
   - Create Key Vault with `enableRbacAuthorization: true` (RBAC instead of access policies)
   - Grant Managed Identity "Key Vault Secrets User" role (read-only access to secrets)
   - Store secrets with expiration dates (90-day rotation policy)

3. **Assign RBAC Roles**:
   - Identify resources Managed Identity needs to access (Key Vault, Storage, SQL)
   - Grant built-in roles with least privilege (e.g., "Storage Blob Data Contributor" for read/write, not "Storage Account Contributor" for full control)
   - Use custom roles if built-in roles too permissive

4. **Enforce Azure Policies**:
   - Start with built-in policies (HTTPS-only for App Services, allowed locations, required tags)
   - Group policies into initiatives (Policy Sets) for easier management (e.g., "Production Security Baseline")
   - Enable enforcement mode ("Default") for production, audit mode ("DoNotEnforce") for testing
   - Review compliance dashboard regularly (remediate non-compliant resources)

5. **Enable Microsoft Defender for Cloud**:
   - Enable Standard tier for production subscriptions (VMs, App Services, SQL, Storage, Containers, Key Vault)
   - Configure Log Analytics workspace for centralized alerts/recommendations
   - Set up continuous export (alerts → Log Analytics, Event Hubs, or Security Information and Event Management (SIEM))
   - Review security recommendations weekly, prioritize high-severity issues

6. **Configure Security Headers**:
   - Add middleware in ASP.NET Core or configure `web.config` for IIS (App Service)
   - HSTS: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
   - CSP: `Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; img-src 'self' data: https:;`
   - X-Frame-Options: `DENY` (or `SAMEORIGIN` if embedding allowed)
   - X-Content-Type-Options: `nosniff`
   - Referrer-Policy: `strict-origin-when-cross-origin`

7. **Review Bundled Code Examples**:
   - `references/code-examples.md`: 6 complete examples (Managed Identity authentication C#, Key Vault secret retrieval with Bicep, Azure Policy enforcement, RBAC role assignments, Microsoft Defender CLI setup, security headers middleware)

8. **Consult Official Documentation**:
   - `references/microsoft-learn.md`: Managed Identity authentication guides, Key Vault RBAC migration, Azure Policy definition structure, RBAC built-in roles catalog, Defender for Cloud plans, OWASP security headers

9. **Validate with Constitution**:
   - Check `memory/constitution.md` Article XV (Security Policies & Standards) for mandatory security controls (Managed Identity required, Key Vault for secrets, HTTPS-only enforced, RBAC least privilege)
   - Document security architecture as ADR (Architecture Decision Record) using `@Bolt ADR` agent

10. **Run Security Audits**:
    - **Microsoft Defender for Cloud**: Review secure score, remediate recommendations
    - **Azure Policy compliance**: Check compliance dashboard, fix non-compliant resources
    - **Key Vault expiration audit**: Query secrets near expiration (`expires < 30 days`), rotate proactively
    - **RBAC audit**: Review role assignments quarterly, revoke unused permissions

---

**Remember**: Security is ongoing, not one-time setup. Rotate secrets every 90 days (automated via Key Vault Event Grid). Review RBAC assignments quarterly (remove unused permissions). Monitor Defender alerts daily (respond to high-severity threats within SLA). Enforce HTTPS-only (Azure Policy blocks HTTP endpoints). Use Managed Identity everywhere (eliminate secrets in code). Adopt defense in depth (multiple security layers, assume breach mentality).
