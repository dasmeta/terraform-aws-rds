# Aurora PostgreSQL with alarms enabled must not use aws_db_instance lookup.
module "this" {
  source = "../.."

  engine            = "aurora-postgresql"
  engine_version    = "17.7"
  instance_class    = "db.t4g.medium"
  identifier        = "aurora-postgresql-alarms-enabled"
  allocated_storage = 100

  db_name     = "testDb"
  db_username = "testUser"
  db_password = "replace"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  aurora_configs = {
    instances = {
      master = {}
    }
  }

  slow_queries = {
    enabled = false
  }

  skip_final_snapshot   = true
  apply_immediately     = true
  create_security_group = true
  security_group_name   = "aurora-postgresql-alarms-enabled-sg"

  alarms = {
    enabled   = true
    sns_topic = "arn:aws:sns:eu-central-1:000000000000:example"
  }
}
