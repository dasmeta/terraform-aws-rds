module "this" {
  source = "../.."

  engine            = "aurora-postgresql"
  engine_version    = "16"
  instance_class    = "db.t3.medium"
  identifier        = "dbdemo"
  db_name           = "devdata"
  db_username       = "userTerraform"
  db_password       = "**********" # set this password upon testing
  allocated_storage = null

  parameter_group_name = "aurora-mysql-8"
  vpc_id               = "vpc-0090b8e4ff88411cc"
  subnet_ids           = ["subnet-018b6ea90a71ae223", "subnet-0c7a12072e0fff04b"]
  enforce_client_tls   = true

  skip_final_snapshot   = true
  apply_immediately     = true
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
