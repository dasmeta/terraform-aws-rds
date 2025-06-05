module "this" {
  source = "../.."

  engine         = "aurora-postgresql"
  engine_version = "16.8"
  instance_class = "db.t3.medium"
  identifier     = "dbdemo"
  # db_name           = "devdata"
  # db_username       = "userTerraform"
  # db_password       = "**********" # set this password upon testing
  allocated_storage = null

  parameter_group_name = "aurora-postgres-16"
  vpc_id               = data.aws_vpc.default.id
  subnet_ids           = data.aws_subnets.default.ids
  enforce_client_tls   = true

  skip_final_snapshot   = true
  apply_immediately     = true
  create_security_group = false

  # replication_source_identifier = "arn:aws:rds:us-east-2:774305617028:db:database-2-test"

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

  slow_queries = {
    enabled        = false
    query_duration = 1
  }

  alarms = {
    enabled   = false
    sns_topic = "Default"
  }

}
