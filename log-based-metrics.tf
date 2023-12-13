module "cloudwatch_metric_filters" {
  source  = "dasmeta/monitoring/aws//modules/cloudwatch-log-based-metrics"
  version = "1.13.2"

  for_each = local.cloudwatch_log_groups

  log_group_name = each.value
  metrics_patterns = [
    {
      name    = "${var.identifier}-RDSSlowQueries"
      pattern = "[day, time, log=\"*:LOG:\", containsDuration=\"duration:\", duration=*, unit, statement=\"statement:*\"]"
      value   = "$duration"
      unit    = "Milliseconds"
    }
  ]
  metrics_namespace = "RDSLogBasedMetrics"
}
