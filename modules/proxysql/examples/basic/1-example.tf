module "this" {
  source = "../../"

  name = "proxysql-basic"

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
      password = "root"
    }]

  }
}
