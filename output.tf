output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db[0].db_instance_address //try(module.db[0].db_instance_address, "")
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = try(module.db[0].db_instance_arn, "")
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = try(module.db[0].endpoint, "")
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
