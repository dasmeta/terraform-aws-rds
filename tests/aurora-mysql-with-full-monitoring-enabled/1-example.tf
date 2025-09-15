module "this" {
  source = "../.."

  engine              = "aurora-mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.medium"
  identifier          = "aurora-mysql-with-full-monitoring-enabled"
  db_name             = "testDb"
  db_username         = "testUser"
  db_password         = "<xxxxxxxxxxxxx>"
  allocated_storage   = null
  publicly_accessible = true
  skip_final_snapshot = true
  apply_immediately   = true

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  create_db_parameter_group = true
  parameters = [
    { "name" : "sql_mode", "value" : "NO_ENGINE_SUBSTITUTION" },
    { "name" : "character_set_server", "value" : "utf8mb4", context = "cluster" },
    { "name" : "collation_server", "value" : "utf8mb4_general_ci", context = "cluster" },
    { "name" : "event_scheduler", "value" : "ON", context = "cluster" }
  ]

  create_security_group = true
  security_group_name   = "test-basic-aurora-mysql-sg"

  # enable full monitoring(this enables performance insights, error/audit/slow-query logs and enable performance_schema/innodb_print_all_deadlocks params )
  enable_full_monitoring = true

  aurora_configs = {
    instances = { # at least one master instance needs to be created
      master = {}
    }
    autoscaling = {
      enabled      = true
      min_capacity = 1
      max_capacity = 2
    }
  }

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
