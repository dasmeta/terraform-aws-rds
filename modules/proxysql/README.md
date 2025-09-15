## This terraform module allows to create proxysql as deployment in terraform, for more details what proxysql is check here https://proxysql.com/

### NOTES:
- the new version of this module brings lot of incompatible changes in params so when upgrading from module version <=1.4.4 to version >1.4.4 make sure to check module params
- the maxConnections/max_connections parameters should be carefully set for based on instance types and proxysql replicas counts as in case if you have higher value set this can bring sql connection limit exceeded errors in client side
- for upgrading from <=1.8.3 to >=1.9.0 version of proxysql check parameters placement as server/users/roles params got moved from inside var.configs.mysql.* params group to one level up. Also the naming of var.configs.mysql.* param items has been switched to proxysql native snake_case. The new 1.9.0 version bring several improvements for proxysql. The main change is aws aurora integration support with instance auto-discovery(check [./examples/basic-with-rds-auto-scale/](./examples/basic-with-rds-auto-scale/))

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
      server_version = "8.0.37"
    }

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
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.proxysql](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The helm chart version | `string` | `"0.2.0"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | ProxySQL common configurations. If there is need to override underlying default configs or do additional chart supported configs in plain way use var.configs | <pre>object({<br/>    readWriteSplit = optional(bool, false) # this option allows to enable read and write splitting rules under mysql_query_rules config/table, the write ones go to hostgroup=0 and read ones go to hostgroup=1. NOTE: we can enable this if we have at least one server in read/write servers hostgroups, for example if we manually set at least one server for each host group in servers list<br/><br/>    admin = object({    # admin user credentials, this is required to set explicitly for security to not use default ones by mistake<br/>      user     = string # the username of proxysql admin user, ProxySql manages/stores its configs in its admin mysql database and one can use this credentials to connect to proxysql admin mysql server, service default port is 6032<br/>      password = string<br/>      port     = optional(number, 6032)<br/>    })<br/>    stats = optional(object({ # create a separate user in admin mysql server for using to access only statistics data, the web ui also uses this user for auth; this user is for internal/private use by default, so if you expose web ui endpoint make sure to set strong user/password<br/>      user       = optional(string, "sadmin")<br/>      password   = optional(string, "sadmin")<br/>      webEnabled = optional(bool, false) # allows to enable admin web UI(auth by stats user/password), with port forward the endpoint will be(https is must): https://127.0.0.1:6080/<br/>      webPort    = optional(number, 6080)<br/>    }), {})<br/>    servers = list(object({                            # list of mysql backend/target server instances, where each instance can be read or write type, NOTE: if you have just configured just one write server make sure to set readWriteSplit=false<br/>      hostname            = string                     # the hostname/domain/ip of backend mysql server<br/>      is_writer           = optional(bool, true)       # whether the server is write/main/master<br/>      status              = optional(string, "ONLINE") # the server accessible status, possible values are ONLINE/SHUNNED/OFFLINE_SOFT/OFFLINE_HARD<br/>      max_connections     = optional(number, 340)      # the server/backend max connection count is based on aws instance type(or if you have mysql on premise it maybe configurable) and there is some expression to calculate this instanceMemoryInBytes/12582880, the value 300 may be used for 4GB memory instances like db.t3.medium<br/>      port                = optional(number, 3306)     # the port of backend server<br/>      compression         = optional(bool, false)      # whether to enable compression<br/>      weight              = optional(number, 1000)     # a value indicating the server's capacity relative to others in the same hostgroup. Used for load balancing<br/>      max_replication_lag = optional(number, 0)        # specifies the maximum acceptable replication lag (in seconds) for a read replica. in case if read replica have higher lag it will be disabled until lag will be acceptable again. maxReplicationLag=0 means the replication lag check is disabled.<br/>      use_ssl             = optional(number, 0)        # whether ssl/tls enabled for proxysql=>mysql backend server connection<br/>      comment             = optional(string, "")       # the comment for server entry, NOTE: in case of aws aurora integration we create one seed server entry to cluster writes endpoint with comment="Aurora"<br/>    }))<br/>    users = list(object({ # the list of backend server(the target mysql server) users, this users will be also used in client side to connect/communicate through proxysql with backend servers<br/>      username               = string<br/>      password               = string<br/>      max_connections        = optional(number, 340) # this limit is per node/server<br/>      use_ssl                = optional(number, 0)   # whether ssl/tls enforcing enabled for client=>proxysql connection<br/>      transaction_persistent = optional(number, 1)   # whether transaction all queries will go to same backend or not, so that rules will be ignored<br/>      active                 = optional(number, 1)   # whether the user is enabled<br/>      read_only              = optional(bool, false) # this controls user default_hostgroup, in case if true default_hostgroup=1 (meaning default hostgroup is write one if no rule matches), in case of false default_hostgroup=2 (write hostgroup)<br/>    }))<br/>    rules = optional(list(object({                   # the list of query routing rule, NOTES: order is important; one of `digest`, `match_digest` and `match_pattern` should be provided and `digest` have higher priority over rest two; also when readWriteSplit=true it will add additional 2 rules in the start and end of rules list to route queries to write/read hostgroups based on query type<br/>      digest                = optional(string, null) # the query digest hash value<br/>      match_digest          = optional(string, null) # match_digest regex string, this is case sensitive<br/>      match_pattern         = optional(string, null) # match_pattern regex string, this is case insensitive by default and can be used to cover all type of cased same queries<br/>      destination_hostgroup = optional(number, 0)    # the hostgroup to which queries will be routed, by default it is 0 meaning that queries will be routed to writes hostgroup<br/>      use_ssl               = optional(number, 0)    # whether ssl/tls enforcing enabled for client=>proxysql connection<br/>      cache_ttl             = optional(number, null) # whether caching enabled and how long will it remain, the number value is in milliseconds<br/>      active                = optional(number, 1)    # when set to 1 no further queries will be evaluated after this rule is matched and processed<br/>      apply                 = optional(number, 1)    # whether the rule is enabled<br/>      proxy_port            = optional(number, null) # the port to use to filter coming queries for the rule, if not passed the rule will apply to all ports<br/>    })), [])<br/>    mysql = object({                                            # mysql configuration, NOTE: not all config items included here, if you have need to change some other options consider using var.extra_configs.app.mysql.*<br/>      server_version           = optional(string, "8.4.4")      # the ProxySQL by itself acts as mysql server and here we configure the version of mysql server of proxysql<br/>      ports                    = optional(list(number), [3306]) # mysql ports available for clients, by default we have single port setup but if there is need new ports can be added and in conjunction with rules proxy_port option we can have custom query routes, for example we can route all queries to write server for a port<br/>      max_connections          = optional(number, 20480)        # the maximum number of client connections that ProxySQL will accept<br/>      query_retries_on_failure = optional(number, 3)            # the number of times ProxySQL will retry a query if it fails<br/>      wait_timeout             = optional(number, 28800000)     # the timeout (in milliseconds) for a client connection to remain idle before it is closed, the current value 28800000 ms = 8 hours<br/>      query_cache_size_mb      = optional(number, 226)          # the size of ProxySQL's query cache in megabytes<br/>      monitor = optional(object({                               # the backend endpoint monitor, this is handy to fast detect failed/removed nodes at scale down, master failover or read replica lags to react on changes to not have much downtime, NOTE: the monitor have lot of custom config options which can be set via var.extra_configs.app.monitor.* (or var.extra_configs.app.mysql.* if not preset in helm chart) config fields<br/>        enabled  = optional(bool, false)                        # whether monitor is enabled<br/>        username = optional(string, "monitor")                  # the monitor user name, NOTE: there is need to create this user or user existing one with appropriate "USAGE, REPLICATION CLIENT" permissions, check docs for more info, for RDS clusters we can use the default user<br/>        password = optional(string, "monitor")                  # the monitor user password<br/>      }), {})<br/>    })<br/>    awsAurora = optional(object({         # allows to configure aws aurora backend specific configurations, so that proxysql will auto-discover the endpoints and switch of an backend server endpoint(with its connection) on scale down or handle master failover, NOTE: the rest of aurora proxysql integration configs can be set via var.extra_configs.app.awsAurora.* config items, beside setting this there is also need to set one seed item in servers list<br/>      enabled     = optional(bool, false) # whether aurora proxysql integration is enabled<br/>      domain_name = optional(string, "")  # the aurora instances endpoints suffix in form ".<some-uniq-hash>.<region>.rds.amazonaws.com"<br/>    }), {})<br/>    monitoring = optional( # prometheus metrics configs, `method` can be "annotations", "podMonitor" or "serviceMonitor"<br/>      object({<br/>        enabled    = optional(bool, true),<br/>        method     = optional(string, "annotations")<br/>        targetPort = optional(number, 6070)<br/>    }), {})<br/>    autoscaling = optional( # auto scale configs<br/>      object({ minReplicas = number, maxReplicas = number }),<br/>      { minReplicas = 2, maxReplicas = 10 }<br/>    )<br/>    resources = optional(object({ # replicas resource request/limits, this config values are mostly based on maxConnections count and queyCacheSizeMB values, so if you want more connections and more caching you may need to change this values also<br/>      limits = optional(object({<br/>        cpu    = optional(string, "100m")<br/>        memory = optional(string, "256Mi")<br/>        }), {<br/>        cpu    = "100m"<br/>        memory = "256Mi"<br/>      })<br/>      requests = optional(object({<br/>        cpu    = optional(string, "100m")<br/>        memory = optional(string, "256Mi")<br/>        }), {<br/>        cpu    = "100m"<br/>        memory = "256Mi"<br/>      })<br/>    }), {})<br/>    setLinkerdOpaquePorts = optional(bool, true) # this allows to automatically set linkerd annotation like `config.linkerd.io/opaque-ports: 3306,3307,6032` on proxysql service to fix linkerd enabled client app connection long lasting issues to non standard mysql tcp ports like extra 3307 port<br/>  })</pre> | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create namespace | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Configurations to pass and override/extend default ones. NOTE: the extra configs for proxysql are placed under proxysql root field. Check the helm chart available configs here: https://github.com/dasmeta/helm/tree/proxysql-0.1.0/charts/proxysql | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of helm release | `string` | `"proxysql"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace | `string` | `"proxysql"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_meta"></a> [helm\_meta](#output\_helm\_meta) | The helm chart release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
