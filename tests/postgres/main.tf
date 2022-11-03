locals {
  vpc_id     = "vpc-0f9024016547dc75e"
  subnet_ids = ["subnet-0d2c0c2cd13a1b8a6", "subnet-0beb63243a61167f4", "subnet-0c3791c28475daa2f"]
  #   infra_secret_accesses = jsondecode(data.aws_secretsmanager_secret_version.infra_secret_accesses.secret_string)
}

module "rds" {
  source = "/Users/Vika/Documents/projects/terraform-aws-rds"
  # source         = "dasmeta/rds/aws"
  # version        = "1.0.0"
  engine         = "postgres"
  engine_version = "12"
  identifier     = "quantistry-dev"
  db_name        = "quantistry"
  db_username    = "user-terraform"
  db_password    = "password-terraform"
  #   db_name              = local.infra_secret_accesses["POSTGRES_DB"]
  #   db_username          = local.infra_secret_accesses["POSTGRES_USER"]
  #   db_password          = local.infra_secret_accesses["POSTGRES_PASSWORD"]
  parameter_group_name = "rds-pg-12"
  vpc_id               = local.vpc_id
  subnet_ids           = local.subnet_ids

  create_security_group = false
  #   ingress_with_cidr_blocks = [
  #     {
  #       description = "3306 from VPC"
  #       from_port   = 3306
  #       to_port     = 3306
  #       protocol    = "tcp"
  #       cidr_blocks = "${data.aws_vpc.main.cidr_block}"
  #   }]

  #   egress_with_cidr_blocks = [
  #     {
  #       from_port   = 0
  #       to_port     = 0
  #       protocol    = "-1"
  #       cidr_blocks = "[0.0.0.0/0]"
  #   }]
}
