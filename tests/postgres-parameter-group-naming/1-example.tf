# Validates parameter group naming: identifier + parameter_group_family (e.g. postgres17).
module "this" {
  source = "../.."

  engine            = "postgres"
  engine_version    = "17"
  identifier        = "identifier-name"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name     = "app"
  db_username = "postgres"
  db_password = "replace"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  create_db_parameter_group = true
  create_security_group     = false

  slow_queries = {
    enabled = false
  }

  alarms = {
    enabled   = false
    sns_topic = ""
  }

  skip_final_snapshot = true
  apply_immediately   = true
}
