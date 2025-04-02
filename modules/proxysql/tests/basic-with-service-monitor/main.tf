module "this" {
  source = "../../"

  name = "proxysql"
  # namespace = "localhost"

  configs = {
    admin = {
      user     = "proxysqladmin"
      password = "<proxysqladmin-pass-here>"
    }
    mysql = {
      version = "8.0.37"
      servers = [
        {
          hostname = "mysql.localhost"
        }
      ]
      users = [{
        username = "root"
        password = "<mysql-user-pass-here>"
      }]
    }
    monitoring = { enabled = true, method = "serviceMonitor" }
  }
}
