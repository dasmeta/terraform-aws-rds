module "rds" {
  source = "../.."

  engine         = "postgres"
  engine_version = "12"
  identifier     = "dbdemo"
  db_name        = "devdata"
  db_username    = "userTerraform"
  db_password    = "password-terraform"

  parameter_group_name = "rds-pg-12"
  vpc_id               = "vpc-046effd7e14742653"
  subnet_ids           = ["subnet-08b19374efcede225", "subnet-01fd8508db302e82c", "subnet-0af7c75104c35cbde"]

  apply_immediately                      = true
  cloudwatch_log_group_retention_in_days = 90
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["postgresql"]

  create_security_group = false

  alarms = {
    sns_topic = "default"

    # If you want overwrite existing values
    custom_values = {
      cpu = {
        statistic = "avg"
        threshold = "90"
        period    = "300"

        creditbalance = {
          period    = "1800"
          threshold = "10"
          equation  = "lt"
          statistic = "avg"
        }
      }

      burstbalance = {
        period    = "1800"
        threshold = "10"
        equation  = "lt"
        statistic = "avg"
      }

      ebs = {
        IObalance = {
          period    = "1800"
          threshold = "10"
          equation  = "lt"
          statistic = "avg"
        }
        bytebalance = {
          period    = "1800"
          threshold = "10"
          equation  = "lt"
          statistic = "avg"
        }
      }

      memory = {
        period    = "1800"
        threshold = "80"
        equation  = "lt"
        statistic = "avg"
      }

      network = {

        read = {
          period    = "60"
          threshold = "1"
          equation  = "gte"
          statistic = "avg"
        }

        write = {
          period    = "60"
          threshold = "1"
          equation  = "gte"
          statistic = "avg"
        }
      }

      connections = {
        period    = "60"
        threshold = "1200"
        statistic = "avg"
      }

      disk = {
        period    = "300"
        threshold = "90"
        statistic = "avg"
      }
    }
  }
}
