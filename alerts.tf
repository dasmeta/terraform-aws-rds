data "aws_ec2_instance_type" "this" {
  instance_type = trim(var.instance_class, "db.")
}

data "aws_db_instance" "database" {
  db_instance_identifier = var.identifier

  depends_on = [
    module.db
  ]
}

locals {
  // SampleCount statistic adds 2 to the real count in case the engine is postgres, so 7 means 5 + 2
  slow_queries_alert_threshold = var.engine == "postgres" ? 7 : 5
}

module "cw_alerts" {
  count = var.alarms.enabled ? 1 : 0

  source  = "dasmeta/monitoring/aws//modules/alerts"
  version = "1.3.5"

  sns_topic = var.alarms.sns_topic

  alerts = concat([
    {
      name   = "RDS ${var.identifier} CPUUtilization"
      source = "AWS/RDS/CPUUtilization"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      statistic = try(var.alarms.custom_values.cpu.statistic, "avg")
      threshold = try(var.alarms.custom_values.cpu.threshold, "90") # percent
      period    = try(var.alarms.custom_values.cpu.period, "300")
    },
    {
      name   = "RDS ${var.identifier} EBSIOBalance%"
      source = "AWS/RDS/EBSIOBalance%"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.ebs.IObalance.period, "1800")
      threshold = try(var.alarms.custom_values.ebs.IObalance.threshold, "10") # percent
      equation  = try(var.alarms.custom_values.ebs.IObalance.equation, "lt")
      statistic = try(var.alarms.custom_values.ebs.IObalance.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} FreeableMemory"
      source = "AWS/RDS/FreeableMemory"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.memory.period, "1800")
      threshold = try(var.alarms.custom_values.memory.threshold, data.aws_ec2_instance_type.this.memory_size * 0.2 * 1024 * 1024)
      equation  = try(var.alarms.custom_values.memory.equation, "lt")
      statistic = try(var.alarms.custom_values.memory.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} ReadLatency"
      source = "AWS/RDS/ReadLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.network.read.period, "60")
      threshold = try(var.alarms.custom_values.network.read.threshold, "1")
      equation  = try(var.alarms.custom_values.network.read.equation, "gte")
      statistic = try(var.alarms.custom_values.network.read.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} WriteLatency"
      source = "AWS/RDS/WriteLatency"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.network.write.period, "60")
      threshold = try(var.alarms.custom_values.network.write.threshold, "1")
      equation  = try(var.alarms.custom_values.network.write.equation, "gte")
      statistic = try(var.alarms.custom_values.network.write.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} DatabaseConnections"
      source = "AWS/RDS/DatabaseConnections"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      # considering https://aws.amazon.com/premiumsupport/knowledge-center/rds-mysql-max-connections/; expecting that only 80% of memory is used for PostgreSQL; warn at 80% connection usage
      period    = try(var.alarms.custom_values.connections.period, "60")
      threshold = try(var.alarms.custom_values.connections.threshold, min(ceil(data.aws_ec2_instance_type.this.memory_size * 0.8 * 0.8 * 1024 * 1024 / 9531392), 5000))
      statistic = try(var.alarms.custom_values.connections.statistic, "avg")
    },
    {
      name   = "RDS ${var.identifier} FreeStorageSpace"
      source = "AWS/RDS/FreeStorageSpace"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.disk.period, "300")
      threshold = try(var.alarms.custom_values.disk.threshold, data.aws_db_instance.database.allocated_storage * 0.2)
      equation  = try(var.alarms.custom_values.disk.equation, "lt")
      statistic = try(var.alarms.custom_values.disk.statistic, "avg")
    },
    ],
    // This will get into in alarm state in case there are 5 slow queries in 5 minutes
    var.slow_queries.enabled ? [
      {
        name      = "RDS ${var.identifier} SlowQueries"
        source    = "RDSLogBasedMetrics/${var.identifier}-RDSSlowQueries"
        filters   = {}
        period    = try(var.alarms.custom_values.slow-queries.period, "300")
        threshold = try(var.alarms.custom_values.slow-queries.threshold, local.slow_queries_alert_threshold)
        equation  = try(var.alarms.custom_values.slow-queries.equation, "gte")
        statistic = try(var.alarms.custom_values.slow-queries.statistic, "count")
      }
    ] : []
  )

  depends_on = [
    module.db
  ]
}
