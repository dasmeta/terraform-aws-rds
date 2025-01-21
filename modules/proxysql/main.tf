resource "helm_release" "proxysql" {
  name       = var.name
  chart      = "christianhuth/proxysql"
  repository = "https://charts.christianhuth.de"
  namespace  = var.namespace

  values = [
    templatefile(
      "${path.module}/values.yaml",
      {
        replica_count                = var.proxysql_config.replicas
        proxysql_admin_user          = var.proxysql_config.username
        proxysql_admin_password      = var.proxysql_config.password
        mysql_max_connections        = var.mysql_config.max_connections
        mysql_query_retries          = var.mysql_config.query_retries
        mysql_wait_timeout           = var.mysql_config.timeout
        mysql_server_hostname        = var.mysql_config.hostname
        mysql_server_port            = var.mysql_config.port
        mysql_server_hostgroup       = var.mysql_config.hostgroup
        mysql_server_max_connections = var.mysql_config.server_max_connections
        mysql_user_username          = var.mysql_config.username
        mysql_user_password          = var.mysql_config.password
        mysql_user_default_hostgroup = var.mysql_config.default_hostgroup
        mysql_user_max_connections   = var.mysql_config.user_max_connections
        readwritesplit               = var.mysql_config.readwritesplit
      }
    )
  ]

  depends_on = [
    kubernetes_namespace.proxysql
  ]
}

resource "kubernetes_namespace" "proxysql" {
  metadata {
    name = var.namespace
  }
}
