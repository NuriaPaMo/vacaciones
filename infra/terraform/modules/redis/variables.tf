variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "redis_name"          { type = string }
variable "sku_name"            { type = string; default = "Basic" }
variable "family"              { type = string; default = "C" }
variable "capacity"            { type = number; default = 0 }
variable "log_analytics_id"    { type = string }
variable "tags"                { type = map(string) }
