resource "helm_release" "proxysql" {
  name             = var.name
  chart            = "proxysql"
  repository       = "https://dasmeta.github.io/helm"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = [jsonencode(module.custom_default_configs.merged)]
}

module "custom_default_configs" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    {
      proxysql = {
        containerPort  = local.defaultPort
        autoscaling    = var.configs.autoscaling
        resources      = var.configs.resources
        admin          = var.configs.admin
        stats          = var.configs.stats
        mysql          = var.configs.mysql
        podMonitor     = local.podMonitor
        podAnnotations = local.podAnnotations
        volumes        = local.volumes
        envFrom        = local.envFrom
        service        = local.service
        web            = local.web
      }
    },
    var.extra_configs
  ]
}
