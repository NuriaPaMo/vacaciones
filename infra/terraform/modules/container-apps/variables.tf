variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "env_name"            { type = string }
variable "app_name"            { type = string }
variable "container_image"     { type = string }
variable "min_replicas"        { type = number; default = 1 }
variable "max_replicas"        { type = number; default = 5 }
variable "api_identity_id"     { type = string }
variable "api_identity_client" { type = string }
variable "log_analytics_id"    { type = string }
variable "log_analytics_key"   { type = string; sensitive = true }
variable "key_vault_uri"       { type = string }
variable "sql_connection_secret"   { type = string }
variable "redis_connection_secret" { type = string }
variable "service_bus_fqdn"    { type = string }
variable "app_insights_connection" { type = string; sensitive = true }
variable "static_web_app_domain"  { type = string }
variable "tags"                { type = map(string) }
