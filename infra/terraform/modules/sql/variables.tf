variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "server_name"         { type = string }
variable "database_name"       { type = string }
variable "admin_login"         { type = string; sensitive = true }
variable "admin_password"      { type = string; sensitive = true }
variable "sku_name"            { type = string; default = "S1" }
variable "log_analytics_id"    { type = string }
variable "tags"                { type = map(string) }
