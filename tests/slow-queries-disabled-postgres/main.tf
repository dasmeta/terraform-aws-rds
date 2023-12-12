module "rds" {
  source = "../.."

  engine         = "postgres"
  engine_version = "12"
  identifier     = "test-db"
  db_name        = "test"
  db_username    = "userTerraform"
  db_password    = "password-terraform"

  slow_queries = {
    enabled = false
  }

  vpc_id     = "vpc-046effd7e14742653"
  subnet_ids = ["subnet-08b19374efcede225", "subnet-01fd8508db302e82c", "subnet-0af7c75104c35cbde"]

  create_security_group = false
  alarms = {
    enabled   = true
    sns_topic = "sns-topic-name"
  }
}
