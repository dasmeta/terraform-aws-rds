## This terraform module allows to create proxysql

### TODO:
-  the underlying helm chart has limited configuration possibility, so it may appear that not everything we need for ProxySQL can be configured by using this module. Consider using another helm chart or developing new one(or forking used one and customizing). For example extra/custom rules and rds aurora specific configs (https://proxysql.com/documentation/aws-aurora-configuration/, https://proxysql.com/blog/aurora-failover-without-losing-transactions/)


### NOTES:
- the maxConnections/max_connections parameter should be carefully set for backend instance type as in case if you have higher value set this can bring sql connection limit exceeded errors in client side

### basic example

```terraform
module "proxysql" {
  source = "dasmeta/rds/aws//modules/proxysql"

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
      },
      {
        hostname       = "<read-server-hostname>"
        isWriter       = false
      }
    ]
    users = [{
      username       = "<servers-db-user>"
      password       = "<servers-db-password>"
    }]
  }
}
```
