module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  count = local.is_aurora ? 0 : 1

  identifier = var.identifier

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine         = var.engine
  engine_version = var.engine_version

  major_engine_version = var.major_engine_version # DB option group
  instance_class       = var.instance_class
  apply_immediately    = var.apply_immediately

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = var.storage_encrypted
  storage_type          = var.storage_type

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
  family                          = local.parameter_group_family
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
  publicly_accessible         = var.publicly_accessible
}

module "db_aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.11.0"

  count = local.is_aurora ? 1 : 0

  name           = var.identifier
  engine         = var.engine
  engine_version = var.engine_version

  instance_class    = var.instance_class
  apply_immediately = var.apply_immediately

  allocated_storage = var.allocated_storage
  storage_encrypted = var.storage_encrypted
  storage_type      = var.storage_type

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.db_password
  port            = local.port

  subnets                = var.subnet_ids
  vpc_security_group_ids = local.vpc_security_group_ids
  create_security_group  = false # above we already create/configure/pass security group ids

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  preferred_maintenance_window    = var.maintenance_window
  preferred_backup_window         = var.backup_window
  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  create_monitoring_role                 = var.create_monitoring_role
  monitoring_interval                    = var.monitoring_interval
  create_cloudwatch_log_group            = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # DB instance parameter group configs
  create_db_parameter_group          = local.create_db_parameter_group
  db_parameter_group_family          = local.parameter_group_family
  db_parameter_group_name            = local.parameter_group_name
  db_parameter_group_use_name_prefix = false
  db_parameter_group_description     = "Custom parameter group for ${var.identifier}"
  db_parameter_group_parameters      = local.combined_parameters

  # DB cluster parameter group configs
  create_db_cluster_parameter_group          = length(local.cluster_params_map) > 0
  db_cluster_parameter_group_family          = local.parameter_group_family
  db_cluster_parameter_group_name            = "${local.parameter_group_name}-cluster"
  db_cluster_parameter_group_use_name_prefix = false
  db_cluster_parameter_group_description     = "Custom parameter group for DB cluster ${var.identifier}"
  db_cluster_parameter_group_parameters      = local.cluster_params_map

  create_db_subnet_group = var.create_db_subnet_group
  db_subnet_group_name   = var.db_subnet_group_name

  # aurora specific configs
  engine_mode                        = var.aurora_configs.engine_mode
  instances                          = var.aurora_configs.instances
  autoscaling_enabled                = var.aurora_configs.autoscaling.enabled
  autoscaling_min_capacity           = var.aurora_configs.autoscaling.min_capacity
  autoscaling_max_capacity           = var.aurora_configs.autoscaling.max_capacity
  predefined_metric_type             = var.aurora_configs.autoscaling.predefined_metric_type
  autoscaling_scale_in_cooldown      = var.aurora_configs.autoscaling.scale_in_cooldown
  autoscaling_scale_out_cooldown     = var.aurora_configs.autoscaling.scale_out_cooldown
  autoscaling_target_cpu             = var.aurora_configs.autoscaling.target_cpu
  autoscaling_target_connections     = var.aurora_configs.autoscaling.target_connections
  serverlessv2_scaling_configuration = var.aurora_configs.autoscaling.serverlessv2_scaling_configuration
  scaling_configuration              = var.aurora_configs.autoscaling.scaling_configuration
  manage_master_user_password        = var.manage_master_user_password
  publicly_accessible                = var.publicly_accessible

  tags = var.tags

  depends_on = [
    module.security_group
  ]
}

module "scheduled_scale" {
  source = "./modules/scheduled-scale"

  count = local.is_aurora && var.aurora_configs.engine_mode != "serverless" && var.aurora_configs.autoscaling.enabled && length(var.aurora_configs.autoscaling.schedules) > 0 ? 1 : 0

  target = {
    resource_id  = "cluster:${module.db_aurora[0].cluster_id}"
    min_capacity = var.aurora_configs.autoscaling.min_capacity
    max_capacity = var.aurora_configs.autoscaling.max_capacity
  }
  scheduled_actions = [for item in var.aurora_configs.autoscaling.schedules : merge(item, { name = "${module.db_aurora[0].cluster_id}-${item.name}" })]

  depends_on = [module.db_aurora]
}

module "proxy" {
  source = "./modules/proxy"

  count = var.proxy.enabled ? 1 : 0

  name                   = var.identifier
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = local.vpc_security_group_ids
  credentials_secret_arn = local.credentials_secret_arn
  db_username            = local.credentials_secret_arn == null ? var.db_username : null
  db_password            = local.credentials_secret_arn == null ? var.db_password : null

  endpoints         = var.proxy.endpoints
  client_auth_type  = var.proxy.client_auth_type
  iam_auth          = var.proxy.iam_auth
  target_db_cluster = var.proxy.target_db_cluster
  debug_logging     = var.proxy.debug_logging

  engine_family          = local.engine_family
  db_cluster_identifier  = local.is_aurora ? var.identifier : "" # var.identifier
  db_instance_identifier = local.is_aurora ? "" : var.identifier

  tags = var.tags

  depends_on = [
    module.db,
    module.db_aurora
  ]
}
