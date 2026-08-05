# IaC Tool Selection - Microsoft Learn Resources

> **Curated Documentation**: Official documentation for infrastructure as code tools targeting Azure.

---

## Azure Bicep

### Overview & Getting Started

- [What is Bicep?](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)
- [Bicep tutorial](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/quickstart-create-bicep-use-visual-studio-code)
- [Install Bicep tools](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [Bicep playground](https://aka.ms/bicepdemo)

### Bicep Language

- [Bicep file structure](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file)
- [Data types in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/data-types)
- [Parameters in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameters)
- [Variables in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/variables)
- [Outputs in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/outputs)
- [Functions in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions)

### Modules & Reusability

- [Bicep modules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules)
- [Create Bicep module](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/tutorial-create-first-module)
- [Bicep registry](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules-registry)
- [Publish modules to registry](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/private-module-registry)

### Deployment

- [Deploy Bicep files with Azure CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli)
- [Deploy Bicep files with PowerShell](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-powershell)
- [Deploy Bicep with Azure Pipelines](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/add-template-to-azure-pipelines)
- [Deploy Bicep with GitHub Actions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions)

### Best Practices

- [Bicep best practices](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/best-practices)
- [Bicep linter](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/linter)
- [Bicep configuration file (bicepconfig.json)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config)

---

## Terraform on Azure

### Getting Started

- [Terraform on Azure documentation](https://learn.microsoft.com/en-us/azure/developer/terraform/)
- [Quickstart: Configure Terraform using Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell)
- [Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage)
- [Authenticate Terraform to Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure)

### Azure Provider

- [Azure Provider documentation (Terraform Registry)](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Configure the Azure Provider](https://learn.microsoft.com/en-us/azure/developer/terraform/quickstart-configure)
- [Azure Provider releases](https://github.com/hashicorp/terraform-provider-azurerm/releases)

### Common Patterns

- [Create Azure VMs with Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/create-linux-virtual-machine-with-infrastructure)
- [Create Azure Kubernetes Service with Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/create-k8s-cluster-with-tf-and-aks)
- [Create Azure App Service with Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/provision-infrastructure-using-azure-deployment-slots)
- [Create Azure Container Apps with Terraform](https://learn.microsoft.com/en-us/azure/container-apps/tutorial-terraform)

### CI/CD Integration

- [Automate Terraform with Azure Pipelines](https://learn.microsoft.com/en-us/azure/developer/terraform/deploy-to-azure-using-azure-pipelines)
- [Automate Terraform with GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/terraform/deploy-using-github-actions)

### Testing & Best Practices

- [Test Terraform projects](https://learn.microsoft.com/en-us/azure/developer/terraform/best-practices-testing-overview)
- [Terraform Azure best practices](https://learn.microsoft.com/en-us/azure/developer/terraform/best-practices-integration-testing)
- [Troubleshoot common Terraform issues](https://learn.microsoft.com/en-us/azure/developer/terraform/troubleshoot)

---

## ARM Templates

### Overview & Fundamentals

- [What are ARM templates?](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
- [ARM template structure](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/syntax)
- [ARM template best practices](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/best-practices)

### Template Development

- [Define parameters in ARM templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/parameters)
- [Use variables in ARM templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/variables)
- [Set outputs in ARM templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/outputs)
- [ARM template functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions)
- [Resource dependencies](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/resource-dependency)

### Linked & Nested Templates

- [Linked templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/linked-templates)
- [Use template specs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-specs)
- [Create and deploy template specs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-template-specs)

### Deployment

- [Deploy ARM templates with Azure CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli)
- [Deploy ARM templates with PowerShell](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)
- [What-if deployment](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-what-if)

### Migration & Comparison

- [Migrate from ARM templates to Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/migrate)
- [Decompile ARM templates to Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/decompile)
- [Compare ARM templates and Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/compare-template-syntax)

---

## Pulumi on Azure

### Getting Started

- [Azure and Pulumi getting started](https://www.pulumi.com/docs/clouds/azure/get-started/)
- [Azure Native Provider](https://www.pulumi.com/registry/packages/azure-native/)
- [Pulumi vs. Terraform](https://www.pulumi.com/docs/concepts/vs/terraform/)
- [Migrate from Terraform to Pulumi](https://www.pulumi.com/tf2pulumi/)

### Azure Integration

- [Azure authentication with Pulumi](https://www.pulumi.com/registry/packages/azure-native/installation-configuration/)
- [Deploy to Azure with Pulumi](https://www.pulumi.com/docs/clouds/azure/)
- [Pulumi Azure examples](https://github.com/pulumi/examples#azure)

### Languages & Patterns

- [Pulumi with TypeScript](https://www.pulumi.com/docs/languages-sdks/javascript/)
- [Pulumi with Python](https://www.pulumi.com/docs/languages-sdks/python/)
- [Pulumi with C#/.NET](https://www.pulumi.com/docs/languages-sdks/dotnet/)
- [Pulumi component resources](https://www.pulumi.com/docs/concepts/resources/components/)

---

## Azure Resource Manager (ARM)

### Core Concepts

- [Azure Resource Manager overview](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview)
- [Resource providers and types](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)
- [Resource groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- [Resource locks](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources)
- [Resource tags](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources)

### Deployment Modes

- [Deployment modes](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-modes)
- [Complete mode deletion](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-complete-mode-deletion)

### Deployment Scopes

- [Deploy to resource group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-resource-group)
- [Deploy to subscription](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-subscription)
- [Deploy to management group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-management-group)
- [Deploy to tenant](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-tenant)

---

## Infrastructure as Code Best Practices

### General Best Practices

- [Azure Well-Architected Framework - Infrastructure as Code](https://learn.microsoft.com/en-us/azure/well-architected/devops/automation-infrastructure)
- [Infrastructure as code with Azure](https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code)
- [Manage infrastructure lifecycles](https://learn.microsoft.com/en-us/azure/architecture/framework/devops/automation-infrastructure)

### Security & Compliance

- [Secure infrastructure as code](https://learn.microsoft.com/en-us/azure/security/develop/infrastructure-as-code)
- [Azure Policy for compliance](https://learn.microsoft.com/en-us/azure/governance/policy/overview)
- [Manage secrets in IaC](https://learn.microsoft.com/en-us/azure/key-vault/general/overview)

### Testing & Validation

- [Test ARM templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/test-toolkit)
- [ARM template test toolkit](https://github.com/Azure/arm-ttk)
- [Bicep test framework](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/linter)

---

## CI/CD & Automation

### GitHub Actions

- [Deploy to Azure using GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/github/github-actions)
- [Authenticate GitHub Actions to Azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Deploy ARM/Bicep with GitHub Actions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions)

### Azure Pipelines

- [Azure Pipelines overview](https://learn.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines)
- [Deploy ARM templates with Azure Pipelines](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/add-template-to-azure-pipelines)
- [Terraform in Azure Pipelines](https://learn.microsoft.com/en-us/azure/developer/terraform/deploy-to-azure-using-azure-pipelines)

### Azure CLI & PowerShell

- [Azure CLI overview](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure PowerShell overview](https://learn.microsoft.com/en-us/powershell/azure/)
- [Deployment commands comparison](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-cli)

---

## Tool Comparison & Migration

### Bicep vs. ARM vs. Terraform

- [Compare Bicep and ARM templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/compare-template-syntax)
- [Compare Bicep, JSON, and Terraform](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/compare-template-syntax)
- [When to use Bicep vs. Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/comparing-terraform-and-bicep)

### Migration Guides

- [Migrate from ARM to Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/migrate)
- [Decompile JSON to Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/decompile)
- [Convert between Terraform and Pulumi](https://www.pulumi.com/tf2pulumi/)

---

## Additional Resources

### Community & Learning

- [Bicep GitHub repository](https://github.com/Azure/bicep)
- [Terraform Azure provider GitHub](https://github.com/hashicorp/terraform-provider-azurerm)
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)
- [Bicep learning path](https://learn.microsoft.com/en-us/training/paths/bicep-deploy/)
- [Terraform on Azure learning path](https://learn.microsoft.com/en-us/training/paths/az-400-implement-manage-infrastructure/)

### Tools & Extensions

- [Bicep VS Code extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
- [Terraform VS Code extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
- [Azure Resource Manager Tools (VS Code)](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools)
- [Pulumi VS Code extension](https://marketplace.visualstudio.com/items?itemName=pulumi.pulumi-lsp-client)

### Official Documentation

- [Pulumi Documentation](https://www.pulumi.com/docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [HashiCorp Learn - Terraform](https://learn.hashicorp.com/terraform)
