# Identity Provider Selection - Microsoft Learn Resources

> **Curated Documentation**: Official Microsoft documentation and best practices for identity and authentication.

---

## Microsoft Entra ID (formerly Azure AD)

### Overview & Concepts

- [What is Microsoft Entra ID?](https://learn.microsoft.com/en-us/entra/fundamentals/whatis)
- [Microsoft identity platform overview](https://learn.microsoft.com/en-us/entra/identity-platform/v2-overview)
- [Authentication vs. authorization](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-vs-authorization)

### OAuth 2.0 & OpenID Connect

- [Microsoft identity platform and OAuth 2.0 authorization code flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow)
- [Microsoft identity platform and the OAuth 2.0 client credentials flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow)
- [OpenID Connect on the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc)
- [OAuth 2.0 authorization code flow with PKCE](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow#request-an-authorization-code)

### ASP.NET Core Integration

- [Secure a web API with Entra ID](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-protected-web-api-overview)
- [Web app that signs in users](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-web-app-sign-user-overview)
- [Enable your Web Apps and Web APIs to sign in users and call APIs with the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/index-web-app)
- [Microsoft.Identity.Web library](https://learn.microsoft.com/en-us/entra/msal/dotnet/microsoft-identity-web/)

### Single-Page Applications (SPA)

- [Single-page application: Sign-in and Sign-out](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-spa-sign-in)
- [Single-page application: Acquire a token to call an API](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-spa-acquire-token)
- [Tutorial: Sign in users and call Microsoft Graph from a JavaScript SPA](https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-v2-javascript-auth-code)
- [MSAL.js browser package](https://learn.microsoft.com/en-us/javascript/api/@azure/msal-browser/)

### Token Management

- [Access tokens in the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens)
- [ID tokens in the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/id-tokens)
- [Refresh tokens in the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/refresh-tokens)
- [Token lifetime policies](https://learn.microsoft.com/en-us/entra/identity-platform/configurable-token-lifetimes)
- [Validating tokens](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens#validate-tokens)

---

## Azure AD B2C (Business-to-Consumer)

### Overview & Setup

- [What is Azure AD B2C?](https://learn.microsoft.com/en-us/azure/active-directory-b2c/overview)
- [Technical and feature overview of Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/technical-overview)
- [Create an Azure AD B2C tenant](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant)

### User Flows & Custom Policies

- [User flows in Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview)
- [Custom policies in Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/custom-policy-overview)
- [Set up a sign-up and sign-in flow](https://learn.microsoft.com/en-us/azure/active-directory-b2c/add-sign-up-and-sign-in-policy)
- [Add social identity providers](https://learn.microsoft.com/en-us/azure/active-directory-b2c/add-identity-provider)

### Application Integration

- [Register a web application in Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications)
- [Configure authentication in a sample web app using Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/configure-authentication-sample-web-app)
- [Enable authentication in your own web API by using Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/enable-authentication-web-api)
- [Configure authentication in a sample SPA using Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/configure-authentication-sample-spa-app)

### Customization

- [Customize the user interface in Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/customize-ui)
- [Localization in Azure AD B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/language-customization)

---

## Authorization & Access Control

### Role-Based Access Control (RBAC)

- [Add app roles to your application](https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-app-roles-in-apps)
- [Use role-based access control in your application](https://learn.microsoft.com/en-us/entra/identity-platform/howto-implement-rbac-for-apps)
- [ASP.NET Core role-based authorization](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/roles)

### Claims-Based Authorization

- [Claims-based authorization in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/claims)
- [Policy-based authorization in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/policies)
- [Custom authorization policy providers](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/iauthorizationpolicyprovider)

### Token Claims

- [Optional claims in tokens](https://learn.microsoft.com/en-us/entra/identity-platform/optional-claims)
- [Customize claims emitted in tokens](https://learn.microsoft.com/en-us/entra/identity-platform/saml-claims-customization)
- [Claims mapping policy](https://learn.microsoft.com/en-us/entra/identity-platform/reference-claims-mapping-policy-type)

---

## Security Best Practices

### General Security

- [Microsoft identity platform best practices](https://learn.microsoft.com/en-us/entra/identity-platform/identity-platform-integration-checklist)
- [Security best practices for application properties](https://learn.microsoft.com/en-us/entra/identity-platform/security-best-practices-for-app-registration)
- [Handling errors and exceptions in MSAL.NET](https://learn.microsoft.com/en-us/entra/msal/dotnet/advanced/exceptions/)

### Token Security

- [Secure applications and APIs](https://learn.microsoft.com/en-us/entra/identity-platform/security-tokens)
- [Token cache serialization in MSAL.NET](https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/token-cache-serialization)
- [Acquire and cache tokens with MSAL](https://learn.microsoft.com/en-us/entra/msal/overview#acquiring-and-caching-tokens)

### PKCE & Secure Flows

- [Proof Key for Code Exchange (PKCE)](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow#protocol-details)
- [Authorization code flow for single-page apps](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-spa-overview)
- [Secure a SPA with PKCE](https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-v2-javascript-auth-code)

---

## Service-to-Service & Daemon Apps

### Client Credentials Flow

- [Daemon app that calls web APIs](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-daemon-overview)
- [Acquire a token in a daemon app](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-daemon-acquire-token)
- [Call a web API from a daemon app](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-daemon-call-api)

### Managed Identities

- [What are managed identities for Azure resources?](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)
- [Use managed identities to access Azure resources from an app](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-managed-identities-work-vm)
- [Azure SDK authentication with managed identity](https://learn.microsoft.com/en-us/azure/developer/intro/passwordless-overview)

---

## API Reference & SDKs

### MSAL Libraries

- [Microsoft Authentication Library (MSAL) overview](https://learn.microsoft.com/en-us/entra/msal/overview)
- [MSAL.NET (C#)](https://learn.microsoft.com/en-us/entra/msal/dotnet/)
- [MSAL for JavaScript (MSAL.js)](https://learn.microsoft.com/en-us/javascript/api/overview/msal-overview)
- [MSAL for Node.js](https://learn.microsoft.com/en-us/javascript/api/@azure/msal-node/)
- [MSAL for React](https://learn.microsoft.com/en-us/javascript/api/@azure/msal-react/)

### Microsoft Identity Web

- [Microsoft.Identity.Web overview](https://learn.microsoft.com/en-us/entra/msal/dotnet/microsoft-identity-web/)
- [Microsoft.Identity.Web API reference](https://learn.microsoft.com/en-us/dotnet/api/microsoft.identity.web)

---

## Migration Guides

- [Migrate from ADAL.NET to MSAL.NET](https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/msal-net-migration)
- [Migrate confidential client applications from ADAL.NET to MSAL.NET](https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/msal-net-migration-confidential-client)
- [Update your applications to use Microsoft Authentication Library (MSAL)](https://learn.microsoft.com/en-us/entra/identity-platform/msal-migration)

---

## Troubleshooting & Debugging

- [Troubleshoot publisher verification](https://learn.microsoft.com/en-us/entra/identity-platform/troubleshoot-publisher-verification)
- [Handle errors and exceptions in MSAL for JavaScript](https://learn.microsoft.com/en-us/entra/msal/javascript/error-handling)
- [Logging in MSAL.NET](https://learn.microsoft.com/en-us/entra/msal/dotnet/advanced/exceptions/msal-logging-dotnet)
- [Debug single sign-on issues](https://learn.microsoft.com/en-us/troubleshoot/azure/active-directory/troubleshoot-sign-in-issues)

---

## Additional Resources

### Third-Party Providers

- [Auth0 Documentation](https://auth0.com/docs)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Okta Developer Documentation](https://developer.okta.com/)
- [Duende IdentityServer Documentation](https://docs.duendesoftware.com/identityserver/v6/)

### Standards & Specifications

- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [Proof Key for Code Exchange (PKCE) RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636)
- [JSON Web Token (JWT) RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)
