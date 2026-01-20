module "cloudwatch_metric_filters" {
  source  = "dasmeta/monitoring/aws//modules/cloudwatch-log-based-metrics"
  version = "1.20.1"

  for_each = local.cloudwatch_log_groups

  log_group_name = each.value
  metrics_patterns = [
    {
      name    = "${var.identifier}-RDSSlowQueries"
      pattern = var.engine == "postgres" ? "[day, time, log=\"*:LOG:\", containsDuration=\"duration:\", duration=*, unit, statement=\"statement:*\"]" : "[start, time=\"Time:\", date, separatorOne, userHost, username, separatorTwo, ip, id, idNumber, separatorThree, queryTime, duration, ...]"
      value   = "$duration"
      unit    = var.engine == "postgres" ? "Milliseconds" : "Seconds"
    }
  ]
  metrics_namespace = "RDSLogBasedMetrics"

  depends_on = [
    module.db_aurora,
    module.db
  ]
}
