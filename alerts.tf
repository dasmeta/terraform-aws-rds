module "cw_alerts" {
  count = var.alarms.enabled ? 1 : 0

  source  = "dasmeta/monitoring/aws//modules/alerts"
  version = "1.20.1"

  sns_topic = var.alarms.sns_topic

  alerts = concat([
    {
      name   = "DB: High CPU Utilization Alert on Instance ${var.identifier}"
      source = "AWS/RDS/CPUUtilization"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      statistic = try(var.alarms.custom_values.cpu.statistic, "avg")
      threshold = try(var.alarms.custom_values.cpu.threshold, "90") # percent
      period    = try(var.alarms.custom_values.cpu.period, "300")
    },
    {
      name   = "DB: Low EBS IO Balance Percentage on Instance ${var.identifier}"
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
      name   = "DB: Low Freeable Memory Alert on Instance ${var.identifier}"
      source = "AWS/RDS/FreeableMemory"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.memory.period, "1800")
      threshold = try(var.alarms.custom_values.memory.threshold, data.aws_ec2_instance_type.this.memory_size * 0.05 * 1024 * 1024)
      equation  = try(var.alarms.custom_values.memory.equation, "lt")
      statistic = try(var.alarms.custom_values.memory.statistic, "avg")
    },
    {
      name   = "DB: High Read Latency Detected on Instance ${var.identifier}"
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
      name   = "DB: High Write Latency Detected on Instance ${var.identifier}"
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
      name   = "DB: High Database Connection Usage on Instance ${var.identifier}"
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
      name   = "DB: Low Free Storage Space on Instance ${var.identifier}"
      source = "AWS/RDS/FreeStorageSpace"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.disk.period, "300")
      threshold = try(var.alarms.custom_values.disk.threshold, data.aws_db_instance.database[0].allocated_storage * 0.08 * 1024 * 1024 * 1024) #8% of storage in Bytes
      equation  = try(var.alarms.custom_values.disk.equation, "lte")
      statistic = try(var.alarms.custom_values.disk.statistic, "avg")
    },
    {
      name   = "DB: High READ IOPS Utilization Alert on Instance ${var.identifier}"
      source = "AWS/RDS/ReadIOPS"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.iops.read.period, "900")
      threshold = try(var.alarms.custom_values.iops.read.threshold, "5000") # IOPS
      equation  = try(var.alarms.custom_values.iops.read.equation, "gte")
      statistic = try(var.alarms.custom_values.iops.read.statistic, "avg")
    },
    {
      name   = "DB: High WRITE IOPS Utilization Alert on Instance ${var.identifier}"
      source = "AWS/RDS/WriteIOPS"
      filters = {
        DBInstanceIdentifier = var.identifier
      }
      period    = try(var.alarms.custom_values.iops.write.period, "300")
      threshold = try(var.alarms.custom_values.iops.write.threshold, "3000") # IOPS
      equation  = try(var.alarms.custom_values.iops.write.equation, "gte")
      statistic = try(var.alarms.custom_values.iops.write.statistic, "avg")
    }
    ],
    // This will get into in alarm state in case there are 5 slow queries in 5 minutes
    local.slow_queries.enabled ? [
      {
        name      = "DB: Excessive Slow Queries on Instance ${var.identifier}"
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
