terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state in Azure Storage — workspace-per-environment
  backend "azurerm" {
    resource_group_name  = "rg-vacmgt-tfstate"
    storage_account_name = "stvacmgttfstate"
    container_name       = "tfstate"
    key                  = "vacmgt.tfstate"
    use_oidc             = true   # workload identity federation for Azure DevOps
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  use_oidc = true
}

provider "azuread" {
  use_oidc = true
}
