variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "namespace_name"      { type = string }
variable "sku"                 { type = string; default = "Standard" }
variable "api_identity_id"     { type = string }
variable "log_analytics_id"    { type = string }
variable "tags"                { type = map(string) }
