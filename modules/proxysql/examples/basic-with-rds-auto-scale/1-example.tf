# proxysql with aurora specific mysql instrumentation
module "this" {
  source = "../../"

  name = "proxysql-aurora"

  configs = {
    admin = {
      user     = "proxysqladmin"
      password = "<proxysqladmin-pass-here>"
    }

    # we set seed item in list of servers as the servers will be auto discovered for rds aurora based on this seed item, we mark it with "Aurora" comment and set "SHUNNED" status to not get it be used by app client connections
    servers = [
      {
        hostname  = module.aurora_cluster.cluster_endpoint
        is_writer = false
        comment   = "Aurora"
        status    = "SHUNNED"
      }
    ]

    users = [{
      username = local.db_username
      password = local.db_password
    }]

    mysql = {
      server_version = "8.0.37"
      ports          = [3306]
      monitor = {
        enabled  = true
        username = local.db_username
        password = local.db_password
      }
    }

    awsAurora = {
      enabled     = true
      domain_name = module.aurora_cluster.cluster_instance_endpoint_suffix
    }

    readWriteSplit = true # we set this to have query rules to split read and write queries
    monitoring     = { enabled = true, method = "serviceMonitor" }
  }

  extra_configs = {
    lifecycle = { # here we override the lifecycle configs for testing purposes
      preStop = {
        exec = { command = ["sh", "-c", "touch /tmp/sigterm-signal-sent && sleep 5"] }
      }
    }
  }

  depends_on = [module.aurora_cluster]
}
