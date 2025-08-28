module "this" {
  source = "../.."

  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.medium"
  identifier          = "test-instance-performance-insights-enabled"
  db_name             = "testDb"
  db_username         = "testUser"
  db_password         = "<xxxxxxxxxxxxx>"
  publicly_accessible = true # make it publicly accessible to test performance insights

  vpc_id     = data.aws_vpcs.default.ids[0]
  subnet_ids = data.aws_subnets.default.ids

  create_security_group     = false
  create_db_parameter_group = true
  parameters = [
    { "name" : "sql_mode", "value" : "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" },
    { "name" : "character_set_server", "value" : "utf8mb4" },
    { "name" : "collation_server", "value" : "utf8mb4_general_ci" },
    { "name" : "innodb_print_all_deadlocks", "value" : "1", context = "cluster" }
  ]

  # enable slow query and error logs(this is main point where we enable performance insights)
  database_insights_mode                = "standard"
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  slow_queries                          = { "enabled" : true, "query_duration" : 1 }
  create_cloudwatch_log_group           = true
  enabled_cloudwatch_logs_exports = [ # have errors/slowquery/audit/general/iam-db-auth-error enabled for deadlocks and row locks queries identification
    "slowquery",                      # slowquery enabling works ok , rest option do not get impact. TODO: check and verify
    "audit",
    "error",
    "general",
    "iam-db-auth-error"
  ]

  skip_final_snapshot = true
  apply_immediately   = true
  allocated_storage   = 5


  alarms = {
    enabled   = false
    sns_topic = "Default"
  }
}
