module "this" {
  source = "../../"

  name = "proxysql-mysql-with-service-monitor"

  configs = {
    mysql = {
      server_version = "8.0.37"
    }
    admin = {
      user     = "proxysqladmin"
      password = "<proxysqladmin-pass-here>"
    }

    servers = [
      {
        hostname = "mysql.localhost"
      }
    ]
    users = [{
      username = "root"
      password = "test"
    }]

    monitoring = { enabled = true, method = "serviceMonitor" }
  }
}
