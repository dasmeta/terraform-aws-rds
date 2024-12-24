output "arn" {
  value       = module.this.proxy_arn
  description = "The arn of proxy"
}

output "id" {
  value       = module.this.proxy_id
  description = "The id of proxy"
}

output "endpoint" {
  description = "Proxy endpoint to connect"
  value       = module.this.proxy_endpoint
}

output "endpoints" {
  description = "All created proxy endpoints"
  value       = module.this.db_proxy_endpoints
}
