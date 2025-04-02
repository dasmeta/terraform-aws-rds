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
        podAnnotations = local.podAnnotations
        volumes        = local.volumes
        envFrom        = local.envFrom
        service        = local.service
        web            = local.web
        extraPorts     = local.containerExtraPorts
        serviceMonitor = {
          enabled    = var.configs.monitoring.enabled && var.configs.monitoring.method == "serviceMonitor"
          targetPort = var.configs.monitoring.targetPort
        }
      }
      podMonitor = {
        enabled    = var.configs.monitoring.enabled && var.configs.monitoring.method == "podMonitor"
        targetPort = var.configs.monitoring.targetPort
      }
    },
    var.extra_configs
  ]
}
