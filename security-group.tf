module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  count = var.create_security_group ? 1 : 0

  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = local.ingress_with_cidr_blocks

  # egress
  egress_with_cidr_blocks = local.egress_with_cidr_blocks

  tags = var.tags
}
