mock_provider "aws" {}

run "private_instances_and_exact_ingress" {
  command = plan

  variables {
    security_group_id = "sg-0123456789abcdef0"
    instances = {
      writer = {
        identifier         = "aurora-existing-0"
        cluster_identifier = "aurora-existing"
        instance_class     = "db.r6g.large"
        engine             = "aurora-mysql"
      }
    }
    ingress_rules = {
      proxy = {
        description                  = "Proxy access"
        referenced_security_group_id = "sg-0123456789abcdef1"
      }
      eks = {
        description = "EKS access"
        cidr_ipv4   = "10.0.0.0/16"
      }
    }
  }

  assert {
    condition     = aws_rds_cluster_instance.instances["writer"].publicly_accessible == false
    error_message = "Existing Aurora instances must remain private."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.rules) == 2
    error_message = "Only explicitly listed ingress rules may be managed."
  }
}

run "reject_world_open_ingress" {
  command = plan

  variables {
    security_group_id = "sg-0123456789abcdef0"
    instances         = {}
    ingress_rules = {
      public = {
        description = "Must be rejected"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  }

  expect_failures = [var.ingress_rules]
}
