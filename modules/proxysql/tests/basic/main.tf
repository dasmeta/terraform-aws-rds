locals {
  eks_name = "eks"
}

module "proxysql" {
  source = "../../"

  name = "proxysql"

  proxysql_config = {
    replicas = 2
    username = "proxysqladmin"
    password = "proxysqladmin"
  }

  mysql_config = {
    max_connections        = 20480
    query_retries          = 5
    timeout                = 28800000
    hostname               = "<hostname>.<region>.rds.amazonaws.com"
    port                   = 3306
    hostgroup              = 1
    server_max_connections = 10000
    username               = "admin"
    password               = "admin"
    readwritesplit         = false
    default_hostgroup      = 1
    user_max_connections   = 10000
  }
}
