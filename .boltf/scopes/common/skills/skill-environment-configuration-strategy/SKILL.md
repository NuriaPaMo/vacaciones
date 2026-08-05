---
name: skill-environment-configuration-strategy
description: Manage environment configuration and secrets across dev/uat/prod with Azure App Configuration, Key Vault, and feature flags. Use when designing configuration architecture, implementing secrets management, choosing between file-based vs cloud config, or establishing multi-environment patterns. Transversal skill applying to all projects - affects deployment strategy and security.
---

# Environment Configuration Strategy

## When to Use This Skill

This skill helps you design robust, secure, and maintainable configuration architectures because configuration management directly impacts security posture (secret exposure risks), operational complexity (drift across environments), development velocity (local setup friction), and long-term maintainability (configuration sprawl).

Consider this skill when:

1. **Starting a new application requiring environment-aware configuration** - You need to establish patterns for local development, staging, and production environments that balance developer convenience (quick local setup) with security (no secrets in source control) and operational flexibility (dynamic configuration changes without redeployment), because poor configuration architecture creates technical debt that compounds over time.

2. **Implementing secret management for connection strings and API keys** - Sensitive configuration must never appear in source control, plain-text files, or verbose logs, and choosing between .NET User Secrets, Azure Key Vault, Azure App Configuration secret references, or environment variables depends on your deployment target, security requirements, and operational maturity.

3. **Choosing between file-based configuration (appsettings.json) and cloud-based services (Azure App Configuration)** - File-based configuration is simpler for small applications but becomes cumbersome at scale, while cloud-based services add operational overhead but enable centralized management, dynamic refresh, and feature flags—the decision affects both development experience and runtime capabilities.

4. **Establishing multi-environment configuration management** - Your application will run in 3-6 distinct environments (local dev, CI/CD, dev, staging, production, DR), and you need to prevent configuration drift, ensure environment parity, and enable safe testing of production-like configuration without compromising security or stability.

5. **Implementing feature flags for progressive rollouts and A/B testing** - Feature flags decouple deployments from releases, enabling progressive rollouts, canary deployments, and instant rollback without code changes—selecting between Azure App Configuration Feature Management, LaunchDarkly, or custom solutions depends on requirements for targeting, analytics, and governance.

6. **Migrating legacy configuration to cloud-native patterns** - Existing applications often have configuration scattered across web.config files, database tables, registry keys, and environment-specific builds, and modernization to 12-factor methodology requires careful planning to avoid breaking existing deployments while improving security and maintainability.

7. **Implementing configuration validation to fail fast on startup** - Invalid configuration (missing required values, malformed connection strings, out-of-range settings) should prevent application startup rather than causing runtime failures, and .NET's Options pattern with DataAnnotations provides compile-time safety and startup validation that dramatically improves operational reliability.

---

## Decision Framework

### Configuration Storage Selection Tree

```text
┌──────────────────────────────────────────┐
│ What type of configuration value?       │
└──────────┬───────────────────────────────┘
           │
    ┌──────┴──────┬───────────────┬─────────────┐
    │             │               │             │
 Secret       Dynamic       Static         Feature
(password,   (needs        (build-time     Flags
 API key)    refresh)      config)         │
    │             │               │         │
    ▼             ▼               ▼         ▼
┌─────────────┐ ┌─────────────┐ ┌────────────┐ ┌────────────┐
│ Key Vault   │ │ App Config  │ │ File-based │ │ App Config │
│ (secrets)   │ │ (dynamic)   │ │ (appsett.) │ │ Feature    │
└─────────────┘ └─────────────┘ └────────────┘ │ Management │
                                                └────────────┘
```

### Configuration Hierarchy Decision

```text
┌────────────────────────────────────────┐
│ Application deployment target?         │
└────────┬───────────────────────────────┘
         │
    ┌────┴────┬──────────┬───────────┐
    │         │          │           │
 Azure    On-Prem    Container   Serverless
 Services            (K8s/ACA)   (Functions)
    │         │          │           │
    ▼         ▼          ▼           ▼
App Config  File +    ConfigMap    App Settings
  +        Env Vars     +          (portal/IaC)
Key Vault              Secrets        +
  +                      +         Key Vault
Managed Identity    Volume Mounts     +
                                   MI

┌────────────────────────────────────────┐
│ Configuration complexity?              │
└────────┬───────────────────────────────┘
         │
    ┌────┴────┬──────────┬───────────┐
    │         │          │           │
Simple    Medium     Complex      Enterprise
(1 env)   (3-5 env)  (multi-     (multi-tenant,
                     tenant)      geo-distributed)
    │         │          │           │
    ▼         ▼          ▼           ▼
appsett.  appsett.   App Config  App Config
  +         +            +            +
Env Vars  Key Vault  Key Vault    Key Vault
                        +            +
                     Feature      Advanced
                     Flags        Targeting
```

