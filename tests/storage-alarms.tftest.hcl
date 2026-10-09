mock_provider "aws" {
  mock_data "aws_ec2_instance_type" {
    defaults = { memory_size = 8192 }
  }
  mock_data "aws_db_instance" {
    defaults = { allocated_storage = 100 }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "000000000000" }
  }
  mock_data "aws_region" {
    defaults = { name = "eu-central-1" }
  }
}

override_module {
  target = module.db
}

override_module {
  target = module.db_aurora
  outputs = {
    cluster_endpoint = "example.cluster-test.eu-central-1.rds.amazonaws.com"
  }
}

variables {
  identifier            = "example"
  engine                = "aurora-postgresql"
  engine_version        = "15.12"
  instance_class        = "db.t4g.medium"
  allocated_storage     = null
  subnet_ids            = ["subnet-example"]
  create_security_group = false
  slow_queries          = { enabled = false }
  aurora_configs        = { instances = { master = {}, reader = {} } }
  alarms                = { sns_topic = "example" }
}

run "aurora_uses_local_storage" {
  command = plan

  assert {
    condition     = contains(keys(module.cw_alerts[0].alert_data.metric-alarms), "DB: Low Free Storage Space on Cluster example-AWS/RDS/FreeLocalStorage")
    error_message = "Aurora must create a FreeLocalStorage alarm rather than the unsupported FreeStorageSpace alarm."
  }

  assert {
    condition = (
      local.storage_alarm.filters.DBClusterIdentifier == "example" &&
      length(local.storage_alarm.filters) == 1 &&
      local.storage_alarm.statistic == "min" &&
      local.storage_alarm.threshold == 5368709120 &&
      local.storage_alarm.period == "300" &&
      local.storage_alarm.equation == "lte"
    )
    error_message = "Aurora must measure the least-free cluster member against the 5 GiB local-storage baseline."
  }

  assert {
    condition     = length(module.cw_alerts[0].alert_data.metric-alarms) == 8
    error_message = "Aurora must preserve all seven non-storage metric alarms."
  }
}

run "aurora_mysql_uses_local_storage" {
  command = plan
  variables {
    engine         = "aurora-mysql"
    engine_version = "8.0.mysql_aurora.3.10.0"
  }
  assert {
    condition     = contains(keys(module.cw_alerts[0].alert_data.metric-alarms), "DB: Low Free Storage Space on Cluster example-AWS/RDS/FreeLocalStorage")
    error_message = "Provisioned Aurora MySQL must also use local storage."
  }
}

run "disk_overrides_are_preserved" {
  command = plan
  variables {
    alarms = {
      sns_topic = "example"
      custom_values = {
        disk = { threshold = 2147483648, period = "600", equation = "lt", statistic = "avg" }
      }
    }
  }
  assert {
    condition = (
      local.storage_alarm.threshold == 2147483648 &&
      local.storage_alarm.period == "600" &&
      local.storage_alarm.equation == "lt" &&
      local.storage_alarm.statistic == "avg"
    )
    error_message = "All existing disk overrides must keep precedence."
  }
}

run "standalone_preserves_allocated_storage_alarm" {
  command = plan
  variables {
    engine            = "postgres"
    allocated_storage = 20
  }
  assert {
    condition = (
      contains(keys(module.cw_alerts[0].alert_data.metric-alarms), "DB: Low Free Storage Space on Instance example-AWS/RDS/FreeStorageSpace") &&
      local.storage_alarm.filters.DBInstanceIdentifier == "example" &&
      length(local.storage_alarm.filters) == 1 &&
      local.storage_alarm.statistic == "avg" &&
      abs(local.storage_alarm.threshold - 8589934592) < 1 &&
      length(module.cw_alerts[0].alert_data.metric-alarms) == 9
    )
    error_message = "Standalone RDS must retain FreeStorageSpace, Average and 8% of actual allocated storage (100 GiB mocked), plus EBS balance."
  }
}

run "disabled_aurora_has_no_alarms" {
  command = plan
  variables {
    alarms = { enabled = false, sns_topic = "" }
  }
  assert {
    condition     = length(module.cw_alerts) == 0 && length(data.aws_db_instance.database) == 0
    error_message = "Disabled Aurora alarms must not create alarms or a standalone DB lookup."
  }
}

run "disabled_standalone_has_no_alarms" {
  command = plan
  variables {
    engine            = "postgres"
    allocated_storage = null
    alarms            = { enabled = false, sns_topic = "" }
  }
  assert {
    condition     = length(module.cw_alerts) == 0 && length(data.aws_db_instance.database) == 0
    error_message = "Disabled standalone alarms must not index an absent DB lookup, even with null storage."
  }
}

run "serverless_v1_omits_unsupported_disk_alarm" {
  command = plan
  variables {
    aurora_configs = { engine_mode = "serverless", instances = {} }
  }
  assert {
    condition     = length(module.cw_alerts[0].alert_data.metric-alarms) == 7
    error_message = "Serverless v1 must omit only the unsupported local-storage alarm."
  }
}

run "serverless_v2_default_class_omits_disk_alarm" {
  command = plan
  variables {
    instance_class = "db.serverless"
  }
  assert {
    condition     = length(module.cw_alerts[0].alert_data.metric-alarms) == 7
    error_message = "Serverless-only v2 clusters inheriting the root class must omit local-storage alarms."
  }
}

run "serverless_member_overrides_omit_disk_alarm" {
  command = plan
  variables {
    aurora_configs = {
      instances = { master = { instance_class = "db.serverless" }, reader = { instance_class = "db.serverless" } }
    }
  }
  assert {
    condition     = length(module.cw_alerts[0].alert_data.metric-alarms) == 7
    error_message = "Member class overrides must determine local-storage support."
  }
}

run "mixed_members_keep_provisioned_storage_alarm" {
  command = plan
  variables {
    instance_class = "db.serverless"
    aurora_configs = {
      instances = { master = { instance_class = "db.t4g.medium" }, reader = {} }
    }
  }
  assert {
    condition     = contains(keys(module.cw_alerts[0].alert_data.metric-alarms), "DB: Low Free Storage Space on Cluster example-AWS/RDS/FreeLocalStorage")
    error_message = "A provisioned member must keep local-storage coverage even when the root class is serverless."
  }
}

run "autoscaling_keeps_cluster_storage_alarm" {
  command = plan
  variables {
    aurora_configs = {
      instances   = { master = {} }
      autoscaling = { enabled = true, min_capacity = 1, max_capacity = 2 }
    }
  }
  assert {
    condition     = local.storage_alarm.filters.DBClusterIdentifier == "example" && length(local.storage_alarm.filters) == 1 && local.storage_alarm.statistic == "min" && length(module.cw_alerts[0].alert_data.metric-alarms) == 8
    error_message = "Autoscaled readers must use the cluster Minimum storage alarm."
  }
}
