module "this" {
  source = "../../"

  name = "proxysql-basic-pgsql"

  configs = {
    databaseType = "pgsql"
    pgsql = {
      server_version = "18.1"
    }
    admin = {
      user     = "proxysqladmin"
      password = "<proxysqladmin-pass-here>"
    }
    servers = [
      {
        hostname = "postgresql.localhost"
        port     = 5432
      }
    ]
    users = [{
      username = "postgres"
      password = "test"
    }]

  }
}
