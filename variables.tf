variable "identifier" {
  type        = string
  description = "Specifies the identifier of the CA certificate for the DB instance"
}

variable "security_group_name" {
  type    = string
  default = "db_security_group"
}

variable "alarms" {
  type = object({
    enabled       = optional(bool, true)
    sns_topic     = string
    custom_values = optional(any, {})
  })
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible"
  type        = bool
  default     = false
}

variable "security_group_description" {
  type    = string
  default = "MySQL security group"
}

variable "tags" {
  type        = map(any)
  description = "A mapping of tags to assign to all resources"
  default     = {}
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of VPC security groups to associate"
  default     = []
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "ingress_with_cidr_blocks" {
  type    = list(map(string))
  default = []
}

variable "egress_with_cidr_blocks" {
  type    = list(map(string))
  default = []
}

variable "set_vpc_security_group_rules" {
  type        = bool
  default     = true
  description = "Whether to automatically add security group rules allowing access to db from vpc network"
}

variable "storage_type" {
  type        = string
  default     = null
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), gp3, or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'gp2' if not"
}

variable "engine" {
  type        = string
  default     = "mysql"
  description = "The database engine to use"
}

variable "engine_version" {
  type        = string
  default     = "5.7.26"
  description = "The engine version to use"
}

variable "major_engine_version" {
  type        = string
  default     = "5.7"
  description = "Specifies the major version of the engine that this option group should be associated with"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro" # for aurora-mysql>=3.x(mysql>=8.x) min instance class is "db.t3.medium", the performance insights for aurora can be enabled only r-series or t4g instances can be used, at least "db.t4g.medium". check the docs for supported instance classes: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.DBInstanceClass.SupportAurora.html
  description = "The instance type of the RDS instance"
}

variable "allocated_storage" {
  type        = number
  default     = 20
  description = "The allocated storage in gigabytes"
}

variable "max_allocated_storage" {
  type        = number
  default     = 100
  description = "Specifies the value for Storage Autoscaling"
}

variable "storage_encrypted" {
  type        = bool
  description = "Specifies whether the DB instance is encrypted"
  default     = true
}

variable "db_name" {
  type        = string
  description = "The DB name to create. If omitted, no database is created initially"
  default     = ""
}

variable "db_username" {
  type        = string
  description = "Username for the master DB user"
  default     = ""
}

variable "db_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file"
}

variable "port" {
  type        = number
  default     = null
  description = "The port on which the DB accepts connections"
}

variable "multi_az" {
  type        = bool
  default     = true
  description = "Specifies if the RDS instance is multi-AZ"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of VPC subnet IDs"
}

variable "iam_database_authentication_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether or not the mappings of AWS Identity and Access Management (IAM) accounts to database accounts are enabled"
}

variable "maintenance_window" {
  type        = string
  default     = "Mon:01:00-Mon:02:00"
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
}

variable "backup_window" {
  type        = string
  default     = "03:00-06:00"
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window"
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = []
  description = "List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL)"
}

variable "backup_retention_period" {
  type        = number
  default     = 35
  description = "The days to retain backups for"
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted"
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "The database can't be deleted when this value is set to true"
}

variable "create_monitoring_role" {
  type        = bool
  default     = false
  description = "Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
}

variable "monitoring_interval" {
  type        = number
  default     = 0
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60"
}

variable "monitoring_role_name" {
  type        = string
  default     = null
  description = "Name of the IAM role which will be created when create_monitoring_role is enabled"
}

variable "parameters" {
  type = list(object({
    name         = string
    value        = string
    context      = optional(string, "instance")  # The context where parameter will be used, supported values are "instance" and "cluster"
    apply_method = optional(string, "immediate") # The apply method for parameter, supported values are "immediate" and "pending-reboot"
  }))
  default     = []
  description = "A list of DB parameters (map) to apply"
}

variable "options" {
  type = list(any)
  default = [{
    option_name = "MARIADB_AUDIT_PLUGIN"

    option_settings = [
      {
        name  = "SERVER_AUDIT_EVENTS"
        value = "CONNECT"
      },
      {
        name  = "SERVER_AUDIT_FILE_ROTATIONS"
        value = "37"
      },
    ]
  }]
  description = "A list of Options to apply"
}

variable "db_instance_tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags for the DB instance"
}

variable "db_option_group_tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags for the DB option group"
}

variable "db_parameter_group_tags" {
  type    = map(any)
  default = {}
}

variable "db_subnet_group_tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags for the  DB parameter group"
}

variable "apply_immediately" {
  type        = bool
  default     = false
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
}

variable "db_subnet_group_use_name_prefix" {
  type        = bool
  default     = false
  description = "Determines whether to use `subnet_group_name` as is or create a unique name beginning with the `subnet_group_name` as the prefix"
}

variable "create_security_group" {
  type        = bool
  default     = true
  description = "Whether to create security group and attach ingress/egress rules which will be used for rds instances(and rds proxy if we enabled it), if you already have one and do not want to create new security group you can explicitly set this variable to false and pass group id by using var.vpc_security_group_ids"
}

variable "create_db_parameter_group" {
  type        = bool
  default     = true
  description = "Whether to create a database parameter group"
}

variable "create_db_option_group" {
  type        = bool
  default     = false
  description = "Create a database option group"
}

