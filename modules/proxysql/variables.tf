variable "name" {
  type        = string
  description = "Name"
}

variable "namespace" {
  type        = string
  description = "Namespace"
  default     = "proxysql"
}

variable "proxysql_config" {
  type = any
  default = {
    replicas = 2
    username = "admin"
    password = "admin"
  }
  description = "ProxySQL configuration, including replicas and admin credentials."
}


variable "mysql_config" {
  type = any
  default = {
    max_connections        = 20480
    query_retries          = 5
    timeout                = 28800000
    hostname               = ""
    port                   = 3306
    hostgroup              = 1
    server_max_connections = 10000
    username               = "admin"
    password               = "admin"
    default_hostgroup      = 1
    user_max_connections   = 20480
    readwritesplit         = false
  }
  description = "MySQL configuration, including connections, retries, and optional server/user details."
}
