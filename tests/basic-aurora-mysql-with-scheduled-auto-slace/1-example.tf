module "this" {
  source = "../.."

  engine              = "aurora-mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.medium"
  identifier          = "test-basic-aurora-with-scheduled-scale"
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
    { "name" : "character_set_server", "value" : "utf8mb4", context = "cluster" },
    { "name" : "collation_server", "value" : "utf8mb4_general_ci", context = "cluster" },
  ]

  slow_queries = { "enabled" : false, "query_duration" : 1 }

  create_security_group = true
  security_group_name   = "test-basic-aurora-with-scheduled-scale-sg"

  aurora_configs = {
    instances = { # at least one master instance needs to be created
      master = {}
    }
    autoscaling = {
      enabled      = true
      min_capacity = 1
      max_capacity = 2
      schedules = [
        {
          name         = "scale_down_daily"
          schedule     = "cron(00 22 * * ? *)" # every day at 22:00 scale down read replicas to 0
          min_capacity = 0
          max_capacity = 0
          timezone     = "Asia/Yerevan"
        },
        {
          name         = "scale_up_daily"
          schedule     = "cron(00 10 * * ? *)" # every day at 10:00 morning scale up read replicas min=1, max=2
          min_capacity = 1
          max_capacity = 2
          timezone     = "Asia/Yerevan"
        }
      ]
    }
  }

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
