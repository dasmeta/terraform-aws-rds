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
  engine                = "postgres"
  engine_version        = "17"
  subnet_ids            = ["subnet-example"]
  create_security_group = false
  alarms                = { sns_topic = "example" }
}

run "postgres_counts_queries_not_duration_samples" {
  command = plan

  assert {
    condition = (
      local.slow_query_count_metric.name == "example-RDSSlowQueryCount" &&
      local.slow_query_count_metric.value == "1" &&
      local.slow_query_count_metric.default_value == "0" &&
      local.slow_query_count_metric.unit == "Count" &&
      strcontains(local.slow_query_count_metric.pattern, "duration >= 3000") &&
      strcontains(local.slow_query_count_metric.pattern, "execute*") &&
      local.slow_query_alarm.statistic == "sum" &&
      local.slow_query_alarm.threshold == 5 &&
      local.slow_query_alarm.period == "300" &&
      local.slow_query_alarm.equation == "gte"
    )
    error_message = "PostgreSQL must count qualifying statement/execute records and evaluate five real queries with Sum."
  }

  assert {
    condition = (
      contains(keys(module.cw_alerts[0].alert_data.metric-alarms), "DB: Excessive Slow Queries on Instance example-RDSLogBasedMetrics/example-RDSSlowQueryCount") &&
      !contains(keys(module.cw_alerts[0].alert_data.metric-alarms), "DB: Excessive Slow Queries on Instance example-RDSLogBasedMetrics/example-RDSSlowQueries") &&
      length(module.cw_alerts[0].alert_data.metric-alarms) == 10
    )
    error_message = "The actual alarm renderer must consume the count source and preserve the nine other standalone alarms."
  }
}

run "fractional_seconds_become_milliseconds" {
  command = plan
  variables {
    slow_queries = { query_duration = 1.5 }
  }
  assert {
    condition     = strcontains(local.slow_query_count_metric.pattern, "duration >= 1500")
    error_message = "The count predicate must use the configured query duration in milliseconds."
  }
}

run "mysql_counts_only_query_log_headers" {
  command = plan
  variables {
    engine         = "mysql"
    engine_version = "8.0"
  }
  assert {
    condition = (
      local.slow_query_count_log_type == "slowquery" &&
      strcontains(local.slow_query_count_metric.pattern, "Query_time:") &&
      local.slow_query_alarm.statistic == "sum" &&
      local.slow_query_alarm.threshold == 5 &&
      tonumber(local.slow_query_params_map.long_query_time.value) == var.slow_queries.query_duration
    )
    error_message = "MySQL must count slow-log headers under the configured server duration threshold."
  }
}

run "mariadb_counts_only_query_log_headers" {
  command = plan
  variables {
    engine         = "mariadb"
    engine_version = "10.11"
  }
  assert {
    condition     = local.slow_query_count_log_type == "slowquery" && strcontains(local.slow_query_count_metric.pattern, "Query_time:") && local.slow_query_alarm.threshold == 5
    error_message = "MariaDB must use the header count pattern despite different optional header lines."
  }
}

run "aurora_postgresql_uses_query_count" {
  command = plan
  variables {
    engine         = "aurora-postgresql"
    engine_version = "17.4"
  }
  assert {
    condition = (
      local.slow_query_count_log_type == "postgresql" &&
      local.slow_query_alarm.statistic == "sum" &&
      contains(keys(module.cw_alerts[0].alert_data.metric-alarms), "DB: Excessive Slow Queries on Cluster example-RDSLogBasedMetrics/example-RDSSlowQueryCount")
    )
    error_message = "Aurora PostgreSQL must retain the cluster alarm name while using query count."
  }
}

run "aurora_mysql_uses_query_count" {
  command = plan
  variables {
    engine         = "aurora-mysql"
    engine_version = "8.0.mysql_aurora.3.10.0"
  }
  assert {
    condition     = local.slow_query_count_log_type == "slowquery" && local.slow_query_alarm.statistic == "sum"
    error_message = "Aurora MySQL must count slow-log records too."
  }
}

run "explicit_overrides_keep_precedence" {
  command = plan
  variables {
    alarms = {
      sns_topic = "example"
      custom_values = {
        slow-queries = { threshold = 9, period = "600", equation = "gt", statistic = "max" }
      }
    }
  }
  assert {
    condition = (
      local.slow_query_alarm.threshold == 9 &&
      local.slow_query_alarm.period == "600" &&
      local.slow_query_alarm.equation == "gt" &&
      local.slow_query_alarm.statistic == "max"
    )
    error_message = "Explicit slow-query overrides must not be silently reset."
  }
}

run "disabled_slow_queries_create_no_filters_or_alarm" {
  command = plan
  variables {
    slow_queries = { enabled = false }
  }
  assert {
    condition     = length(module.cloudwatch_metric_filters) == 0 && length(module.cw_alerts[0].alert_data.metric-alarms) == 9
    error_message = "Disabled slow queries must create neither filters nor a slow-query alarm."
  }
}

run "disabled_alarms_keep_query_telemetry" {
  command = plan
  variables {
    alarms = { enabled = false, sns_topic = "" }
  }
  assert {
    condition     = length(module.cw_alerts) == 0 && contains(keys(module.cloudwatch_metric_filters), "postgresql")
    error_message = "Disabling alarms must preserve independently enabled log telemetry."
  }
}

run "auxiliary_log_exports_do_not_change_query_log_selection" {
  command = plan
  variables {
    enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  }
  assert {
    condition     = local.slow_query_count_log_type == "postgresql" && length(module.cloudwatch_metric_filters) == 2
    error_message = "Additional exports must preserve the existing duration filter instances and select only the query log for counting."
  }
}
