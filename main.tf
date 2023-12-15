locals {
  vpc_security_group_ids          = var.create_security_group ? [module.security_group[0].security_group_id] : var.vpc_security_group_ids
  enabled_cloudwatch_logs_exports = (var.engine == "mysql" && var.slow_queries.enabled) ? ["slowquery"] : (var.engine == "postgres" && var.slow_queries.enabled) ? ["postgresql"] : var.enabled_cloudwatch_logs_exports
  # Cloudwatch log groups from which log based metrics are created in case slow queries are enabled
  cloudwatch_log_groups          = var.slow_queries.enabled ? { for type in local.enabled_cloudwatch_logs_exports : type => "/aws/rds/instance/${var.identifier}/${type}" } : {}
  create_db_parameter_group      = var.slow_queries.enabled ? true : var.create_db_parameter_group
  parameter_group_name           = local.create_db_parameter_group ? "${var.identifier}-${var.engine}" : null
  postgres_slow_queries_duration = var.slow_queries.query_duration * 1000
  port                           = var.engine == "mysql" ? 3306 : var.engine == "postgres" ? 5432 : var.port
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

  # Maps from the default parameters for easier merging
  params_mysql    = { for p in local.default_params_mysql : p.name => p.value }
  params_postgres = { for p in local.default_params_postgres : p.name => p.value }

  # Create a map from the user parameters
  user_params_map = { for p in var.parameters : p.name => p.value }

  # Merge the two maps, with user parameters overriding defaults
  merged_params_map = (var.engine == "mysql" && var.slow_queries.enabled) ? merge(local.params_mysql, local.user_params_map) : (var.engine == "postgres" && var.slow_queries.enabled) ? merge(local.params_postgres, local.user_params_map) : {}

  # Convert the merged map back to a list of maps
  combined_parameters = [for name, value in local.merged_params_map : { name = name, value = value }]
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.1"

  depends_on = [
    module.security_group
  ]

  identifier = var.identifier

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine         = var.engine
  engine_version = var.engine_version

  major_engine_version = var.major_engine_version # DB option group
  instance_class       = var.instance_class
  apply_immediately    = var.apply_immediately

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = local.port

  multi_az               = var.multi_az
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = local.vpc_security_group_ids

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  maintenance_window              = var.maintenance_window
  backup_window                   = var.backup_window
  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  create_monitoring_role                 = var.create_monitoring_role
  monitoring_interval                    = var.monitoring_interval
  monitoring_role_name                   = var.monitoring_role_name
  create_cloudwatch_log_group            = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # DB parameter group configs
  create_db_parameter_group       = local.create_db_parameter_group
  family                          = "${var.engine}${var.engine_version}"
  parameter_group_name            = local.parameter_group_name
  parameter_group_use_name_prefix = false
  parameter_group_description     = "Custom parameter group for ${var.identifier}"
  parameters                      = local.combined_parameters

  create_db_option_group = var.create_db_option_group
  create_db_subnet_group = var.create_db_subnet_group
  db_subnet_group_name   = var.db_subnet_group_name

  options = var.options
  tags    = var.tags

  db_instance_tags            = var.db_instance_tags
  db_option_group_tags        = var.db_option_group_tags
  db_parameter_group_tags     = var.db_parameter_group_tags
  db_subnet_group_tags        = var.db_subnet_group_tags
  manage_master_user_password = var.manage_master_user_password
}
