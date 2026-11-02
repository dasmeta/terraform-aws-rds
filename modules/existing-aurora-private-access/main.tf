resource "aws_rds_cluster_instance" "instances" {
  for_each = var.instances

  identifier          = each.value.identifier
  cluster_identifier  = each.value.cluster_identifier
  instance_class      = each.value.instance_class
  engine              = each.value.engine
  publicly_accessible = false

  tags = each.value.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rules" {
  for_each = var.ingress_rules

  security_group_id            = var.security_group_id
  referenced_security_group_id = each.value.referenced_security_group_id
  cidr_ipv4                    = each.value.cidr_ipv4
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port
  description                  = each.value.description
}
