---
name: skill-identity-provider-selection
description: Choose identity provider (Entra ID, Azure AD B2C, Auth0, Keycloak) and implement OAuth 2.0 flows with authorization models (RBAC, claims-based, ABAC). Use when implementing authentication for SPAs/APIs/mobile apps, selecting OAuth flows (Authorization Code + PKCE, Client Credentials), or designing multi-tenant auth. Foundational decision affecting all user-facing applications.
---

# Identity Provider Selection

## When to Use This Skill

This skill helps you navigate identity and authentication decisions because these choices affect security posture, user experience, development velocity, operational complexity, and long-term maintainability across your entire application stack.

Consider this skill when:

1. **Starting a new project requiring user authentication** - You need to understand which identity provider aligns with your user base (employees vs. customers), compliance requirements, and integration complexity, because choosing the wrong provider can lead to costly migrations, user friction, and security vulnerabilities down the line.

2. **Implementing OAuth 2.0 flows for web or mobile applications** - Different OAuth flows serve different application types (SPAs, server-rendered apps, native mobile, daemon services), and selecting the wrong flow can expose security vulnerabilities (like token theft in public clients) or create poor user experiences (like frequent re-authentication).

3. **Choosing between Entra ID and Azure AD B2C** - These Microsoft offerings serve fundamentally different audiences (organizational users vs. external customers), have different feature sets (B2C optimizes for consumer scenarios with social providers, Entra ID excels at enterprise SSO), and different pricing models that significantly impact project costs.

4. **Selecting an identity provider for your application** - The decision between Microsoft Entra ID, Azure AD B2C, Auth0, Keycloak, or Duende IdentityServer depends on factors like cloud platform alignment, customization needs, cost sensitivity, compliance requirements, and team expertise—each provider has distinct strengths that match specific architectural contexts.

5. **Designing authorization models for fine-grained access control** - Choosing between RBAC (role-based), claims-based, policy-based, or ABAC (attribute-based) authorization affects how easily you can model complex business rules, audit access decisions, and adapt to changing requirements without code changes.

6. **Implementing service-to-service authentication for microservices** - Daemon applications and background services require different authentication patterns (client credentials flow, managed identities, certificate-based auth) than user-facing applications, and improper implementation can create security gaps or operational overhead.

7. **Evaluating third-party identity providers vs. self-hosted solutions** - The build-vs-buy decision for identity infrastructure involves trade-offs between control (self-hosted Keycloak/IdentityServer), convenience (SaaS providers like Auth0), cloud integration (Entra ID), and total cost of ownership that vary dramatically across organizational contexts.

---

## Decision Framework

### Identity Provider Selection Tree

```text
┌─────────────────────────────────────────────┐
│ What is your primary user base?            │
└────────────┬────────────────────────────────┘
             │
      ┌──────┴───────┐
      │              │
 Enterprise      Customers
 Employees       (B2C/B2B2C)
      │              │
      │              │
      ▼              ▼
┌──────────────┐  ┌──────────────────────┐
│ On Azure?    │  │ Social providers?    │
└──┬────────┬──┘  └──┬───────────────┬───┘
   │        │        │               │
  YES      NO       YES              NO
   │        │        │               │
   ▼        │        ▼               ▼
Entra ID    │   ┌──────────────┐  ┌──────────────┐
            │   │ On Azure?    │  │ Need custom  │
            │   └──┬────────┬──┘  │ flows?       │
            │      │        │     └──┬────────┬──┘
            │     YES      NO        │        │
            │      │        │       YES      NO
            │      ▼        ▼        │        │
            │  Azure AD  Auth0       ▼        ▼
            │     B2C       │    Keycloak  Auth0
            │               │    Duende
            │               │
            ▼               ▼
      ┌──────────────────────────┐
      │ Budget + Control needs   │
      └──┬────────────────────┬──┘
         │                    │
    High Control        Managed Service
    (self-host)        (lower ops burden)
         │                    │
         ▼                    ▼
     Keycloak             Auth0
     Duende              Okta
```

### OAuth 2.0 Flow Selection Tree

```text
┌───────────────────────────────────┐
│ What type of application?         │
└────────────┬──────────────────────┘
             │
      ┌──────┴───────┬─────────────┬──────────┐
      │              │             │          │
    Browser       Server-side   Mobile     Daemon/
     SPA           Web App        App      Service
      │              │             │          │
      ▼              ▼             ▼          ▼
Authorization    Authorization   Authz     Client
Code + PKCE     Code Flow      Code +   Credentials
                (with server   PKCE      Flow
                secret)        (native)
```

---

## Scoring Model: Identity Provider Comparison

Use this as a **conversation starter** to explore trade-offs, not as a rigid calculation. Scores reflect typical scenarios—your context may shift priorities.

