output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = try(module.db,"")
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = try(module.db,"")
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = try(module.db.endpoint,"")
}

output "db_instance_port" {
  description = "The database port"
  value       = try(module.db.db_instance_port,"")
}

output "db_username" {
  description = "DB username"
  value       = try(var.db_username,"")
}

output "db_password" {
  description = "DB password"
  value       = try(var.db_password,"")
  sensitive = true
}

output "db_instance_cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes"
  value       = try(module.db.db_instance_cloudwatch_log_groups,"")
}
