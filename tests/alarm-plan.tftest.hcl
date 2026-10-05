# Keep real database resources in this plan so the deferred-data regression is exercised.
mock_provider "aws" {
  mock_data "aws_ec2_instance_type" {
    defaults = { memory_size = 8192 }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "000000000000" }
  }
  mock_data "aws_region" {
    defaults = { name = "eu-central-1" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
}
mock_provider "random" {}

variables {
  identifier                  = "example"
  engine                      = "aurora-postgresql"
  engine_version              = "15.12"
  instance_class              = "db.t4g.medium"
  allocated_storage           = null
  subnet_ids                  = ["subnet-example"]
  create_security_group       = false
  create_monitoring_role      = false
  monitoring_interval         = 0
  db_name                     = "example"
  db_username                 = "example"
  manage_master_user_password = true
  slow_queries                = { enabled = false }
  aurora_configs              = { instances = { master = {} } }
  alarms                      = { sns_topic = "example" }
}

run "alarm_account_is_known_with_pending_database" {
  command = plan
  assert {
    condition     = length(module.cw_alerts[0].alert_data.metric-alarms) == 8
    error_message = "The pending Aurora creation must preserve all eight metric alarms."
  }
}
