output "helm_meta" {
  value       = helm_release.proxysql.metadata
  description = "The helm chart release metadata"
}
