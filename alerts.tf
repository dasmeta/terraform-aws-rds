data "aws_ec2_instance_type" "this" {
  instance_type = trim(var.instance_class, "db.")
}

module "cw_alerts" {
  count = var.alarms.enabled ? 1 : 0

  source  = "dasmeta/monitoring/aws//modules/alerts"
  version = "1.3.5"

  sns_topic = var.alarms.sns_topic

  alerts = [
    {
      name   = "RDS ${var.identifier} CPUUtilization"
      source = "AWS/RDS/CPUUtilization"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      statistic = try(var.alarms.custom-values.cpu.statistic, "avg")
      threshold = try(var.alarms.custom-values.cpu.threshold, "90") # percent
      period    = try(var.alarms.custom-values.cpu.period, "300")
    },
    {
      name   = "RDS ${var.identifier} EBSIOBalance%"
      source = "AWS/RDS/EBSIOBalance%"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom-values.ebs.IObalance.period, "1800")
      threshold = try(var.alarms.custom-values.ebs.IObalance.threshold, "10") # percent
      equation  = try(var.alarms.custom-values.ebs.IObalance.equation, "lt")
      statistic = try(var.alarms.custom-values.ebs.IObalance.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} FreeableMemory"
      source = "AWS/RDS/FreeableMemory"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom-values.memory.period, "1800")
      threshold = try(var.alarms.custom-values.memory.threshold, data.aws_ec2_instance_type.this.memory_size * 0.2 * 1024 * 1024)
      equation  = try(var.alarms.custom-values.memory.equation, "lt")
      statistic = try(var.alarms.custom-values.memory.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} ReadLatency"
      source = "AWS/RDS/ReadLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom-values.network.read.period, "60")
      threshold = try(var.alarms.custom-values.network.read.threshold, "1")
      equation  = try(var.alarms.custom-values.network.read.equation, "gte")
      statistic = try(var.alarms.custom-values.network.read.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} WriteLatency"
      source = "AWS/RDS/WriteLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom-values.network.write.period, "60")
      threshold = try(var.alarms.custom-values.network.write.threshold, "1")
      equation  = try(var.alarms.custom-values.network.write.equation, "gte")
      statistic = try(var.alarms.custom-values.network.write.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} DatabaseConnections"
      source = "AWS/RDS/DatabaseConnections"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      # considering https://aws.amazon.com/premiumsupport/knowledge-center/rds-mysql-max-connections/; expecting that only 80% of memory is used for PostgreSQL; warn at 80% connection usage
      period    = try(var.alarms.custom-values.connections.period, "60")
      threshold = try(var.alarms.custom-values.connections.threshold, min(ceil(data.aws_ec2_instance_type.this.memory_size * 0.8 * 0.8 * 1024 * 1024 / 9531392), 5000))
      statistic = try(var.alarms.custom-values.connections.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} diskUsedPercent"
      source = "RDS/diskUsedPercent"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom-values.disk.period, "300")
      threshold = try(var.alarms.custom-values.disk.threshold, "90")
      statistic = try(var.alarms.custom-values.disk.statistic, "avg")
    },
  ]

  depends_on = [
    module.db,
    aws_cloudwatch_log_metric_filter.rds_disk_metric
  ]
}

resource "aws_cloudwatch_log_metric_filter" "rds_disk_metric" {
  count = var.alarms.enabled ? 1 : 0

  name           = "filter-${var.identifier}-disk"
  pattern        = "{$.instanceID = \"${var.identifier}\" && $.fileSys[0].mountPoint = \"/rdsdbdata\"}"
  log_group_name = "RDSOSMetrics"

  metric_transformation {
    name      = "diskUsedPercent"
    namespace = "RDS"
    unit      = "Percent"
    value     = "$.fileSys[0].usedPercent"
    dimensions = {
      DBInstanceIdentifier = "$.instanceID"
    }
  }

  depends_on = [
    module.db
  ]
}
