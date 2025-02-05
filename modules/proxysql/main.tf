resource "helm_release" "proxysql" {
  name             = var.name
  chart            = "proxysql"
  repository       = "https://charts.christianhuth.de"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace

  values = [jsonencode(module.custom_default_configs_merged.merged)]

}

module "custom_default_configs_merged" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    {
      replicaCount = var.proxysql_config.replicas
      resources    = var.proxysql_config.resources
      proxysql = {
        admin = {
          user     = var.proxysql_config.username
          password = var.proxysql_config.password
        }

        mysql = var.mysql_config
      }
    },
    var.configs
  ]
}
