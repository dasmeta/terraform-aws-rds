output "final_config" {
  value       = "module.custom_default_configs.merged"
  description = "The helm chart final prepared configs"
  sensitive   = true
}
