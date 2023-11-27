data "aws_ec2_instance_type" "this" {
  instance_type = trim(var.instance_class, "db.")
}

module "cw_alerts" {
  count = var.sns_topic != null ? 1 : 0

  source  = "dasmeta/monitoring/aws//modules/alerts"
  version = "1.3.5"

  sns_topic = var.sns_topic

  alerts = [
    {
      name   = "RDS ${var.identifier} CPUUtilization"
      source = "AWS/RDS/CPUUtilization"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      statistic = try(var.alarms.cpu.statistic, "avg")
      threshold = try(var.alarms.cpu.threshold, "90") # percent
      period    = try(var.alarms.cpu.period, "300")
    },
    {
      name   = "RDS ${var.identifier} BurstBalance"
      source = "AWS/RDS/BurstBalance"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.burstbalance.period, "1800")
      threshold = try(var.alarms.burstbalance.threshold, "10") # percent
      equation  = try(var.alarms.burstbalance.equation, "lt")
      statistic = try(var.alarms.burstbalance.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} CPUCreditBalance"
      source = "AWS/RDS/CPUCreditBalance"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.cpu.creditbalance.period, "1800")
      threshold = try(var.alarms.cpu.creditbalance.threshold, "10") # percent
      equation  = try(var.alarms.cpu.creditbalance.equation, "lt")
      statistic = try(var.alarms.cpu.creditbalance.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} EBSByteBalance%"
      source = "AWS/RDS/EBSByteBalance%"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.ebs.bytebalance.period, "1800")
      threshold = try(var.alarms.ebs.bytebalance.threshold, "10") # percent
      equation  = try(var.alarms.ebs.bytebalance.equation, "lt")
      statistic = try(var.alarms.ebs.bytebalance.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} EBSIOBalance%"
      source = "AWS/RDS/EBSIOBalance%"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.ebs.IObalance.period, "1800")
      threshold = try(var.alarms.ebs.IObalance.threshold, "10") # percent
      equation  = try(var.alarms.ebs.IObalance.equation, "lt")
      statistic = try(var.alarms.ebs.IObalance.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} FreeableMemory"
      source = "AWS/RDS/FreeableMemory"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.memory.period, "1800")
      threshold = try(var.alarms.memory.threshold, data.aws_ec2_instance_type.this.memory_size * 0.2 * 1024 * 1024)
      equation  = try(var.alarms.memory.equation, "lt")
      statistic = try(var.alarms.memory.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} ReadLatency"
      source = "AWS/RDS/ReadLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.network.read.period, "60")
      threshold = try(var.alarms.network.read.threshold, "1")
      equation  = try(var.alarms.network.read.equation, "gte")
      statistic = try(var.alarms.network.read.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} WriteLatency"
      source = "AWS/RDS/WriteLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.network.write.period, "60")
      threshold = try(var.alarms.network.write.threshold, "1")
      equation  = try(var.alarms.network.write.equation, "gte")
      statistic = try(var.alarms.network.write.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} DatabaseConnections"
      source = "AWS/RDS/DatabaseConnections"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      # considering https://aws.amazon.com/premiumsupport/knowledge-center/rds-mysql-max-connections/; expecting that only 80% of memory is used for PostgreSQL; warn at 80% connection usage
      period    = try(var.alarms.connections.period, "60")
      threshold = try(var.alarms.connections.threshold, min(ceil(data.aws_ec2_instance_type.this.memory_size * 0.8 * 0.8 * 1024 * 1024 / 9531392), 5000))
      statistic = try(var.alarms.connections.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} diskUsedPercent"
      source = "RDS/diskUsedPercent"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.disk.period, "300")
      threshold = try(var.alarms.disk.threshold, "90")
      statistic = try(var.alarms.disk.statistic, "avg")
    },
  ]

  depends_on = [
    module.db,
    aws_cloudwatch_log_metric_filter.rds_disk_metric
  ]
}

resource "aws_cloudwatch_log_metric_filter" "rds_disk_metric" {
  count = var.sns_topic != null ? 1 : 0

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
