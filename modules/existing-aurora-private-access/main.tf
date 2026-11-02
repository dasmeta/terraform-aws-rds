resource "aws_rds_cluster" "existing" {
  cluster_identifier = var.cluster.identifier
  engine             = var.cluster.engine
  engine_version     = var.cluster.engine_version
  database_name      = var.cluster.database_name

  db_subnet_group_name            = var.cluster.db_subnet_group_name
  db_cluster_parameter_group_name = var.cluster.db_cluster_parameter_group_name
  vpc_security_group_ids          = [var.security_group_id]
  port                            = var.cluster.port

  backup_retention_period               = var.cluster.backup_retention_period
  preferred_backup_window               = var.cluster.preferred_backup_window
  preferred_maintenance_window          = var.cluster.preferred_maintenance_window
  storage_encrypted                     = var.cluster.storage_encrypted
  deletion_protection                   = var.cluster.deletion_protection
  enable_http_endpoint                  = var.cluster.enable_http_endpoint
  skip_final_snapshot                   = var.cluster.skip_final_snapshot
  performance_insights_enabled          = var.cluster.performance_insights_enabled
  performance_insights_kms_key_id       = var.cluster.performance_insights_kms_key_id
  performance_insights_retention_period = var.cluster.performance_insights_retention_period

  iam_database_authentication_enabled = var.cluster.iam_database_authentication_enabled
  copy_tags_to_snapshot               = var.cluster.copy_tags_to_snapshot

  tags = var.cluster.tags

  lifecycle {
    prevent_destroy = true
    # AWS reports absent forwarding settings as null, while this provider
    # defaults them to false and otherwise proposes a needless modification.
    ignore_changes = [tags, tags_all, enable_global_write_forwarding, enable_local_write_forwarding]
  }
}

data "aws_vpc_security_group_rules" "existing" {
  filter {
    name   = "group-id"
    values = [var.security_group_id]
  }

}

data "aws_vpc_security_group_rule" "existing" {
  for_each = toset(data.aws_vpc_security_group_rules.existing.ids)

  security_group_rule_id = each.value
}

locals {
  public_ingress_rule_ids = [
    for id, rule in data.aws_vpc_security_group_rule.existing : id
    if !rule.is_egress && (rule.cidr_ipv4 == "0.0.0.0/0" || rule.cidr_ipv6 == "::/0")
  ]
}

resource "aws_rds_cluster_instance" "instances" {
  for_each = var.instances

  identifier          = each.value.identifier
  cluster_identifier  = aws_rds_cluster.existing.id
  instance_class      = each.value.instance_class
  engine              = each.value.engine
  publicly_accessible = false

  tags = each.value.tags

  lifecycle {
    prevent_destroy = true
    # The hosting workspace may inject provider default tags. Existing instance
    # tags are outside this access-only module's responsibility.
    ignore_changes = [tags, tags_all, force_destroy]

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
