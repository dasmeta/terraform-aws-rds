module "rds" {
  source = "dasmeta/rds/aws"

  engine         = "postgres"
  engine_version = "12"
  identifier     = "db-demo"
  db_name        = "dev-data"
  db_username    = "user-terraform"
  db_password    = "password-terraform"

  parameter_group_name = "rds-pg-12"
  vpc_id               = "vpc-122123fsf41414"
  subnet_ids           = ["subnet-231dadsa344ds", "subnet-231dqweqsa344ds", "subnet-241dadsa344ds"]

  create_security_group = false
}
