variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "sql_admin_login" {
  description = "Azure SQL Server administrator login name"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "Azure SQL Server administrator password — stored in Key Vault, never in state"
  type        = string
  sensitive   = true
}

variable "entra_tenant_id" {
  description = "Azure Entra ID tenant ID for auth and managed identity"
  type        = string
}

variable "api_container_image" {
  description = "Full container image reference for the API (e.g. ghcr.io/org/vacmgt-api:sha)"
  type        = string
  default     = "mcr.microsoft.com/dotnet/aspnet:10.0"  # placeholder until first build
}

variable "api_min_replicas" {
  description = "Minimum Container App replicas"
  type        = number
  default     = 1
}

variable "api_max_replicas" {
  description = "Maximum Container App replicas"
  type        = number
  default     = 5
}

variable "redis_sku" {
  description = "Azure Cache for Redis SKU name (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "redis_family" {
  description = "Redis SKU family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "Redis cache size (0–6 for C-family)"
  type        = number
  default     = 0
}

variable "service_bus_sku" {
  description = "Azure Service Bus namespace SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "sql_sku" {
  description = "Azure SQL Database SKU name (e.g. GP_Gen5_2, S1)"
  type        = string
  default     = "S1"
}

variable "alert_action_group_email" {
  description = "Email address for Azure Monitor alert notifications"
  type        = string
}
