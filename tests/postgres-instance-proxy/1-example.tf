module "this" {
  source = "../.."

  engine         = "postgres"
  engine_version = "16"
  identifier     = "dbdemo"
  db_name        = "devdata"
  db_username    = "userTerraform"
  db_password    = "**********" # set this password upon testing

  vpc_id     = "vpc-0ad800f71d2414808"
  subnet_ids = ["subnet-0e5bb6f69f7ab86e2", "subnet-0e2cb8c97b60b76fd"]

  apply_immediately                      = true
  cloudwatch_log_group_retention_in_days = 90
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["postgresql"]

  create_security_group = false

  alarms = {
    enabled   = false
    sns_topic = "Default"
  }

  proxy = {
    enabled           = true # First create only the rds, then the proxy
    client_auth_type  = "POSTGRES_MD5"
    target_db_cluster = false
  }
}
