module "this" {
  source = "../.."

  engine            = "aurora-postgresql"
  engine_version    = "17.7"
  instance_class    = "db.t4g.medium"
  identifier        = "aurora-postgresql-full-monitoring"
  allocated_storage = null

  db_name     = "testDb"
  db_username = "testUser"
  db_password = "replace"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  enforce_client_tls     = true
  enable_full_monitoring = true

  aurora_configs = {
    instances = {
      master = {}
    }
  }

  slow_queries = {
    enabled        = false
    query_duration = 1
  }

  skip_final_snapshot   = true
  apply_immediately     = true
  create_security_group = true
  security_group_name   = "aurora-postgresql-full-monitoring-sg"

  alarms = {
    enabled   = false
    sns_topic = "Default"
  }
}
