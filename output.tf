output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = try(module.db[0].db_instance_address, "")
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = try(module.db[0].db_instance_arn, "")
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = try(module.db[0].db_instance_endpoint, "")
}

output "db_instance_port" {
  description = "The database port"
  value       = try(module.db[0].db_instance_port, "")
}

output "db_username" {
  description = "DB username"
  value       = try(var.db_username, "")
}

output "db_password" {
  description = "DB password"
  value       = try(var.db_password, "")
  sensitive   = true
}

output "db_instance_cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes"
  value       = try(module.db[0].db_instance_cloudwatch_log_groups, "")
}

# aurora cluster endpoints
output "cluster_endpoint" {
  description = "aurora cluster read/write endpoint"
  value       = try(module.db_aurora[0].cluster_endpoint, "")
}
output "cluster_reader_endpoint" {
  description = "aurora cluster read endpoint"
  value       = try(module.db_aurora[0].cluster_reader_endpoint, "")
}

output "cluster_instance_endpoint_suffix" {
  description = "aurora cluster instances endpoint suffix part in form '.<cluster-uniq-hash>.<region-name>.rds.amazonaws.com'"
  value       = replace(try(module.db_aurora[0].cluster_endpoint, ""), "${var.identifier}.cluster-", ".")
}
