module "database" {
  source = "../.."

  identifier                  = "example"
  engine                      = "postgres"
  engine_version              = "17"
  instance_class              = "db.t3.small"
  db_username                 = "example"
  manage_master_user_password = true
  subnet_ids                  = var.subnet_ids
  create_security_group       = false
  vpc_security_group_ids      = var.security_group_ids

  # Count completed statements taking at least three seconds.
  slow_queries = { query_duration = 3 }

  # Defaults alert on five qualifying queries in five minutes using Sum.
  alarms = { sns_topic = var.sns_topic }
}