---

## Scoring Model: Configuration Strategy Comparison

Use this as a **conversation starter** to explore trade-offs, not as a rigid calculation. Scores reflect typical cloud-native application scenarios—your context may shift priorities.

| Approach                     | Security   | Flexibility | Operational Overhead | Dev Experience | Dynamic Updates | Cost (Small Scale)  |
| ---------------------------- | ---------- | ----------- | -------------------- | -------------- | --------------- | ------------------- |
| **appsettings.json**         | ⭐⭐       | ⭐⭐⭐      | ⭐⭐⭐⭐⭐           | ⭐⭐⭐⭐⭐     | ❌              | ⭐⭐⭐⭐⭐ (free)   |
| **Environment Variables**    | ⭐⭐⭐     | ⭐⭐⭐⭐    | ⭐⭐⭐⭐             | ⭐⭐⭐⭐       | ⭐              | ⭐⭐⭐⭐⭐ (free)   |
| **Azure App Configuration**  | ⭐⭐⭐⭐   | ⭐⭐⭐⭐⭐  | ⭐⭐⭐               | ⭐⭐⭐         | ⭐⭐⭐⭐⭐      | ⭐⭐⭐⭐ (low cost) |
| **Azure Key Vault**          | ⭐⭐⭐⭐⭐ | ⭐⭐⭐      | ⭐⭐⭐               | ⭐⭐⭐         | ⭐⭐            | ⭐⭐⭐⭐ (low cost) |
| **Hybrid (App Config + KV)** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐  | ⭐⭐                 | ⭐⭐⭐         | ⭐⭐⭐⭐⭐      | ⭐⭐⭐ (moderate)   |

**Key Trade-offs:**

- **Security**: Key Vault provides hardware-backed encryption and audit logs; file-based configuration risks accidental secret commits
- **Flexibility**: Azure App Configuration enables feature flags, dynamic updates, and A/B testing without redeployment
- **Operational Overhead**: Cloud services require additional infrastructure, monitoring, and access management
- **Dev Experience**: appsettings.json provides fastest local development; cloud services require authentication setup
- **Dynamic Updates**: Configuration refresh without restart available in App Configuration; file-based requires redeployment
- **Cost**: File-based and environment variables are free; App Configuration charges per request/storage; Key Vault charges per operation

---

## Configuration Strategy Patterns

### File-Based Configuration (appsettings.json)

**Primary Use Case**: Simple applications with static configuration, local development environments, and scenarios where configuration changes require intentional redeployment.

**Key Characteristics:**

- JSON files with hierarchical structure (appsettings.json, appsettings.{Environment}.json)
- Compiled into application deployment package
- Configuration provider loads in priority order (base → environment-specific)
- Supports nested sections, arrays, and strongly-typed binding via Options pattern
- No external dependencies or runtime network calls

**When File-Based Configuration Makes Sense:**

- Your application has < 5 configuration settings
- Configuration changes infrequently (monthly or less)
- You want zero external dependencies
- You need fastest possible application startup
- Your deployment pipeline manages environment-specific builds
- You're prototyping or building internal tools
- Configuration values are not sensitive secrets

**Technical Considerations:**

- appsettings.{Environment}.json merges with base appsettings.json
- Environment determined by ASPNETCORE_ENVIRONMENT variable
- User Secrets for local development prevent credential exposure
- Cannot update configuration without redeployment
- Large configuration files impact artifact size
- Strongly-typed Options pattern provides IntelliSense and validation

### Environment Variables

**Primary Use Case**: 12-factor app compliant deployments where configuration is injected at runtime, containerized applications, and cloud-native platforms like Azure App Service or Container Apps.

**Key Characteristics:**

- Configuration provided by hosting environment (not in repository)
- Standard across platforms (Windows, Linux, containers)
- Azure App Service application settings automatically become environment variables
- Hierarchical configuration via double-underscore syntax (Section\_\_NestedKey)
- Higher priority than file-based configuration (overrides appsettings.json)

**When Environment Variables Make Sense:**

- You're deploying to containers (Docker, Kubernetes, Azure Container Apps)
- Your platform natively supports environment variables (App Service, Functions)
- You need environment-specific configuration without file changes
- Your application follows 12-factor app methodology
- You want infrastructure-as-code (Bicep, Terraform) to inject configuration
- Configuration values are non-secret or platform-managed secrets

**Technical Considerations:**