| Provider                  | Azure Integration | Customization | Cost (Small Scale)     | Enterprise Features | Customer Scenarios | Self-Hosted Option |
| ------------------------- | ----------------- | ------------- | ---------------------- | ------------------- | ------------------ | ------------------ |
| **Microsoft Entra ID**    | ⭐⭐⭐⭐⭐        | ⭐⭐⭐        | ⭐⭐⭐⭐               | ⭐⭐⭐⭐⭐          | ⭐⭐               | ❌                 |
| **Azure AD B2C**          | ⭐⭐⭐⭐⭐        | ⭐⭐⭐⭐      | ⭐⭐⭐                 | ⭐⭐⭐              | ⭐⭐⭐⭐⭐         | ❌                 |
| **Auth0**                 | ⭐⭐⭐            | ⭐⭐⭐⭐      | ⭐⭐                   | ⭐⭐⭐⭐            | ⭐⭐⭐⭐⭐         | ❌                 |
| **Keycloak**              | ⭐⭐              | ⭐⭐⭐⭐⭐    | ⭐⭐⭐⭐⭐ (free OSS)  | ⭐⭐⭐⭐            | ⭐⭐⭐⭐           | ✅                 |
| **Duende IdentityServer** | ⭐⭐              | ⭐⭐⭐⭐⭐    | ⭐⭐⭐⭐ (license req) | ⭐⭐⭐⭐            | ⭐⭐⭐             | ✅                 |

**Key Trade-offs:**

- **Azure Integration**: Entra ID and B2C offer seamless integration with Azure services (App Service, Functions, API Management), managed identities, and Azure RBAC
- **Customization**: Self-hosted solutions (Keycloak, Duende) and B2C (custom policies) allow deep UI and flow customization
- **Cost**: OSS options (Keycloak) are free but require operational overhead; SaaS providers charge per MAU (monthly active users)
- **Enterprise Features**: Entra ID excels at SSO, conditional access, and enterprise governance
- **Customer Scenarios**: B2C and Auth0 optimize for consumer-facing apps with social providers and user self-service

---

## Identity Provider Patterns

### Microsoft Entra ID (formerly Azure AD)

**Primary Use Case**: Enterprise applications for organizational users (employees, partners) requiring SSO, conditional access, and integration with Microsoft 365 and Azure services.

**Key Characteristics:**

- Deep Azure ecosystem integration (managed identities, Azure RBAC, Key Vault)
- Enterprise governance features (conditional access, PIM, access reviews)
- Multi-tenant application support for SaaS vendors
- B2B collaboration for external partners
- Strong compliance certifications (SOC 2, ISO 27001, HIPAA)

**When This Provider Makes Sense:**

- Your users are organizational accounts (work/school)
- You need SSO with Microsoft 365 or other Entra-integrated apps
- You require conditional access policies (MFA, device compliance, location-based access)
- Your infrastructure is primarily on Azure
- You need to support B2B scenarios (inviting external partners)

**Technical Considerations:**

- Supports OAuth 2.0 and OpenID Connect out of the box
- Token lifetimes: Access tokens (1 hour default), refresh tokens (90 days default, configurable)
- Multi-tenant apps require special consideration for tenant isolation
- App roles defined in manifest enable RBAC within Entra ID
- Microsoft.Identity.Web library simplifies ASP.NET Core integration
- MSAL (Microsoft Authentication Library) provides client SDKs for JavaScript, .NET, Python, Java

### Azure AD B2C (Business-to-Consumer)

**Primary Use Case**: Customer-facing applications requiring social identity providers, self-service registration, and custom branding while leveraging Azure's security infrastructure.

**Key Characteristics:**

- Consumer-optimized authentication flows (social providers: Google, Facebook, Apple)
- Custom branding and UI customization through HTML templates
- Self-service password reset and profile editing
- User flows for common scenarios (sign-up, sign-in, password reset)
- Custom policies (XML-based) for complex authentication logic
- Pay-per-MAU pricing model (first 50K MAU free)

**When This Provider Makes Sense:**

- Your users are consumers or customers (not organizational accounts)
- You need social identity provider integration
- Your brand requires custom authentication UI
- You need to collect custom user attributes during registration
- You want a managed service without operational overhead
- Your application is on Azure and benefits from tight integration

**Technical Considerations:**

- User flows provide quick setup for standard scenarios
- Custom policies (Identity Experience Framework) enable advanced customization but have steep learning curve
- Claims transformation allows modifying token claims before issuance
- API connectors enable integration with external systems during authentication flows
- Localization supported for 36+ languages
- Premium features (fraud detection, anomaly detection) require P1/P2 tiers

### Auth0

**Primary Use Case**: Multi-platform applications requiring rapid authentication implementation, extensive identity provider choices, and minimal operational burden across cloud platforms.

**Key Characteristics:**

