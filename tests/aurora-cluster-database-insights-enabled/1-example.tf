# NOTE: there is better way to enable cluster monitoring via var.enable_full_monitoring=true passing, which sets all needed params
module "this" {
  source = "../.."

  engine              = "aurora-mysql"
  engine_version      = "8.0"
  instance_class      = "db.t4g.medium" // performance insights do not support t2, t3 instance types. at least r-series or t4g instances should be used
  identifier          = "test-aurora-cluster-database-insights-enabled"
  db_name             = "testDb"
  db_username         = "testUser"
  db_password         = "<xxxxxxxxxxxxx>"
  allocated_storage   = null
  publicly_accessible = false
  skip_final_snapshot = true
  apply_immediately   = true
  enforce_client_tls  = false
  storage_encrypted   = false

  vpc_id     = data.aws_vpcs.default.ids[0]
  subnet_ids = data.aws_subnets.default.ids

  create_db_parameter_group = true
  parameters = [
    { "name" : "sql_mode", "value" : "NO_ENGINE_SUBSTITUTION" },
    { "context" : "cluster", "name" : "sql_mode", "value" : "NO_ENGINE_SUBSTITUTION" },
    { "apply_method" : "pending-reboot", "context" : "cluster", "name" : "read_only", "value" : "0" },
    { "context" : "cluster", "name" : "character_set_server", "value" : "utf8mb4" },
    { "context" : "cluster", "name" : "collation_server", "value" : "utf8mb4_general_ci" },
    { "context" : "cluster", "name" : "event_scheduler", "value" : "ON" },
    { "context" : "cluster", "name" : "net_read_timeout", "value" : "300" },
    { "context" : "cluster", "name" : "net_write_timeout", "value" : "300" },
    { "apply_method" : "pending-reboot", "context" : "cluster", "name" : "enforce_gtid_consistency", "value" : "ON" },
    { "apply_method" : "pending-reboot", "context" : "cluster", "name" : "gtid-mode", "value" : "ON" },
    { "apply_method" : "pending-reboot", "name" : "performance_schema", "value" : "1" },
    { "apply_method" : "pending-reboot", "context" : "cluster", "name" : "performance_schema", "value" : "1" }
  ]


  # enable slow query and error logs
  slow_queries = { "enabled" : false, "query_duration" : 1 }

  # enable performance insights and logging
  create_cloudwatch_log_group = true
  enabled_cloudwatch_logs_exports = [ # have errors/slowquery enabled for deadlocks and row locks queries identification
    "audit",
    "error",
    "general",
    "iam-db-auth-error",
    "instance",
    "slowquery",
  ]
  database_insights_mode                = "advanced"
  performance_insights_enabled          = true
  performance_insights_retention_period = 465
  monitoring_interval                   = 60
  create_monitoring_role                = true

  create_security_group = true
  security_group_name   = "aurora-cluster-database-insights-enabled-sg"

  aurora_configs = {
    instances = { # at least one master instance needs to be created
      master = {

      }
      # replica = {}
    }
    # autoscaling = {
    #   enabled      = true
    #   min_capacity = 0
    #   max_capacity = 0
    # }
  }

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