variable "create_db_subnet_group" {
  type        = bool
  default     = true
  description = "Whether to create a database subnet group"
}

variable "db_subnet_group_name" {
  type        = string
  default     = null
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC"
}

variable "create_cloudwatch_log_group" {
  type        = bool
  default     = true
  description = "Determines whether a CloudWatch log group is created for each enabled_cloudwatch_logs_exports"
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention_in_days" {
  type        = number
  default     = 30
  description = "The number of days to retain CloudWatch logs for the DB instance"
}

variable "slow_queries" {
  type = object({
    enabled        = optional(bool, true)
    query_duration = optional(number, 3)
  })
  default = {
    enabled        = true
    query_duration = 3
  }
}

variable "publicly_accessible" {
  type        = bool
  default     = false
  description = "Whether the database is accessible publicly. Note that if you need to enable this you have to place db on public subnets"
}

variable "database_insights_mode" {
  type        = string
  default     = null
  description = "The mode of Database Insights to enable for the DB cluster. Valid values: standard, advanced"
}

variable "aurora_configs" {
  type = object({
    engine_mode = optional(string, "provisioned") # The database engine mode. Valid values: `global`, `multimaster`, `parallelquery`, `provisioned`, `serverless`(serverless is deprecated)
    instances   = optional(any, {})               # Cluster instances configs
    autoscaling = optional(object({
      enabled                = optional(bool, false)                              # Whether autoscaling enabled
      min_capacity           = optional(number, 0)                                # Min number of read replicas, NOTE: at cluster creation if we have set >0 value(for example 1) sometime it do not create the replicas at this min and there is need to go to aws UI and edit/save without any change the auto-scale config to trigger the read replica creation with provided min size
      max_capacity           = optional(number, 2)                                # Max number of read replicas permitted
      predefined_metric_type = optional(string, "RDSReaderAverageCPUUtilization") # The metric type to scale on. Valid values are `RDSReaderAverageCPUUtilization` and `RDSReaderAverageDatabaseConnections`
      scale_in_cooldown      = optional(number, 300)                              # Cooldown in seconds before allowing further scaling operations after a scale in
      scale_out_cooldown     = optional(number, 300)                              # Cooldown in seconds before allowing further scaling operations after a scale out
      target_cpu             = optional(number, 70)                               # CPU threshold which will initiate autoscaling
      target_connections     = optional(number, 700)                              # Average number of connections threshold which will initiate autoscaling. Default value is 70% of db.r4/r5/r6g.large's default max_connections
      schedules = optional(list(object({                                          # List of scheduled autoscale configs
        name         = string                                                     # The name of scheduled scale
        schedule     = string                                                     # The schedule time to apply auto scale, can be cron(min hour day month week-day year ), at(yyyy-mm-ddThh:mm:ss) or rate(value unit) formats
        min_capacity = optional(number)                                           # If not set defaults to aurora_configs.autoscaling_min_capacity
        max_capacity = optional(number)                                           # If not set defaults to aurora_configs.autoscaling_max_capacity
        timezone     = optional(string, null)                                     # By default it uses UTC, available values can be found here: https://www.joda.org/joda-time/timezones.html
      })), [])

      scaling_configuration              = optional(any, {}) # map of nested attributes with scaling properties. Only valid when `engine_mode` is set to `serverless`
      serverlessv2_scaling_configuration = optional(any, {}) # for enabling serverless-2(the serverless-1(engine_mode=serverless, scaling_configuration is set) is deprecated), valid when `engine_mode` is set to `provisioned`
    }), {})
  })
  default     = {}
  description = "The aws rd aurora specific configurations"
}

variable "proxy" {
  type = object({
    enabled             = optional(bool, false)                     # whether rds proxy is enabled
    endpoints           = optional(any, {})                         # map of {<name>: <configs>} additional proxy endpoints(by default we have already one read/write endpoint), for more info check resource doc https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_endpoint
    client_auth_type    = optional(string, "MYSQL_NATIVE_PASSWORD") # The type of authentication the proxy uses for connections from clients
    iam_auth            = optional(string, "DISABLED")              # Whether IAM auth enabled
    target_db_cluster   = optional(bool, true)                      # Whether the target db is cluster
    debug_logging       = optional(bool, false)                     # Whether enhanced logging is enabled
    idle_client_timeout = optional(number, 1800)                    # The timeout of idle connections, default is 30 minutes
  })
  default     = {}
  description = "The aws rds proxy specific configurations"
}

variable "enforce_client_tls" {
  type        = bool
  default     = true
  description = "parameter to enforce tls connections from clients"
}

variable "replication_source_identifier" {
  description = "ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled or not, the default is false"
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_arn" {
  description = "Specifies the KMS Key ID to encrypt Performance Insights data. If not specified, the default RDS KMS key will be used (aws/rds)"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Specifies the amount of time to retain performance insights data for. Defaults to 7 days if Performance Insights are enabled. Valid values are 7, month * 31 (where month is a number of months from 1-23), and 731. When using `advanced` database_insights_mode this value should be at least 465"
  type        = number
  default     = null
}

variable "enable_full_monitoring" {
  type        = bool
  default     = false
  description = "Config allowing to enable all available monitoring toolings on database. This is just wrapper shortcut to not set performance insights and database queries monitoring all configs manually"
}