- Platform-agnostic (works across AWS, Azure, GCP, on-premises)
- Extensive social and enterprise provider catalog (100+ integrations)
- Rules and Actions for extensibility (serverless functions)
- Universal Login provides consistent, secure authentication UI
- Strong developer experience with comprehensive SDKs
- Built-in attack protection (bot detection, breached password detection)

**When This Provider Makes Sense:**

- You need multi-cloud or cloud-agnostic identity solution
- Your application requires many social or enterprise providers
- You want rapid time-to-market with minimal authentication code
- Your team lacks deep identity expertise
- You need consistent authentication across web, mobile, and desktop
- Developer experience and documentation are priorities

**Technical Considerations:**

- Actions (Node.js functions) run during authentication pipeline for custom logic
- Organizations feature enables B2B multi-tenancy
- Pricing based on MAU with generous free tier (7K MAU)
- Supports passwordless authentication (email magic links, SMS OTP, WebAuthn)
- Refresh token rotation enhances security for SPAs
- Extensive marketplace for integrations and extensions

### Keycloak

**Primary Use Case**: Self-hosted identity and access management for organizations requiring full control, deep customization, and zero licensing costs with tolerance for operational overhead.

**Key Characteristics:**

- Open-source (Apache 2.0 license) with no per-user costs
- Full control over hosting, data residency, and customization
- Supports SAML 2.0 in addition to OAuth/OIDC (legacy enterprise integrations)
- User federation (LDAP, Active Directory) for hybrid identity scenarios
- Extensive admin console for identity management
- Red Hat support available (Red Hat SSO is commercial Keycloak distribution)

**When This Provider Makes Sense:**

- You have strict data residency or sovereignty requirements
- Your organization has strong DevOps/infrastructure capabilities
- You need deep customization of authentication flows
- Budget constraints prohibit per-user licensing
- You require SAML 2.0 support for legacy applications
- You want to avoid vendor lock-in

**Technical Considerations:**

- Requires operational expertise (deployment, scaling, monitoring, patching)
- Kubernetes-native deployment with Keycloak Operator
- Service Provider Interfaces (SPIs) enable deep customization
- Realm concept enables multi-tenancy within single Keycloak instance
- Admin REST API for automation and integration
- Performance tuning required for high-scale deployments

### Duende IdentityServer

**Primary Use Case**: .NET applications requiring a self-hosted, enterprise-grade identity provider with extensive customization, tight framework integration, and advanced OAuth/OIDC scenarios.

**Key Characteristics:**

- .NET-native implementation (successor to IdentityServer4)
- Full source code access for maximum customization
- Advanced OAuth/OIDC scenarios (token exchange, pushed authorization requests)
- Strong community and commercial support
- Integrates directly with ASP.NET Core Identity
- License required for production use (free for dev/testing, open-source projects)

**When This Provider Makes Sense:**

- Your stack is .NET-centric
- You need advanced OAuth/OIDC features not available in other providers
- You require complete control over authentication logic
- You have .NET expertise in-house
- Your architecture requires embedded identity server
- You need specific customization that SaaS providers can't accommodate

**Technical Considerations:**

- Licensing: Free for open-source projects, paid license for commercial use
- Deep integration with ASP.NET Core (middleware, DI, configuration)
- Entity Framework Core support for storing configuration and operational data
- Extensive extensibility through interfaces and dependency injection
- Well-documented but requires deeper OAuth/OIDC understanding
- Operational overhead similar to Keycloak (self-hosted)

---

## OAuth 2.0 Flow Patterns

### Authorization Code Flow + PKCE (Recommended for SPAs and Native Apps)

The authorization code flow with Proof Key for Code Exchange (PKCE) is the modern, secure approach for public clients (JavaScript SPAs, mobile apps) that cannot securely store client secrets.

**Flow Characteristics:**

- Authorization happens via browser redirect to identity provider
- Code exchange occurs on backend (or client for SPAs with PKCE)
- PKCE prevents authorization code interception attacks
- Refresh tokens enable long-lived sessions without re-authentication
- Recommended by OAuth 2.0 Security Best Practices (BCP)

**When to Use:**

- Single-Page Applications (React, Angular, Vue)
- Native mobile applications (iOS, Android)
- Desktop applications
- Any public client that cannot secure a client secret

### Client Credentials Flow (Service-to-Service)

Daemon applications and background services authenticate using client ID and secret (or certificate) without user context.

**Flow Characteristics:**

- Application authenticates as itself, not on behalf of a user
- Suitable for automated processes, background jobs, API-to-API calls
- Token represents application identity, not user identity
- Certificate-based authentication recommended over secrets for production
- Managed identities (Azure) eliminate need for secret management

**When to Use:**

- Background services calling APIs
- Scheduled jobs requiring API access
- Microservice-to-microservice authentication
- Azure Functions triggered by timers/queues calling downstream APIs

