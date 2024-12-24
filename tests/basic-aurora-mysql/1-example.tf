module "this" {
  source = "../.."

  engine              = "aurora-mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.medium"
  identifier          = "test-basic-aurora-mysql"
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

  slow_queries = { "enabled" : false, "query_duration" : 1 }

  create_security_group = true
  security_group_name   = "test-basic-aurora-mysql-sg"

  aurora_configs = {
    autoscaling_enabled      = true
    autoscaling_min_capacity = 1
    autoscaling_max_capacity = 2

    instances = { # at least one master instance needs to be created
      master = {}
    }
  }

  proxy = {
    enabled = false
  }

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
