mock_provider "aws" {}

run "private_instances_and_exact_ingress" {
  command = plan

  variables {
    security_group_id = "sg-0123456789abcdef0"
    cluster = {
      identifier                            = "aurora-existing"
      engine                                = "aurora-mysql"
      engine_version                        = "8.0.mysql_aurora.3.10.3"
      database_name                         = "example"
      db_subnet_group_name                  = "default"
      db_cluster_parameter_group_name       = "default.aurora-mysql8.0"
      backup_retention_period               = 7
      preferred_backup_window               = "21:00-21:30"
      preferred_maintenance_window          = "tue:00:00-tue:00:30"
      storage_encrypted                     = false
      deletion_protection                   = false
      enable_http_endpoint                  = true
      skip_final_snapshot                   = true
      performance_insights_enabled          = true
      performance_insights_kms_key_id       = "arn:aws:kms:eu-central-1:111122223333:key/example"
      performance_insights_retention_period = 465
      iam_database_authentication_enabled   = false
      copy_tags_to_snapshot                 = false
      port                                  = 3306
    }
    instances = {
      writer = {
        identifier     = "aurora-existing-0"
        instance_class = "db.r6g.large"
        engine         = "aurora-mysql"
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
    condition     = aws_rds_cluster.existing.backup_retention_period == 7
    error_message = "The adopted cluster must retain its configured backup period."
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
    cluster = {
      identifier                            = "aurora-existing"
      engine                                = "aurora-mysql"
      engine_version                        = "8.0.mysql_aurora.3.10.3"
      database_name                         = "example"
      db_subnet_group_name                  = "default"
      db_cluster_parameter_group_name       = "default.aurora-mysql8.0"
      backup_retention_period               = 7
      preferred_backup_window               = "21:00-21:30"
      preferred_maintenance_window          = "tue:00:00-tue:00:30"
      storage_encrypted                     = false
      deletion_protection                   = false
      enable_http_endpoint                  = true
      skip_final_snapshot                   = true
      performance_insights_enabled          = true
      performance_insights_kms_key_id       = "arn:aws:kms:eu-central-1:111122223333:key/example"
      performance_insights_retention_period = 465
      iam_database_authentication_enabled   = false
      copy_tags_to_snapshot                 = false
      port                                  = 3306
    }
    instances = {}
    ingress_rules = {
      public = {
        description = "Must be rejected"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  }

  expect_failures = [var.ingress_rules]
}
