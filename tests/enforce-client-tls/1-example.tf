module "this" {
  source = "../.."

  engine         = "mariadb"
  engine_version = "11.4.4"
  identifier     = "dbdemo"
  db_name        = "devdata"
  db_username    = "userTerraform"
  db_password    = "**********" # set this password upon testing

  parameter_group_name = "rds-mariadb-11"
  vpc_id               = "vpc-0090b8e4ff88411cc"
  subnet_ids           = ["subnet-018b6ea90a71ae223", "subnet-0c7a12072e0fff04b"]
  enforce_client_tls   = true

  apply_immediately                      = true
  cloudwatch_log_group_retention_in_days = 90
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["audit"]

  create_security_group = false

  slow_queries = {
    enabled        = false
    query_duration = 1
  }

  alarms = {
    enabled   = false
    sns_topic = "Default"
  }

}
