module "this" {
  source = "../.."

  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.medium"
  identifier        = "dbdemo"
  db_name           = "devdata"
  db_username       = "userTerraform"
  db_password       = "**********" # set this password upon testing
  allocated_storage = 20

  parameter_group_name = "postgresql-16"
  parameter_group_type = "instance"
  vpc_id               = "vpc-0090b8e4ff88411cc"
  subnet_ids           = ["subnet-018b6ea90a71ae223", "subnet-0c7a12072e0fff04b"]
  enforce_client_tls   = true

  skip_final_snapshot = true

  apply_immediately = true

  create_security_group = false

  slow_queries = {
    enabled        = false
    query_duration = 1
  }

  alarms = {
    enabled   = false
    sns_topic = "Default"
  }

}
