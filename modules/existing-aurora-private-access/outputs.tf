output "instance_ids" {
  description = "Identifiers of adopted Aurora instances."
  value       = { for key, instance in aws_rds_cluster_instance.instances : key => instance.id }
}

output "ingress_rule_ids" {
  description = "Identifiers of adopted ingress rules."
  value       = { for key, rule in aws_vpc_security_group_ingress_rule.rules : key => rule.id }
}
