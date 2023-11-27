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
      statistic = "avg"
      threshold = "90"
    },
    {
      name   = "RDS ${var.identifier} BurstBalance"
      source = "AWS/RDS/BurstBalance"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = "1800"
      threshold = "10" # percent
      equation  = "lt"
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} CPUCreditBalance"
      source = "AWS/RDS/CPUCreditBalance"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = "1800"
      threshold = "10" # percent
      equation  = "lt"
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} EBSByteBalance%"
      source = "AWS/RDS/EBSByteBalance%"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = "1800"
      threshold = "10" # percent
      equation  = "lt"
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} EEBSIOBalance%"
      source = "AWS/RDS/EBSIOBalance%"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = "1800"
      threshold = "10" # percent
      equation  = "lt"
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} FreeableMemory"
      source = "AWS/RDS/FreeableMemory"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = "1800"
      threshold = data.aws_ec2_instance_type.this.memory_size * 0.2 * 1024 * 1024 # bytes
      equation  = "lt"
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} ReadLatency"
      source = "AWS/RDS/ReadLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = "60"
      threshold = "1"
      equation  = "gte"
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} WriteLatency"
      source = "AWS/RDS/WriteLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = "60"
      threshold = "1"
      equation  = "gte"
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} DatabaseConnections"
      source = "AWS/RDS/DatabaseConnections"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period = "60"
      # considering https://aws.amazon.com/premiumsupport/knowledge-center/rds-mysql-max-connections/; expecting that only 80% of memory is used for PostgreSQL; warn at 80% connection usage
      threshold = min(ceil(data.aws_ec2_instance_type.this.memory_size * 0.8 * 0.8 * 1024 * 1024 / 9531392), 5000) # count
      statistic = "avg"
    },
    {
      name   = "RDS ${var.identifier} diskUsedPercent"
      source = "RDS/diskUsedPercent"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      threshold = "90"
      statistic = "avg"
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
