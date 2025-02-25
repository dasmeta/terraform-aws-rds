locals {
  vpc_security_group_ids          = var.create_security_group ? [module.security_group[0].security_group_id] : var.vpc_security_group_ids
  enabled_cloudwatch_logs_exports = ((var.engine == "mysql" || var.engine == "mariadb") && var.slow_queries.enabled) ? ["slowquery"] : (var.engine == "postgres" && var.slow_queries.enabled) ? ["postgresql"] : var.enabled_cloudwatch_logs_exports
  # Cloudwatch log groups from which log based metrics are created in case slow queries are enabled
  cloudwatch_log_groups          = var.slow_queries.enabled ? { for type in local.enabled_cloudwatch_logs_exports : type => "/aws/rds/instance/${var.identifier}/${type}" } : {}
  create_db_parameter_group      = var.slow_queries.enabled || var.enforce_client_tls ? true : var.create_db_parameter_group
  parameter_group_name           = local.create_db_parameter_group ? "${var.identifier}-${var.engine}" : null
  postgres_slow_queries_duration = var.slow_queries.query_duration * 1000
  port                           = (endswith(var.engine, "mysql") || endswith(var.engine, "mariadb")) ? 3306 : endswith(var.engine, "postgres") ? 5432 : var.port
  default_params_mysql = [
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "log_output"
      value = "FILE"
    },
    {
      name  = "long_query_time"
      value = var.slow_queries.query_duration
    },
  ]
  default_params_postgres = [
    {
      name  = "log_min_duration_statement" //This setting causes PostgreSQL to log any query that takes longer than `local.slow_queries_duration` seconds to execute. It includes both the query text and its duration.
      value = local.postgres_slow_queries_duration
    },
    {
      name  = "log_statement" //This setting prevents the logging of every single SQL statement and logs those ones which correspond to parameter group's configuration.
      value = "none"
    },
    {
      name  = "log_duration" //When enabled, this logs the duration of every completed statement.
      value = "1"
    },
  ]

  enforce_tls_mysql = {
    "require_secure_transport" = 1
  }

  enforce_tls_postgres = {
    "rds.force_ssl" = 1
  }

  # Maps from the default parameters for easier merging
  params_mysql    = { for p in local.default_params_mysql : p.name => p.value }
  params_postgres = { for p in local.default_params_postgres : p.name => p.value }

  # Create a map from the user parameters
  user_params_map    = { for p in var.parameters : p.name => p.value if p.context == "instance" }
  cluster_params_map = [for p in var.parameters : p if p.context == "cluster"]

  # Merge the two maps, with user parameters overriding defaults
  merged_params_map = merge(
    ((var.engine == "mysql" || var.engine == "mariadb") && var.slow_queries.enabled) ? local.params_mysql : {},
    (var.engine == "postgres" && var.slow_queries.enabled) ? local.params_postgres : {},
    local.user_params_map,
    var.enforce_client_tls ? ((var.engine == "mysql" || var.engine == "mariadb") ? local.enforce_tls_mysql : local.enforce_tls_postgres) : {},
  )

  # Convert the merged map back to a list of maps
  combined_parameters = [for name, value in local.merged_params_map : { name = name, value = value }]
  is_aurora           = startswith(var.engine, "aurora")
  engine_family       = (endswith(var.engine, "mysql") || endswith(var.engine, "mariadb")) ? "MYSQL" : (endswith(var.engine, "postgres") ? "POSTGRESQL" : "")

  // SampleCount statistic adds 2 to the real count in case the engine is postgres, so 7 means 5 + 2
  slow_queries_alert_threshold = var.engine == "postgres" ? 7 : 5
  parameter_group_family       = format("%s%s%s", (local.is_aurora ? "aurora-" : ""), var.engine, (var.engine == "mariadb" ? regex("\\d+\\.\\d+", var.engine_version) : var.engine_version))

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
