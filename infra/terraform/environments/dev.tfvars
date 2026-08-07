# Dev workspace — auto-deploy on merge to develop
location                   = "westeurope"
sql_sku                    = "S1"
redis_sku                  = "Basic"
redis_family               = "C"
redis_capacity             = 0
service_bus_sku            = "Standard"
api_min_replicas           = 1
api_max_replicas           = 3
alert_action_group_email   = "devops@company.com"
