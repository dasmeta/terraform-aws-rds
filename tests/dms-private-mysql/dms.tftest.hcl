mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name   = "eu-central-1"
      region = "eu-central-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
      arn        = "arn:aws:iam::111122223333:user/terraform-test"
      user_id    = "AIDATERRAFORMTEST"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_dms_replication_instance" {
    override_during = plan
    defaults = {
      replication_instance_arn = "arn:aws:dms:eu-central-1:111122223333:rep:INSTANCEEXAMPLE"
    }
  }

  mock_resource "aws_dms_replication_task" {
    override_during = plan
    defaults = {
      replication_task_arn = "arn:aws:dms:eu-central-1:111122223333:task:TASKEXAMPLE"
    }
  }
}

run "secure_private_migration_defaults" {
  command = plan

  assert {
    condition     = module.this.replication_instance_publicly_accessible == false
    error_message = "The DMS replication instance must remain private."
  }

  assert {
    condition     = module.this.replication_instance_class == "dms.r6i.large"
    error_message = "The default DMS class must be dms.r6i.large."
  }

  assert {
    condition     = module.this.replication_instance_engine_version == "3.6.1"
    error_message = "The default DMS engine version must be 3.6.1."
  }

  assert {
    condition     = module.this.replication_instance_allocated_storage == 100
    error_message = "The default DMS storage allocation must be 100 GiB."
  }

  assert {
    condition     = module.this.replication_instance_multi_az == false
    error_message = "The default DMS runtime must be Single-AZ."
  }

  assert {
    condition     = module.this.source_endpoint_ssl_mode == "verify-full" && module.this.target_endpoint_ssl_mode == "verify-full"
    error_message = "Both endpoints must use verify-full TLS."
  }

  assert {
    condition     = module.this.migration_type == "full-load-and-cdc"
    error_message = "Only full-load-and-cdc tasks are supported."
  }

  assert {
    condition     = module.this.task_start_replication == false
    error_message = "Terraform must leave the migration task stopped."
  }

  assert {
    condition     = jsondecode(module.this.table_mappings).rules[0]["object-locator"]["schema-name"] == "application"
    error_message = "Table mappings must select the explicit application schema."
  }

  assert {
    condition     = jsondecode(module.this.task_settings).TargetMetadata.FullLobMode == true
    error_message = "Full LOB mode must be enabled."
  }

  assert {
    condition     = jsondecode(module.this.task_settings).FullLoadSettings.TargetTablePrepMode == "TRUNCATE_BEFORE_LOAD"
    error_message = "The target preparation mode must truncate pre-created tables."
  }

  assert {
    condition     = jsondecode(module.this.task_settings).Logging.EnableLogging == true
    error_message = "DMS task logging must be enabled."
  }

  assert {
    condition     = jsondecode(module.this.task_settings).ValidationSettings.EnableValidation == true
    error_message = "DMS row validation must be enabled."
  }

  assert {
    condition     = module.this.task_log_group_name == "dms-tasks-INSTANCEEXAMPLE"
    error_message = "The log group name must use the replication instance resource ID."
  }

  assert {
    condition     = module.this.task_log_stream_name == "dms-task-TASKEXAMPLE"
    error_message = "The log stream name must use the replication task resource ID."
  }
}
