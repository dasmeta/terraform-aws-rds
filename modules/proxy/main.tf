module "db_password" {
  source  = "dasmeta/modules/aws//modules/secret"
  version = "2.18.2"

  count = var.credentials_secret_arn == null ? 1 : 0

  name                    = "db-password-${var.name}"
  recovery_window_in_days = var.credentials_secret_recovery_window
  value = {
    username = var.db_username
    password = var.db_password
  }
}

module "this" {
  source  = "terraform-aws-modules/rds-proxy/aws"
  version = "3.1.0"

  name                   = var.name
  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  debug_logging          = var.debug_logging
  idle_client_timeout    = var.idle_client_timeout

  endpoints = { for key, item in var.endpoints : key => merge(item, {
    name                   = key
    vpc_subnet_ids         = var.subnet_ids
    vpc_security_group_ids = var.vpc_security_group_ids
    })
  }

  auth = {
    "superuser" = {
      client_password_auth_type = var.client_auth_type
      iam_auth                  = var.iam_auth
      secret_arn                = try(module.db_password[0].secret_id, var.credentials_secret_arn)
    }
  }

  engine_family         = var.engine_family
  target_db_cluster     = var.target_db_cluster
  db_cluster_identifier = coalesce(var.db_cluster_identifier, var.name)

  tags = var.tags

  depends_on = [
    module.db_password
  ]
}
