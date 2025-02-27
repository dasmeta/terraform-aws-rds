## This terraform module allows to create proxysql as deployment in terraform, for more details what proxysql is check here https://proxysql.com/

### NOTES:
- the new version of this module brings lot of incompatible changes in params so when upgrading from module version <=1.4.4 to version >1.4.4 make sure to check module params
- the maxConnections/max_connections parameters should be carefully set for based on instance types and proxysql replicas counts as in case if you have higher value set this can bring sql connection limit exceeded errors in client side

### basic example

```terraform
module "proxysql" {
  source = "dasmeta/rds/aws//modules/proxysql"

  name = "proxysql"

  configs = {
    admin = {
      user     = "proxysqladmin"
      password = "<proxysqladmin-pass-here>"
    }
    mysql = {
      version = "8.0.37"
      servers = [
        {
          hostname  = "mysql.localhost"
        }
      ]
      users = [{
        username = "root"
        password = "<mysql-user-pass-here>"
      }]
    }
  }
}
```
