data "aws_vpc_security_group_rules" "existing" {
  filter {
    name   = "group-id"
    values = [var.security_group_id]
  }

  filter {
    name   = "is-egress"
    values = ["false"]
  }
}

data "aws_vpc_security_group_rule" "existing" {
  for_each = toset(data.aws_vpc_security_group_rules.existing.ids)

  security_group_rule_id = each.value
}

locals {
  public_ingress_rule_ids = [
    for id, rule in data.aws_vpc_security_group_rule.existing : id
    if rule.cidr_ipv4 == "0.0.0.0/0" || rule.cidr_ipv6 == "::/0"
  ]
}

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
    # The hosting workspace may inject provider default tags. Existing instance
    # tags are outside this access-only module's responsibility.
    ignore_changes = [tags, tags_all]

    precondition {
      condition     = length(local.public_ingress_rule_ids) == 0
      error_message = "The existing Aurora security group has public ingress rules. Remove them before managing private access."
    }
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

  lifecycle {
    ignore_changes = [tags]
  }
}
