variable "name" {
  type        = string
  description = "The name of helm release"
  default     = "proxysql"
}

variable "namespace" {
  type        = string
  description = "Namespace"
  default     = "proxysql"
}

variable "create_namespace" {
  type        = bool
  description = "Whether to create namespace"
  default     = true
}

variable "chart_version" {
  type        = string
  description = "The helm chart version"
  default     = "1.2.1"
}

variable "configs" {
  type = object({
    image = optional(object({ # the proxysql docker image repo/tag configs
      repository = optional(string, "proxysql/proxysql")
      tag        = optional(string, "3.0.5")
    }), {})
    pdb = optional(object({ # enable pdb with min available=1 default by as this is critical app
      enabled      = optional(bool, true)
      minAvailable = optional(number, 1)
    }), {})
    databaseType   = optional(string, "mysql") # the proxysql mode/database-type, supported values are "mysql" and "pgsql"
    readWriteSplit = optional(bool, false)     # this option allows to enable read and write splitting rules under mysql_query_rules config/table, the write ones go to hostgroup=0 and read ones go to hostgroup=1. NOTE: we can enable this if we have at least one server in read/write servers hostgroups, for example if we manually set at least one server for each host group in servers list

    admin = object({    # admin user credentials, this is required to set explicitly for security to not use default ones by mistake
      user     = string # the username of proxysql admin user, ProxySql manages/stores its configs in its admin mysql database and one can use this credentials to connect to proxysql admin mysql server, service default port is 6032
      password = string
      port     = optional(number, 6032)
    })
    stats = optional(object({ # create a separate user in admin mysql server for using to access only statistics data, the web ui also uses this user for auth; this user is for internal/private use by default, so if you expose web ui endpoint make sure to set strong user/password
      user       = optional(string, "sadmin")
      password   = optional(string, "sadmin")
      webEnabled = optional(bool, false) # allows to enable admin web UI(auth by stats user/password), with port forward the endpoint will be(https is must): https://127.0.0.1:6080/
      webPort    = optional(number, 6080)
    }), {})
    servers = list(object({                            # list of mysql backend/target server instances, where each instance can be read or write type, NOTE: if you have just configured just one write server make sure to set readWriteSplit=false
      hostname            = string                     # the hostname/domain/ip of backend mysql server
      is_writer           = optional(bool, true)       # whether the server is write/main/master
      status              = optional(string, "ONLINE") # the server accessible status, possible values are ONLINE/SHUNNED/OFFLINE_SOFT/OFFLINE_HARD
      max_connections     = optional(number, 340)      # the server/backend max connection count is based on aws instance type(or if you have mysql on premise it maybe configurable) and there is some expression to calculate this instanceMemoryInBytes/12582880, the value 300 may be used for 4GB memory instances like db.t3.medium
      port                = optional(number, 3306)     # the port of backend server, defaults to mysql default 3306 port, set 5432 for postgresql backend endpoints default port
      compression         = optional(bool, false)      # whether to enable compression
      weight              = optional(number, 1000)     # a value indicating the server's capacity relative to others in the same hostgroup. Used for load balancing
      max_replication_lag = optional(number, 0)        # specifies the maximum acceptable replication lag (in seconds) for a read replica. in case if read replica have higher lag it will be disabled until lag will be acceptable again. maxReplicationLag=0 means the replication lag check is disabled.
      use_ssl             = optional(number, 0)        # whether ssl/tls enabled for proxysql=>mysql backend server connection
      comment             = optional(string, "")       # the comment for server entry, NOTE: in case of aws aurora integration we create one seed server entry to cluster writes endpoint with comment="Aurora"
    }))
    users = list(object({ # the list of backend server(the target mysql server) users, this users will be also used in client side to connect/communicate through proxysql with backend servers
      username               = string
      password               = string
      max_connections        = optional(number, 340) # this limit is per node/server
      use_ssl                = optional(number, 0)   # whether ssl/tls enforcing enabled for client=>proxysql connection
      transaction_persistent = optional(number, 1)   # whether transaction all queries will go to same backend or not, so that rules will be ignored
      active                 = optional(number, 1)   # whether the user is enabled
      read_only              = optional(bool, false) # this controls user default_hostgroup, in case if true default_hostgroup=1 (meaning default hostgroup is write one if no rule matches), in case of false default_hostgroup=2 (write hostgroup)
    }))
    rules = optional(list(object({                   # the list of query routing rule, NOTES: order is important; one of `digest`, `match_digest` and `match_pattern` should be provided and `digest` have higher priority over rest two; also when readWriteSplit=true it will add additional 2 rules in the start and end of rules list to route queries to write/read hostgroups based on query type
      digest                = optional(string, null) # the query digest hash value
      match_digest          = optional(string, null) # match_digest regex string, this is case sensitive
      match_pattern         = optional(string, null) # match_pattern regex string, this is case insensitive by default and can be used to cover all type of cased same queries
      destination_hostgroup = optional(number, 0)    # the hostgroup to which queries will be routed, by default it is 0 meaning that queries will be routed to writes hostgroup
      use_ssl               = optional(number, 0)    # whether ssl/tls enforcing enabled for client=>proxysql connection
      cache_ttl             = optional(number, null) # whether caching enabled and how long will it remain, the number value is in milliseconds
      active                = optional(number, 1)    # when set to 1 no further queries will be evaluated after this rule is matched and processed
      apply                 = optional(number, 1)    # whether the rule is enabled
      proxy_port            = optional(number, null) # the port to use to filter coming queries for the rule, if not passed the rule will apply to all ports
    })), [])
    mysql = optional(object({                                   # mysql configuration, NOTE: not all config items included here, if you have need to change some other options consider using var.extra_configs.app.mysql.*
      server_version           = optional(string, "8.4.4")      # the ProxySQL middleware by itself acts as mysql server and here we configure the version of mysql server of proxysql
      ports                    = optional(list(number), [3306]) # mysql ports available for clients, by default we have single port setup but if there is need new ports can be added and in conjunction with rules proxy_port option we can have custom query routes, for example we can route all queries to write server for a port
      max_connections          = optional(number, 20480)        # the maximum number of client connections that ProxySQL will accept
      query_retries_on_failure = optional(number, 3)            # the number of times ProxySQL will retry a query if it fails
      wait_timeout             = optional(number, 28800000)     # the timeout (in milliseconds) for a client connection to remain idle before it is closed, the current value 28800000 ms = 8 hours
      query_cache_size_mb      = optional(number, 226)          # the size of ProxySQL's query cache in megabytes
      monitor = optional(object({                               # the backend endpoint monitor, this is handy to fast detect failed/removed nodes at scale down, master failover or read replica lags to react on changes to not have much downtime, NOTE: the monitor have lot of custom config options which can be set via var.extra_configs.app.monitor.* (or var.extra_configs.app.mysql.* if not preset in helm chart) config fields
        enabled  = optional(bool, false)                        # whether monitor is enabled
        username = optional(string, "monitor")                  # the monitor user name, NOTE: there is need to create this user or user existing one with appropriate "USAGE, REPLICATION CLIENT" permissions, check docs for more info, for RDS clusters we can use the default user
        password = optional(string, "monitor")                  # the monitor user password
      }), {})
    }), {})
    pgsql = optional(object({                                     # pgsql/postgresql configuration, NOTE: not all config items included here, if you have need to change some other options consider using var.extra_configs.app.pgsql.*
      server_version             = optional(string, "17.7")       # the ProxySQL middleware by itself acts as postgresql server and here we configure the version of postgresql server of proxysql
      ports                      = optional(list(number), [5432]) # postgresql ports available for clients, by default we have single port setup but if there is need new ports can be added and in conjunction with rules proxy_port option we can have custom query routes, for example we can route all queries to write server for a port
      threads                    = optional(number, 3)            # the number of postgres threads
      have_ssl                   = optional(bool, true)           # indicates PostgreSQL SSL support availability and configuration status.
      max_connections            = optional(number, 2048)         # the maximum number of client connections that ProxySQL will accept
      connect_timeout_client     = optional(number, 10000)        # timeout (ms) for client connections during PostgreSQL protocol handshake (default: 10000)
      connect_timeout_server     = optional(number, 1000)         # default timeout (ms) for establishing connections to PostgreSQL backend servers (default: 1000)
      connect_timeout_server_max = optional(number, 10000)        # maximum timeout (ms) for connecting to PostgreSQL backend servers (default: 10000)
      default_query_delay        = optional(number, 0)            # default imposed query delay
      default_query_timeout      = optional(number, 36000000)     # default query timeout for backend queries
      query_retries_on_failure   = optional(number, 3)            # the number of times ProxySQL will retry a query if it fails
      poll_timeout               = optional(number, 2000)         # minimal timeout used to detect incoming/outgoing traffic via the `poll` syscall
      ping_timeout_server        = optional(number, 500)          # how long proxysql waits for those keep-alive pings to succeed before it drops that one backend connection (it does not mark the server down)
      commands_stats             = optional(bool, true)           # create stats about the received commands
      monitor = optional(object({                                 # the backend endpoint monitor, this is handy to fast detect failed/removed nodes at scale down, master failover or read replica lags to react on changes to not have much downtime, NOTE: the monitor have lot of custom config options which can be set via var.extra_configs.app.monitor.* (or var.extra_configs.app.mysql.* if not preset in helm chart) config fields
        enabled  = optional(bool, false)                          # whether monitor is enabled
        username = optional(string, "monitor")                    # the monitor user name, NOTE: there is need to create this user or user existing one with appropriate "USAGE, REPLICATION CLIENT" permissions, check docs for more info, for RDS clusters we can use the default user
        password = optional(string, "monitor")                    # the monitor user password
      }), {})
    }), {})
    awsAurora = optional(object({         # allows to configure aws aurora backend specific configurations, so that proxysql will auto-discover the endpoints and switch of an backend server endpoint(with its connection) on scale down or handle master failover, NOTE: the rest of aurora proxysql integration configs can be set via var.extra_configs.app.awsAurora.* config items, beside setting this there is also need to set one seed item in servers list
      enabled     = optional(bool, false) # whether aurora proxysql integration is enabled
      domain_name = optional(string, "")  # the aurora instances endpoints suffix in form ".<some-uniq-hash>.<region>.rds.amazonaws.com"
    }), {})
    scheduledRestart = optional(object({                           # used as workaround with aws rds aurora with autoscaling enabled to cleanup auto-discovered and removed/scaled-down instances endpoints, it do rollout restart of proxysql deployment based on specified schedule, for more info check here: https://github.com/sysown/proxysql/issues/3883#issuecomment-3753200770
      enabled                 = optional(bool, false)              # whether scheduled restart is enabled
      schedule                = optional(string, "00 02 */10 * *") # at 02:00 am UTC once every 10 day
      timeZone                = optional(string, "Etc/UTC")        # the timezone of schedule
      concurrencyPolicy       = optional(string, "Forbid")         # the k8s cronjob concurrency policy
      startingDeadlineSeconds = optional(number, 60)               # the k8s cronjob deadline seconds
      restartPolicy           = optional(string, "Never")          # the k8s cronjob restart policy
      image = optional(object({                                    # job container image configs
        repository = optional(string, "dasmeta/awscli-kubectl")
        tag        = optional(string, "1.34.2")
      }), {})
    }), {})
    monitoring = optional( # prometheus metrics configs, `method` can be "annotations", "podMonitor" or "serviceMonitor"
      object({
        enabled    = optional(bool, true),
        method     = optional(string, "annotations")
        targetPort = optional(number, 6070)
    }), {})
    autoscaling = optional( # auto scale configs
      object({ minReplicas = number, maxReplicas = number }),
      { minReplicas = 2, maxReplicas = 10 }
    )
    resources = optional(object({ # replicas resource request/limits, this config values are mostly based on maxConnections count and queyCacheSizeMB values, so if you want more connections and more caching you may need to change this values also
      limits = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "256Mi")
        }), {
        cpu    = "100m"
        memory = "256Mi"
      })
      requests = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "256Mi")
        }), {
        cpu    = "100m"
        memory = "256Mi"
      })
    }), {})
    setLinkerdOpaquePorts = optional(bool, true) # this allows to automatically set linkerd annotation like `config.linkerd.io/opaque-ports: 3306,3307,6032` on proxysql service to fix linkerd enabled client app connection long lasting issues to non standard mysql tcp ports like extra 3307 port
  })
  description = "ProxySQL common configurations. If there is need to override underlying default configs or do additional chart supported configs in plain way use var.configs"
  sensitive   = true # we have user password data here so we set this variable sensitive to not expose it in tf logs
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Configurations to pass and override/extend default ones. NOTE: the extra configs for proxysql are placed under proxysql root field. Check the helm chart available configs here: https://github.com/dasmeta/helm/tree/proxysql-0.1.0/charts/proxysql"
}
