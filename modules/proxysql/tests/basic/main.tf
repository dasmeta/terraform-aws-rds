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
    version = "8.0.37"
    servers = [
      {
        hostname       = "<write-server-hostname>"
        isWriter       = true
        maxConnections = 340
      },
      {
        hostname       = "<read-server-hostname>"
        isWriter       = false
        maxConnections = 340
      }
    ]
    users = [{
      username       = "<servers-db-user>"
      password       = "<servers-db-password>"
      maxConnections = 340
      readOnly       = false
    }]
  }
}