- Syntax: `SectionName__NestedKey` maps to `configuration["SectionName:NestedKey"]`
- Azure App Service encrypts application settings at rest
- Container orchestrators (Kubernetes, ACA) inject via ConfigMaps and Secrets
- Environment variables visible to application processes (security consideration)
- No built-in support for configuration refresh (requires restart)
- Strong typing via Options pattern recommended

### Azure App Configuration (Centralized Cloud Service)

**Primary Use Case**: Multi-service architectures requiring centralized configuration, dynamic configuration updates, feature flags, and configuration consistency across distributed applications.

**Key Characteristics:**

- Managed service for application configuration and feature flags
- Key-value storage with labels for environment separation
- Dynamic configuration refresh without restart (push or pull)
- Feature Management SDK for progressive rollouts and targeting
- Snapshot capability for point-in-time configuration
- Geo-replication and high availability built-in

**When Azure App Configuration Makes Sense:**

- You have > 3 related services sharing configuration
- You need feature flags for canary releases or A/B testing
- You want centralized configuration management across microservices
- You require configuration updates without redeployment
- You need configuration versioning and audit trails
- Your architecture spans multiple Azure regions
- You want percentage-based or user-targeted feature rollouts

**Technical Considerations:**

- Labels organize configuration by environment (Development, Production)
- Sentinel keys trigger configuration refresh across application instances
- Feature Management SDK integrates with ASP.NET Core middleware
- Key Vault references enable storing secrets in Key Vault, retrieved via App Config
- Pricing based on requests (first 1000 requests/day free on Standard tier)
- Managed identity authentication recommended (no connection strings)
- Watch for refresh polling overhead (recommended 30-300 second intervals)

### Azure Key Vault (Secrets Management)

**Primary Use Case**: Secure storage and access control for sensitive configuration values including connection strings, passwords, API keys, certificates, and encryption keys.

**Key Characteristics:**

- Hardware-backed secret storage (HSM-backed in Premium tier)
- Fine-grained access control via Azure RBAC or access policies
- Audit logging for all secret access operations
- Secret versioning with expiration policies
- Integration with Azure services via managed identities
- Automatic certificate renewal for TLS certificates

**When Key Vault Makes Sense:**

- Your configuration includes database credentials, API keys, encryption keys
- You need audit trails for secret access (compliance requirement)
- You require fine-grained access control (per-secret RBAC)
- You're managing SSL/TLS certificates across multiple services
- You need secret rotation without application changes
- Your organization has security policies prohibiting secrets in any plain-text files
- You're implementing zero-trust security architecture

**Technical Considerations:**

- Secret names use hyphens (hyphen) which map to double-underscores in configuration
  - Key Vault: `ConnectionStrings--DefaultConnection`
  - Configuration: `config["ConnectionStrings:DefaultConnection"]`
- DefaultAzureCredential authentication pattern recommended
- Caching recommended to reduce Key Vault operations (cost optimization)
- Secret rotation requires application restart unless using App Configuration Key Vault references
- Throttling limits: 2000 requests per 10 seconds per vault
- Premium tier provides HSM-backing for keys and secrets

### Hybrid Approach (App Configuration + Key Vault References)

**Primary Use Case**: Best-practice cloud-native configuration combining centralized management, dynamic refresh, feature flags, and secure secret storage.

**Key Characteristics:**

- Non-sensitive configuration in Azure App Configuration
- Sensitive secrets stored in Key Vault, referenced from App Configuration
- Single integration point (App Configuration) for application
- Configuration refresh includes Key Vault secret updates
- Unified access control model via managed identities

**When Hybrid Approach Makes Sense:**

- You want centralized configuration AND secure secrets
- You need configuration refresh extending to secrets
- You require feature flags alongside secret management
- Your team prefers single configuration provider in code
- You want consistent managed identity authentication
- Your organization separates configuration and secrets for compliance

**Technical Considerations:**

- App Configuration references look like: `{"uri":"https://myvault.vault.azure.net/secrets/MySecret"}`
- Application retrieves secret from Key Vault transparently
- Managed identity requires access to both App Configuration AND Key Vault
- Configuration refresh automatically updates secrets
- Cost: Pay for both services (App Config requests + Key Vault operations)
- Recommended pattern for production enterprise applications

---

## The 12-Factor App Methodology (Configuration)

The 12-factor app methodology emphasizes strict separation of configuration from code with externalization to the environment.

**Core Principles:**

- **III. Config**: Store config in environment variables
- Configuration varies between deployments (dev, staging, production)
- Configuration never committed to source control
- Configuration orthogonal to code (same codebase, different config)

**Implementation Patterns:**

- Environment variables as primary configuration source
- Backing services (databases, caches) accessed via configuration
- No grouping of environments in code ("staging" vs "production" are just configs)
- Credentials and secrets externalized to hosting platform

