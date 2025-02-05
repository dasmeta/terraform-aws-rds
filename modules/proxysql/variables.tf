variable "name" {
  type        = string
  description = "Name"
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
  default     = "1.3.2"
}

variable "proxysql_config" {
  type = object({
    replicas = optional(number, 2) # the number of proxysql pods/replicas
    resources = optional(object({  # ProxySQL replicas resource request/limits, this config values are mostly based on maxConnections count and queyCacheSizeMB values, so if you want more connections and more caching you may need to change this values also
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
    username = string # the username of proxysql admin user(ProxySql manages/stores its configs in mysql database and one can use this credentials to connect to proxysql admin mysql server, service default port is 6032)
    password = string # the password of proxysql admin user
  })
  description = "ProxySQL configuration, including replicas and admin credentials."
}

variable "mysql_config" {
  type = object({
    servers = list(object({                      # list of mysql backend/target server instances, where each instance can be read or write type
      hostname          = string                 # the hostname/domain/ip of backend mysql server
      isWriter          = optional(bool, true)   # whether the server is write/main/master
      maxConnections    = optional(number, 340)  # the server/backend max connection count is based on aws instance type(or if you have mysql on premise it maybe configurable) and there is some expression to calculate this instanceMemoryInBytes/12582880, the value 300 may be used for 4GB memory instances like db.t3.medium
      port              = optional(number, 3306) # the port of backend server
      compression       = optional(bool, false)  # whether to enable compression
      weight            = optional(number, 1000) # a value indicating the server's capacity relative to others in the same hostgroup. Used for load balancing
      maxReplicationLag = optional(number, 0)    # this field specifies the maximum acceptable replication lag (in seconds) for a read replica. in case if read replica have higher lag it will be disabled until lag will be acceptable again. maxReplicationLag=0 means the replication lag check is disabled.
    }))
    users = list(object({ # the list of backend server(the target mysql server) users, this users will be also used in client side to connect/communicate through proxysql with backend servers
      username       = string
      password       = string
      maxConnections = optional(number, 340) # this limit is per node/server
      readOnly       = optional(bool, false) # this controls user default_hostgroup, in case if true default_hostgroup=1 (meaning default hostgroup is write one if no rule matches), in case of false default_hostgroup=2 (write hostgroup)
    }))
    slave = optional(object({
      enabled   = optional(bool, true) # enables/sets config of write/read hostgroups by having hostgroup=1 as write and hostgroup=2 as read
      checkType = optional(string, "read_only")
    }), {})
    version               = optional(string, "5.7.34") # the ProxySQL by itself acts as mysql server and here we configure the version of mysql server of proxysql
    port                  = optional(number, 3306)     # ProxySQL mysql port.
    maxConnections        = optional(number, 20480)    # the maximum number of client connections that ProxySQL will accept
    queryRetriesOnFailure = optional(number, 5)        # the number of times ProxySQL will retry a query if it fails
    waitTimeout           = optional(number, 28800000) # the timeout (in milliseconds) for a client connection to remain idle before it is closed, the current value 28800000 ms = 8 hours
    readwritesplit        = optional(bool, true)       # this option allows to enable read and write splitting rules under mysql_query_rules config/table (unfortunately this rules are not configurable/customable), the write ones go to hostgroup=1 and read ones go to hostgroup=2
    queyCacheSizeMB       = optional(number, 226)      # the size of ProxySQL's query cache in megabytes
  })
  description = "MySQL configuration, including connections, retries, and optional server/user details."
}

variable "configs" {
  type        = any
  default     = {}
  description = "Configurations to pass and override default ones. Check the helm chart available configs here: https://artifacthub.io/packages/helm/christianhuth/proxysql"
}
