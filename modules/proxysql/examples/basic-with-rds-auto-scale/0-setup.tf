terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# you can pass helm provider config like `export KUBE_CONFIG_PATH=/path/to/k8s.kubeconfig`
provider "helm" {}

# get region default vpc and its subnets
data "aws_vpcs" "default" {
  tags = {
    Name = "default"
  }
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.default.ids[0]]
  }
}

locals {
  db_username = "testUser"
  db_password = "test"
}

# create aurora cluster with auto scaling enabled
module "aurora_cluster" {
  source = "../../../.."

  identifier          = "rds-aurora-with-auto-scale"
  engine_version      = "8.0"
  engine              = "aurora-mysql"
  instance_class      = "db.t4g.medium"
  db_name             = "testDb"
  db_username         = local.db_username
  db_password         = local.db_password
  allocated_storage   = null
  publicly_accessible = true
  skip_final_snapshot = true
  apply_immediately   = true
  enforce_client_tls  = false
  storage_encrypted   = false

  vpc_id     = data.aws_vpcs.default.ids[0]
  subnet_ids = data.aws_subnets.default.ids

  create_db_parameter_group = true
  parameters = [
    { "name" : "sql_mode", "value" : "NO_ENGINE_SUBSTITUTION" },
    { "context" : "cluster", "name" : "sql_mode", "value" : "NO_ENGINE_SUBSTITUTION" },
    { "apply_method" : "pending-reboot", "context" : "cluster", "name" : "read_only", "value" : "0" },
    { "context" : "cluster", "name" : "character_set_server", "value" : "utf8mb4" },
    { "context" : "cluster", "name" : "collation_server", "value" : "utf8mb4_general_ci" },
    { "context" : "cluster", "name" : "event_scheduler", "value" : "ON" },
    { "context" : "cluster", "name" : "net_read_timeout", "value" : "300" },
    { "context" : "cluster", "name" : "net_write_timeout", "value" : "300" },
    { "apply_method" : "pending-reboot", "context" : "cluster", "name" : "enforce_gtid_consistency", "value" : "ON" },
    { "apply_method" : "pending-reboot", "context" : "cluster", "name" : "gtid-mode", "value" : "ON" },
  ]

  # enable full monitoring
  enable_full_monitoring = true

  aurora_configs = {
    instances = { # at least one master instance needs to be created
      master = {}
    }
    autoscaling = {
      enabled      = true
      min_capacity = 1
      max_capacity = 2
      # schedules = [
      #   {
      #     name         = "scale_down_daily"
      #     schedule     = "cron(00 22 * * ? *)" # every day at 22:00 scale down read replicas to 0
      #     min_capacity = 0
      #     max_capacity = 0
      #     timezone     = "Asia/Yerevan"
      #   },
      #   {
      #     name         = "scale_up_daily"
      #     schedule     = "cron(00 10 * * ? *)" # every day at 10:00 morning scale up read replicas min=1, max=2
      #     min_capacity = 1
      #     max_capacity = 2
      #     timezone     = "Asia/Yerevan"
      #   }
      # ]
    }
  }

  alarms = {
    enabled   = false
    sns_topic = ""
  }
}
