locals {
  source_endpoint_id  = "${var.name}-source"
  target_endpoint_id  = "${var.name}-target"
  replication_task_id = "${var.name}-full-load-cdc"

  table_mappings = jsonencode({
    rules = [{
      rule-type = "selection"
      rule-id   = "1"
      rule-name = "include-application-schema"
      object-locator = {
        schema-name = var.schema_name
        table-name  = "%"
      }
      rule-action = "include"
    }]
  })

  task_settings = jsonencode({
    TargetMetadata = {
      SupportLobs        = true
      FullLobMode        = true
      LimitedSizeLobMode = false
      LobChunkSize       = 64
    }
    FullLoadSettings = {
      TargetTablePrepMode             = "TRUNCATE_BEFORE_LOAD"
      CreatePkAfterFullLoad           = false
      StopTaskCachedChangesApplied    = false
      StopTaskCachedChangesNotApplied = false
      MaxFullLoadSubTasks             = var.max_full_load_subtasks
      TransactionConsistencyTimeout   = var.transaction_consistency_timeout
      CommitRate                      = var.commit_rate
    }
    Logging = {
      EnableLogging = true
    }
    ValidationSettings = {
      EnableValidation = true
      ValidationMode   = "ROW_LEVEL"
    }
  })
}

module "this" {
  source  = "terraform-aws-modules/dms/aws"
  version = "2.6.0"

  create_iam_roles = true

  repl_subnet_group_name        = "${var.name}-subnet-group"
  repl_subnet_group_description = "Private replication subnet group for ${var.name}"
  repl_subnet_group_subnet_ids  = var.network.subnet_ids

  repl_instance_allocated_storage            = var.allocated_storage
  repl_instance_auto_minor_version_upgrade   = false
  repl_instance_allow_major_version_upgrade  = false
  repl_instance_apply_immediately            = false
  repl_instance_engine_version               = var.engine_version
  repl_instance_multi_az                     = var.multi_az
  repl_instance_preferred_maintenance_window = var.maintenance_window
  repl_instance_publicly_accessible          = false
  repl_instance_class                        = var.instance_class
  repl_instance_id                           = var.name
  repl_instance_vpc_security_group_ids       = var.network.security_group_ids

  create_access_iam_role = true
  access_iam_role_name   = "${var.name}-secrets-access"
  access_secret_arns = distinct([
    var.source_endpoint.secret_arn,
    var.target_endpoint.secret_arn,
  ])
  access_kms_key_arns = distinct([
    var.source_endpoint.kms_key_arn,
    var.target_endpoint.kms_key_arn,
  ])

  endpoints = {}

  replication_tasks = {}

  tags = var.tags
}

resource "aws_dms_endpoint" "source" {
  endpoint_id                     = local.source_endpoint_id
  endpoint_type                   = "source"
  engine_name                     = var.source_endpoint.engine_name
  database_name                   = var.source_endpoint.database_name
  secrets_manager_arn             = var.source_endpoint.secret_arn
  secrets_manager_access_role_arn = module.this.access_iam_role_arn
  certificate_arn                 = var.source_endpoint.certificate_arn
  ssl_mode                        = "verify-full"
  extra_connection_attributes     = var.source_endpoint.extra_connection_attributes

  tags = var.tags
}

resource "aws_dms_endpoint" "target" {
  endpoint_id                     = local.target_endpoint_id
  endpoint_type                   = "target"
  engine_name                     = var.target_endpoint.engine_name
  database_name                   = var.target_endpoint.database_name
  secrets_manager_arn             = var.target_endpoint.secret_arn
  secrets_manager_access_role_arn = module.this.access_iam_role_arn
  certificate_arn                 = var.target_endpoint.certificate_arn
  ssl_mode                        = "verify-full"
  extra_connection_attributes     = var.target_endpoint.extra_connection_attributes

  tags = var.tags
}

resource "aws_dms_replication_task" "this" {
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = module.this.replication_instance_arn
  replication_task_id       = local.replication_task_id
  replication_task_settings = local.task_settings
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  table_mappings            = local.table_mappings
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  start_replication_task    = false

  tags = var.tags
}
