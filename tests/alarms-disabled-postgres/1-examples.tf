module "rds" {
  source = "../.."

  engine         = "postgres"
  engine_version = "12"
  identifier     = "dbdemo"
  db_name        = "devdata"
  db_username    = "userTerraform"
  db_password    = "password-terraform"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  apply_immediately                      = true
  cloudwatch_log_group_retention_in_days = 90
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["postgresql"]

  create_security_group = false

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