**Why This Matters:**

- Prevents accidental secret exposure in repositories
- Enables true continuous deployment (same artifact, different config)
- Supports multi-cloud deployments (cloud-agnostic configuration)
- Simplifies testing (mock configuration via environment)

---

## Feature Flag Patterns

### Progressive Rollout

Enable features incrementally to reduce risk and gather feedback.

**Pattern Characteristics:**

- Start with 1% of users, gradually increase to 100%
- Instant rollback if metrics degrade
- Decouples deployment from release
- Percentage-based targeting via App Configuration Feature Management

**When to Use:**

- High-risk features requiring gradual validation
- New architectures requiring production validation
- Performance-sensitive changes
- User-facing changes requiring feedback cycles

### User Targeting

Enable features for specific users, groups, or tenants.

**Pattern Characteristics:**

- Target beta users, internal users, or specific customers
- User ID or claims-based targeting
- Time-window targeting (enable during specific hours)
- Geographic targeting

**When to Use:**

- Beta testing with limited user base
- Premium features for paid tiers
- Testing in production with internal users
- Compliance-based feature availability

---

## Common Pitfalls

### Secrets Committed to Source Control

**Problem**: Developers accidentally commit appsettings.json with connection strings or API keys causing security breaches.

**Solution**: Use .gitignore for appsettings.Development.json. Use .NET User Secrets for local development (`dotnet user-secrets set`). Implement pre-commit hooks scanning for secrets. Use Azure Key Vault for all environments.

### Configuration Drift Across Environments

**Problem**: Production configuration differs from staging in subtle ways, causing bugs that only appear in production.

**Solution**: Use Azure App Configuration with labels for environment separation. Use Infrastructure-as-Code (Bicep, Terraform) to inject configuration consistently. Implement configuration validation tests.

### Hard-Coded Configuration in Code

**Problem**: Database server names, API endpoints, or feature flags hard-coded as string literals throughout application.

**Solution**: Use Options pattern with strongly-typed classes. Bind configuration sections to POCOs. Validate configuration at startup with DataAnnotations.

### Environment Variable Naming Collisions

**Problem**: Generic environment variable names conflict with system variables or other applications.

**Solution**: Prefix application-specific variables (e.g., `MYAPP_DATABASE_URL`). Use hierarchical naming (`AppSettings__ApiBaseUrl`). Document variables in README.

### Missing Configuration Validation

**Problem**: Application starts successfully with invalid configuration, failing later during runtime operations.

**Solution**: Use Options pattern with `ValidateDataAnnotations()` and `ValidateOnStart()`. Implement custom IValidateOptions for complex validation. Fail fast on startup.

---

## Quick Reference

| Scenario                        | Primary Strategy             | Secondary Strategy       | Notes                             |
| ------------------------------- | ---------------------------- | ------------------------ | --------------------------------- |
| Local development               | appsettings.Development.json | User Secrets             | Keep development.json out of git  |
| Container deployments           | Environment Variables        | ConfigMaps/Secrets (K8s) | 12-factor compliant               |
| Azure App Service               | Application Settings         | Key Vault (secrets)      | App Settings become env vars      |
| Microservices (3+ services)     | Azure App Configuration      | Key Vault references     | Centralized management            |
| Feature flags / A/B testing     | App Configuration Features   | LaunchDarkly             | Built-in targeting filters        |
| Database credentials            | Azure Key Vault              | Managed Identity         | Never in plain text               |
| API keys (external services)    | Azure Key Vault              | Environment Variables    | Rotate via Key Vault              |
| Feature toggles (simple)        | appsettings.json boolean     | App Configuration        | App Config for dynamic updates    |
| Multi-tenant configuration      | Azure App Configuration      | Per-tenant labels        | Label = tenant ID                 |
| Configuration requiring refresh | Azure App Configuration      | Sentinel key pattern     | 5-minute cache expiration typical |
| Compliance/audit requirements   | Azure Key Vault              | Access policies/RBAC     | Full audit logs                   |
| Serverless (Azure Functions)    | Application Settings         | Key Vault                | Set via portal or IaC             |

---

## Bundled Resources

This skill includes bundled resources that are loaded progressively:

- **references/code-examples.md**: Complete implementation examples including appsettings.json hierarchy, environment variables, Azure App Configuration integration, Azure Key Vault secret management, feature flags, Node.js dotenv patterns, Options pattern validation, and CI/CD configuration injection workflows across .NET and Node.js
- **references/microsoft-learn.md**: Curated documentation covering ASP.NET Core configuration, Azure App Configuration, Azure Key Vault, 12-factor app methodology, feature management, CI/CD secrets management, best practices, testing strategies, and managed identity integration
