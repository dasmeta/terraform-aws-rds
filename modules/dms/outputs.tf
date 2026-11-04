output "replication_subnet_group_id" {
  description = "ID of the managed DMS replication subnet group."
  value       = module.this.replication_subnet_group_id
}

output "replication_instance_arn" {
  description = "ARN of the DMS replication instance."
  value       = module.this.replication_instance_arn
}

output "replication_instance_private_ips" {
  description = "Private IP addresses of the DMS replication instance."
  value       = module.this.replication_instance_private_ips
}

output "source_endpoint_id" {
  description = "ID of the source DMS endpoint."
  value       = aws_dms_endpoint.source.endpoint_id
}

output "source_endpoint_arn" {
  description = "ARN of the source DMS endpoint."
  value       = aws_dms_endpoint.source.endpoint_arn
}

output "target_endpoint_id" {
  description = "ID of the target DMS endpoint."
  value       = aws_dms_endpoint.target.endpoint_id
}

output "target_endpoint_arn" {
  description = "ARN of the target DMS endpoint."
  value       = aws_dms_endpoint.target.endpoint_arn
}

output "replication_task_id" {
  description = "ID of the stopped DMS replication task."
  value       = aws_dms_replication_task.this.replication_task_id
}

output "replication_task_arn" {
  description = "ARN of the stopped DMS replication task."
  value       = aws_dms_replication_task.this.replication_task_arn
}

output "access_iam_role_arn" {
  description = "ARN of the scoped DMS Secrets Manager access role."
  value       = module.this.access_iam_role_arn
}

output "task_log_group_name" {
  description = "CloudWatch log group used by the DMS replication task."
  value       = "dms-tasks-${element(split(":", module.this.replication_instance_arn), 6)}"
}

output "task_log_stream_name" {
  description = "CloudWatch log stream used by the DMS replication task."
  value       = "dms-task-${element(split(":", aws_dms_replication_task.this.replication_task_arn), 6)}"
}

output "replication_instance_publicly_accessible" {
  description = "Effective public accessibility setting for contract verification."
  value       = false
}

output "replication_instance_class" {
  description = "Effective DMS replication instance class."
  value       = var.instance_class
}

output "replication_instance_engine_version" {
  description = "Effective DMS engine version."
  value       = var.engine_version
}

output "replication_instance_allocated_storage" {
  description = "Effective DMS allocated storage in GiB."
  value       = var.allocated_storage
}

output "replication_instance_multi_az" {
  description = "Effective DMS Multi-AZ setting."
  value       = var.multi_az
}

output "source_endpoint_ssl_mode" {
  description = "Effective source endpoint TLS verification mode."
  value       = aws_dms_endpoint.source.ssl_mode
}

output "target_endpoint_ssl_mode" {
  description = "Effective target endpoint TLS verification mode."
  value       = aws_dms_endpoint.target.ssl_mode
}

output "migration_type" {
  description = "Effective DMS migration type."
  value       = "full-load-and-cdc"
}

output "task_start_replication" {
  description = "Whether Terraform starts the DMS task. Always false."
  value       = false
}

output "table_mappings" {
  description = "Generated explicit-schema DMS table mappings JSON."
  value       = local.table_mappings
}

output "task_settings" {
  description = "Generated opinionated DMS task settings JSON."
  value       = local.task_settings
}
