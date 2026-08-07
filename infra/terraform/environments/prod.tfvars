# Prod workspace — manual approval required before apply
location                   = "westeurope"
sql_sku                    = "GP_Gen5_2"
redis_sku                  = "Standard"
redis_family               = "C"
redis_capacity             = 1
service_bus_sku            = "Standard"
api_min_replicas           = 2
api_max_replicas           = 10
alert_action_group_email   = "ops@company.com"
