locals {
  env    = terraform.workspace  # "dev" or "prod"
  prefix = "vacmgt"

  tags = {
    project     = "VacationManagement"
    environment = local.env
    managed_by  = "terraform"
    repository  = "vacaciones"
  }

  # Resource name helpers — follow Azure abbreviation conventions
  names = {
    resource_group       = "rg-${local.prefix}-${local.env}"
    container_apps_env   = "cae-${local.prefix}-${local.env}"
    container_app_api    = "ca-${local.prefix}-api-${local.env}"
    sql_server           = "sql-${local.prefix}-${local.env}"
    sql_database         = "sqldb-${local.prefix}-${local.env}"
    redis                = "redis-${local.prefix}-${local.env}"
    service_bus          = "sb-${local.prefix}-${local.env}"
    static_web_app       = "stapp-${local.prefix}-${local.env}"
    key_vault            = "kv-${local.prefix}-${local.env}"
    log_analytics        = "law-${local.prefix}-${local.env}"
    app_insights         = "appi-${local.prefix}-${local.env}"
    managed_identity_api = "id-${local.prefix}-api-${local.env}"
  }
}
