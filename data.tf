data "aws_ec2_instance_type" "this" {
  instance_type = trim(var.instance_class, "db.")
}

data "aws_db_instance" "database" {
  db_instance_identifier = var.identifier

  # Aurora cluster identifier is not a standalone DB instance identifier.
  count = var.alarms.enabled && !local.is_aurora ? 1 : 0

  depends_on = [
    module.db
  ]
}

data "aws_vpc" "this" {
  count = var.create_security_group ? 1 : 0

  id = var.vpc_id
}
