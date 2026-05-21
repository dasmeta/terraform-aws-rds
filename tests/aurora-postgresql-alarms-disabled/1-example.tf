# Mirrors Aurora PostgreSQL workspaces (e.g. prod-keycloak-aurora) with alarms disabled.
# Plan must not read aws_db_instance using the cluster identifier.
module "this" {
  source = "../.."

  engine            = "aurora-postgresql"
  engine_version    = "17.7"
  instance_class    = "db.t4g.medium"
  identifier        = "prod-keycloak-aurora"
  allocated_storage = null

  db_name     = "keycloak"
  db_username = "keycloak"
  db_password = "replace"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  enforce_client_tls = true

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
  security_group_name   = "aurora-postgresql-alarms-disabled-sg"

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
