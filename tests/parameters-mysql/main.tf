module "rds" {
  source = "../.."

  engine         = "mysql"
  engine_version = "8.0"
  identifier     = "parameters-rds"
  db_name        = "test-with-parameters"
  db_username    = "userTerraform"
  db_password    = "password"

  vpc_id     = "vpc-046effd7e14742653"
  subnet_ids = ["subnet-08b19374efcede225", "subnet-01fd8508db302e82c", "subnet-0af7c75104c35cbde"]

  create_security_group     = false
  create_db_parameter_group = true
  parameters                = [{ "name" : "sql_mode", "value" : "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" }, { "name" : "character_set_server", "value" : "utf8mb4" }, { "name" : "collation_server", "value" : "utf8mb4_general_ci" }]

  slow_queries = { "enabled" : false, "query_duration" : 1 }

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
