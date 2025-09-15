locals {
  engine_families = {
    postgres = "POSTGRESQL",
    mysql    = "MYSQL"
  }
  is_aurora     = startswith(var.engine, "aurora")
  engine_family = (endswith(var.engine, "mysql") || endswith(var.engine, "mariadb")) ? local.engine_families.mysql : (endswith(var.engine, "postgres") ? local.engine_families.postgres : "")

  // SampleCount statistic adds 2 to the real count in case the engine is postgres, so 7 means 5 + 2
  slow_queries_alert_threshold = var.engine == "postgres" ? 7 : 5
  parameter_group_family       = format("%s%s", var.engine, (var.engine == "mariadb" ? regex("\\d+\\.\\d+", var.engine_version) : (length(try(regex("postgres", var.engine), "")) > 0 ? regex("\\d+", var.engine_version) : var.engine_version)))

  vpc_security_group_ids = var.create_security_group ? [module.security_group[0].security_group_id] : var.vpc_security_group_ids
  # Cloudwatch log groups from which log based metrics are created in case slow queries are enabled
  cloudwatch_log_groups          = local.slow_queries.enabled ? { for type in local.enabled_cloudwatch_logs_exports : type => "/aws/rds/${local.is_aurora ? "cluster" : "instance"}/${var.identifier}/${type}" } : {}
  parameter_group_name           = local.create_db_parameter_group ? "${var.identifier}-${var.engine}" : null
  postgres_slow_queries_duration = var.slow_queries.query_duration * 1000
  port                           = local.engine_family == local.engine_families.mysql ? 3306 : (local.engine_family == local.engine_families.postgres ? 5432 : var.port)
  prepared_configs = {
    MYSQL = {
      slow_query_enable = {
        params = [
          { name = "slow_query_log", value = "1" },
          { name = "log_output", value = "FILE", apply_method = "pending-reboot" },
          { name = "long_query_time", value = var.slow_queries.query_duration }
        ]
        enabled_cloudwatch_logs_exports = ["slowquery"]
      }
      client_tls_enforce = { params = [
        { name = "require_secure_transport", value = "1" }
      ] }
      enable_full_monitoring = {
        params = [
          { "apply_method" : "pending-reboot", "name" : "performance_schema", "value" : "1" },
          { "name" : "innodb_print_all_deadlocks", "value" : "1" },
        ],
        enabled_cloudwatch_logs_exports = [
          "audit",
          "error",
          "general",
          "instance",
          "slowquery",
        ]
      }
    },
    POSTGRESQL = {
      slow_query_enable = {
        params = [
          // This setting causes PostgreSQL to log any query that takes longer than `local.slow_queries_duration` seconds to execute. It includes both the query text and its duration.
          { name = "log_min_duration_statement", value = local.postgres_slow_queries_duration },
          // This setting prevents the logging of every single SQL statement and logs those ones which correspond to parameter group's configuration.
          { name = "log_statement", value = "none" },
          // When enabled, this logs the duration of every completed statement.
          { name = "log_duration", value = "1" }
        ]
        enabled_cloudwatch_logs_exports = ["postgresql"]
      }
      client_tls_enforce = { params = [
        {
          name  = "enforce_tls_postgres"
          value = "1"
        }
      ] }
      enable_full_monitoring = {
        enabled_cloudwatch_logs_exports = [
          "postgresql",
          "upgrade"
        ]
      }
    }
    common = {
      enable_full_monitoring = {
        slow_queries                = { "enabled" : true }
        create_db_parameter_group   = true
        create_cloudwatch_log_group = true
        enabled_cloudwatch_logs_exports = [
          "iam-db-auth-error",
        ]
        database_insights_mode                = "advanced"
        performance_insights_enabled          = true
        performance_insights_retention_period = 465
        monitoring_interval                   = 60
        create_monitoring_role                = true
      }
    }
  }

  # have set configs automatically based on enable_full_monitoring variable to not pass all this manually
  slow_queries                          = merge(var.slow_queries, var.enable_full_monitoring ? local.prepared_configs.common.enable_full_monitoring.slow_queries : {})
  create_db_parameter_group             = var.enable_full_monitoring ? local.prepared_configs.common.enable_full_monitoring.create_db_parameter_group : local.slow_queries.enabled || var.enforce_client_tls ? true : var.create_db_parameter_group
  create_cloudwatch_log_group           = var.enable_full_monitoring ? local.prepared_configs.common.enable_full_monitoring.create_cloudwatch_log_group : var.create_cloudwatch_log_group
  enabled_cloudwatch_logs_exports       = var.enable_full_monitoring ? concat(local.prepared_configs[local.engine_family].enable_full_monitoring.enabled_cloudwatch_logs_exports, local.prepared_configs.common.enable_full_monitoring.enabled_cloudwatch_logs_exports) : concat(var.enabled_cloudwatch_logs_exports, local.slow_queries.enabled ? local.prepared_configs[local.engine_family].slow_query_enable.enabled_cloudwatch_logs_exports : [])
  database_insights_mode                = var.enable_full_monitoring ? local.prepared_configs.common.enable_full_monitoring.database_insights_mode : var.database_insights_mode
  performance_insights_enabled          = var.enable_full_monitoring ? local.prepared_configs.common.enable_full_monitoring.performance_insights_enabled : var.performance_insights_enabled
  performance_insights_retention_period = var.enable_full_monitoring ? max(local.prepared_configs.common.enable_full_monitoring.performance_insights_retention_period, coalesce(var.performance_insights_retention_period, 0)) : var.performance_insights_retention_period
  monitoring_interval                   = var.enable_full_monitoring ? max(local.prepared_configs.common.enable_full_monitoring.monitoring_interval, var.monitoring_interval) : var.monitoring_interval
  create_monitoring_role                = var.enable_full_monitoring ? local.prepared_configs.common.enable_full_monitoring.create_monitoring_role : var.create_monitoring_role

  # build parameter group params
  ## Maps from the default parameters for easier merging
  slow_query_params_map             = local.slow_queries.enabled ? { for p in try(local.prepared_configs[local.engine_family].slow_query_enable.params, {}) : p.name => p } : {}
  enforce_client_tls_params_map     = var.enforce_client_tls ? { for p in try(local.prepared_configs[local.engine_family].client_tls_enforce.params, {}) : p.name => p } : {}
  enable_full_monitoring_params_map = var.enable_full_monitoring ? { for p in try(local.prepared_configs[local.engine_family].enable_full_monitoring.params, {}) : p.name => p } : {}
  ## Create  parma_name=>param_values_object map from the user passed parameters
  user_instance_params_map = { for p in var.parameters : p.name => p if p.context == "instance" }
  user_cluster_params_map  = { for p in var.parameters : p.name => p if p.context == "cluster" }
  ## Merge prepared param sets with user parameters
  merged_instance_params_map = merge(
    local.slow_query_params_map,
    local.enforce_client_tls_params_map,
    local.enable_full_monitoring_params_map,
    local.user_instance_params_map
  )
  merged_cluster_params_map = merge(
    local.slow_query_params_map,
    local.enforce_client_tls_params_map,
    local.enable_full_monitoring_params_map,
    local.user_cluster_params_map
  )
  ## Convert the merged map back to a list of maps
  instance_parameters = [for name, value in local.merged_instance_params_map : value]
  cluster_parameters  = [for name, value in local.merged_cluster_params_map : value]



  ingress_with_cidr_blocks = concat(
    var.ingress_with_cidr_blocks,
    var.create_security_group && var.set_vpc_security_group_rules ? [ # make cluster available within vpc private network
      {
        description = "${local.port} from VPC"
        from_port   = local.port
        to_port     = local.port
        protocol    = "tcp"
        cidr_blocks = data.aws_vpc.this[0].cidr_block
      }
    ] : [],
    var.create_security_group && var.publicly_accessible ? [ # expose rds to public, NOTE: you need also to place instances on public subnets
      {
        description = "Accessible from everywhere"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = "0.0.0.0/0"
      }
    ] : []
  )

  egress_with_cidr_blocks = concat(
    var.egress_with_cidr_blocks,
    var.create_security_group && var.set_vpc_security_group_rules && var.proxy.enabled ? [ # this egress rule needed for rds proxy
      {
        description = "${local.port} to VPC"
        from_port   = local.port
        to_port     = local.port
        protocol    = "tcp"
        cidr_blocks = data.aws_vpc.this[0].cidr_block
      }
    ] : [],
  )

  credentials_secret_arn = try(module.db[0].db_instance_master_user_secret_arn, module.db_aurora[0].cluster_master_user_secret.secret_arn, null)
}