### Authorization Code Flow with Client Secret (Server-Side Web Apps)

Traditional server-rendered applications can securely store client secrets and handle token exchange server-side.

**Flow Characteristics:**

- Authorization code exchanged for tokens on server
- Client secret validates application identity
- Session stored server-side (cookies)
- Tokens never exposed to browser

**When to Use:**

- ASP.NET MVC/Razor Pages applications
- Express/Node.js server-rendered applications
- Any confidential client with secure server-side session storage

---

## Authorization Model Patterns

### Role-Based Access Control (RBAC)

Users are assigned roles, and permissions are granted to roles rather than individual users.

**Pattern Characteristics:**

- Coarse-grained: Roles represent job functions (Admin, Manager, Employee)
- App roles defined in identity provider and included in tokens as claims
- ASP.NET Core authorization policies check role membership
- Simple to implement and understand

**When RBAC Makes Sense:**

- Authorization needs map cleanly to organizational roles
- Permissions change infrequently
- Small number of distinct roles (<10)
- Business rules are simple (if Admin, allow; else deny)

### Claims-Based Authorization

Authorization decisions based on user claims (attributes) included in security tokens.

**Pattern Characteristics:**

- Fine-grained: Individual attributes (department, level, employee_id)
- Claims mapping allows customizing token contents
- Flexible authorization policies combine multiple claims
- Supports complex business rules

**When Claims-Based Makes Sense:**

- Authorization depends on multiple user attributes
- Business logic requires combining conditions (department AND level)
- Identity provider provides rich user profile data
- You want to avoid role explosion

### Policy-Based Authorization

Authorization requirements encapsulated as reusable policies evaluated at runtime.

**Pattern Characteristics:**

- Most flexible: Custom logic in authorization handlers
- Policies can combine claims, roles, resources, and context
- Centralized authorization logic (single-responsibility)
- Testable authorization rules

**When Policy-Based Makes Sense:**

- Complex business rules that don't fit claims or roles
- Context-dependent authorization (time of day, location)
- Resource-based authorization (document owner can edit)
- Need for audit trail of authorization decisions

---

## Common Pitfalls

### Token Storage in Browser

**Problem**: Storing JWTs in localStorage exposes them to XSS attacks.

**Solution**: Use httpOnly cookies for refresh tokens; store short-lived access tokens in memory. Consider BFF (Backend-for-Frontend) pattern for highest security.

### Overly Long Token Lifetimes

**Problem**: Long-lived access tokens increase blast radius if compromised.

**Solution**: Keep access tokens short (5-15 minutes), use refresh tokens for longevity, implement refresh token rotation.

### Not Validating Token Audience

**Problem**: Accepting tokens intended for other APIs creates security vulnerability.

**Solution**: Always validate `aud` (audience) claim matches your API identifier.

### Client Secret in Frontend Code

**Problem**: Embedding client secrets in JavaScript/mobile apps exposes credentials.

**Solution**: Use authorization code flow + PKCE for public clients; never use client credentials flow in frontend.

### Ignoring Token Expiration

**Problem**: Using expired tokens causes intermittent failures.

**Solution**: Implement automatic token refresh before expiration; handle 401 responses gracefully.

---

## Quick Reference

| Scenario                        | Provider Suggestion         | OAuth Flow                | Authorization Model |
| ------------------------------- | --------------------------- | ------------------------- | ------------------- |
| Enterprise employees on Azure   | Microsoft Entra ID          | Authorization Code        | RBAC (App Roles)    |
| Customer-facing app on Azure    | Azure AD B2C                | Auth Code + PKCE          | Claims-based        |
| Multi-cloud consumer app        | Auth0                       | Auth Code + PKCE          | Custom (Rules)      |
| Self-hosted with full control   | Keycloak                    | Auth Code + PKCE          | RBAC + Claims       |
| .NET-centric advanced scenarios | Duende IdentityServer       | Auth Code + PKCE          | Policy-based        |
| Background service calling API  | Entra ID (Managed Identity) | Client Credentials        | App-level RBAC      |
| React SPA                       | Any provider                | Auth Code + PKCE          | Claims/RBAC         |
| Mobile app (iOS/Android)        | Any provider                | Auth Code + PKCE (native) | Claims/RBAC         |

---

## Bundled Resources

This skill includes bundled resources that are loaded progressively:

- **references/code-examples.md**: Complete implementation examples for Entra ID, B2C, Auth0, JWT validation, RBAC, claims-based authorization, service-to-service authentication, and SPA integration across C#/.NET and Node.js/TypeScript
- **references/microsoft-learn.md**: Curated Microsoft documentation covering OAuth 2.0 flows, MSAL libraries, token validation, authorization patterns, security best practices, and API references
