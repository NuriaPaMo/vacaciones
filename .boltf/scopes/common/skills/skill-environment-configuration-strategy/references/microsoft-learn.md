# Environment Configuration Strategy - Microsoft Learn Resources

> **Curated Documentation**: Official Microsoft documentation for configuration management patterns and Azure services.

---

## ASP.NET Core Configuration

### Fundamentals

- [Configuration in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)
- [Configuration providers](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/#configuration-providers)
- [Environment-based configuration](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/environments)
- [Use multiple environments](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/environments)

### Options Pattern

- [Options pattern in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options)
- [Configure options with a delegate](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options#options-configured-with-a-delegate)
- [Options validation](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options#options-validation)
- [IValidateOptions for complex validation](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options#ivalidateoptions-for-complex-validation)

### User Secrets

- [Safe storage of app secrets in development](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets)
- [Enable secret storage](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets#enable-secret-storage)
- [Set a secret](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets#set-a-secret)

---

## Azure App Configuration

### Overview & Getting Started

- [What is Azure App Configuration?](https://learn.microsoft.com/en-us/azure/azure-app-configuration/overview)
- [Quickstart: Create an Azure App Configuration store](https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-azure-app-configuration-create)
- [Use Azure App Configuration in ASP.NET Core](https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-aspnet-core-app)
- [Use Azure App Configuration in Node.js](https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-javascript-provider)

### Configuration Refresh

- [Use dynamic configuration in ASP.NET Core](https://learn.microsoft.com/en-us/azure/azure-app-configuration/enable-dynamic-configuration-aspnet-core)
- [Use dynamic configuration in .NET Framework](https://learn.microsoft.com/en-us/azure/azure-app-configuration/enable-dynamic-configuration-dotnet)
- [Configuration refresh strategies](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-app-configuration-event)

### Feature Management

- [Feature management overview](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-feature-management)
- [Enable feature flags in ASP.NET Core](https://learn.microsoft.com/en-us/azure/azure-app-configuration/use-feature-flags-dotnet-core)
- [Manage feature flags](https://learn.microsoft.com/en-us/azure/azure-app-configuration/manage-feature-flags)
- [Feature filters](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-feature-filters-aspnet-core)
- [Targeting filters](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-targetingfilter-aspnet-core)

### Key-Value Management

- [Work with key-values](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-key-value)
- [Use labels for environment-specific configuration](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-labels)
- [Point-in-time snapshot](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-point-time-snapshot)

### Integration Patterns

- [Import configuration from a file](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-import-export-data)
- [Use managed identities to access App Configuration](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-integrate-azure-managed-service-identity)
- [Azure App Configuration best practices](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-best-practices)

---

## Azure Key Vault

### Overview & Setup

- [What is Azure Key Vault?](https://learn.microsoft.com/en-us/azure/key-vault/general/overview)
- [Azure Key Vault basic concepts](https://learn.microsoft.com/en-us/azure/key-vault/general/basic-concepts)
- [Quickstart: Create a key vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal)

### Secrets Management

- [About secrets](https://learn.microsoft.com/en-us/azure/key-vault/secrets/about-secrets)
- [Set and retrieve a secret](https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-portal)
- [Secret versioning](https://learn.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates#objects-identifiers-and-versioning)

### .NET Integration

- [Use Key Vault configuration provider in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/key-vault-configuration)
- [Azure Key Vault .NET SDK](https://learn.microsoft.com/en-us/dotnet/api/overview/azure/security.keyvault.secrets-readme)
- [Authenticate to Key Vault with .NET](https://learn.microsoft.com/en-us/azure/key-vault/general/authentication)

### Access Control

- [Provide access to Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide)
- [Use managed identities with Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/authentication#managed-identity)
- [Key Vault access policies vs. Azure RBAC](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-access-policy)

### Best Practices

- [Azure Key Vault best practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Throttling guidance](https://learn.microsoft.com/en-us/azure/key-vault/general/overview-throttling)
- [Monitoring and alerting](https://learn.microsoft.com/en-us/azure/key-vault/general/monitor-key-vault)

---

## Environment Variables & Secrets

### .NET Configuration

- [Environment variable configuration provider](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/#environment-variable-configuration-provider)
- [Hierarchical configuration using environment variables](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/#non-prefixed-environment-variables)
- [Environment variables naming convention](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/#environment-variables)

### Azure App Service

- [Configure app settings in App Service](https://learn.microsoft.com/en-us/azure/app-service/configure-common)
- [Configure connection strings](https://learn.microsoft.com/en-us/azure/app-service/configure-common#configure-connection-strings)
- [Environment variables and app settings in containers](https://learn.microsoft.com/en-us/azure/app-service/configure-custom-container#configure-environment-variables)

### Azure Container Apps

- [Manage secrets in Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets)
- [Set environment variables](https://learn.microsoft.com/en-us/azure/container-apps/environment-variables)

### Azure Functions

- [Manage your function app settings](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-use-azure-function-app-settings)
- [App settings reference for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings)

---

## 12-Factor App Methodology

### Core Principles

- [The Twelve-Factor App](https://12factor.net/)
- [III. Config - Store config in the environment](https://12factor.net/config)
- [Backing services](https://12factor.net/backing-services)

### Microsoft Implementation Guides

- [.NET Microservices: Configuration](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/multi-container-microservice-net-applications/configuration)
- [Cloud-Native .NET Apps](https://learn.microsoft.com/en-us/dotnet/architecture/cloud-native/)
- [Configuration in containerized applications](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/multi-container-microservice-net-applications/implement-api-gateways-with-ocelot#configuration)

---

## Feature Management

### Microsoft Feature Management

- [Feature management .NET library](https://learn.microsoft.com/en-us/azure/azure-app-configuration/feature-management-dotnet-reference)
- [Use feature filters](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-feature-filters-aspnet-core)
- [Conditional feature filters](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-targetingfilter-aspnet-core)

### Patterns & Strategies

- [Feature flags patterns](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-feature-management#feature-flag-usage-in-code)
- [Progressive rollouts](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-targetingfilter-aspnet-core)
- [A/B testing with feature flags](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-feature-filters-aspnet-core#targeting-filter)

---

## Azure DevOps & CI/CD

### Azure Pipelines

- [Use secrets in Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables)
- [Variable groups](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups)
- [Link secrets from Azure Key Vault](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups#link-secrets-from-an-azure-key-vault)

### GitHub Actions

- [Encrypted secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Using secrets in a workflow](https://docs.github.com/en/actions/security-guides/encrypted-secrets#using-encrypted-secrets-in-a-workflow)
- [Azure Login action](https://github.com/Azure/login)

---

## Best Practices & Patterns

### Security

- [Secure configuration data](https://learn.microsoft.com/en-us/aspnet/core/security/)
- [Prevent secrets in source code](https://learn.microsoft.com/en-us/azure/security/develop/secure-dev-overview#prevent-secrets-from-being-checked-in)
- [Credential scanning in Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/repos/security/github-advanced-security-secret-scanning)

### Configuration Management

- [Configuration best practices for .NET](https://learn.microsoft.com/en-us/dotnet/core/extensions/configuration)
- [Configuration in ASP.NET Core best practices](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/#configuration-best-practices)
- [Avoid using production secrets in development](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets#production-secrets)

### Multi-Environment Management

- [Manage environments in Azure](https://learn.microsoft.com/en-us/azure/architecture/guide/devops/devops-deployment-environments)
- [Environment-specific configuration strategies](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/multi-container-microservice-net-applications/configuration)
- [Deployment slots in Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots)

---

## Azure Managed Identities

### Overview

- [What are managed identities for Azure resources?](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)
- [How managed identities work](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-managed-identities-work-vm)

### Service Integration

- [Use managed identity with App Configuration](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-integrate-azure-managed-service-identity)
- [Use managed identity with Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/authentication#managed-identity)
- [Configure managed identities for App Service](https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity)

### .NET SDK Integration

- [Azure SDK for .NET with DefaultAzureCredential](https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication)
- [DefaultAzureCredential class](https://learn.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential)

---

## Node.js Configuration

### Environment Variables

- [Node.js process.env](https://nodejs.org/docs/latest/api/process.html#process_process_env)
- [dotenv package documentation](https://github.com/motdotla/dotenv)

### Azure Integration

- [Use Azure App Configuration in Node.js](https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-javascript-provider)
- [Azure SDK for JavaScript](https://learn.microsoft.com/en-us/javascript/api/overview/azure/)

---

## Testing & Validation

### Configuration Testing

- [Test configuration in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests#customize-webapplicationfactory)
- [Mock IOptions for unit testing](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options#options-interfaces)

### Integration Testing

- [Integration tests in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests)
- [Test with WebApplicationFactory](https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests#basic-tests-with-the-default-webapplicationfactory)

---

## Additional Resources

### Tools

- [Azure CLI - az appconfig](https://learn.microsoft.com/en-us/cli/azure/appconfig)
- [Azure CLI - az keyvault](https://learn.microsoft.com/en-us/cli/azure/keyvault)
- [Secret Scanner for Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/repos/security/github-advanced-security-secret-scanning)

### Community & Learning

- [Azure App Configuration samples](https://github.com/Azure/AppConfiguration)
- [Microsoft.Extensions.Configuration GitHub](https://github.com/dotnet/runtime/tree/main/src/libraries/Microsoft.Extensions.Configuration)
- [Feature Management samples](https://github.com/microsoft/FeatureManagement-Dotnet)
