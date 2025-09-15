resource "helm_release" "proxysql" {
  name             = var.name
  chart            = "proxysql"
  repository       = "https://dasmeta.github.io/helm"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = [
    jsonencode({
      proxysql = {
        containerPort = local.defaultPort
        autoscaling   = var.configs.autoscaling
        resources     = var.configs.resources
        app = {
          readWriteSplit = var.configs.readWriteSplit
          admin          = var.configs.admin
          stats          = var.configs.stats
          servers        = var.configs.servers
          users          = var.configs.users
          rules          = var.configs.rules
          mysql          = var.configs.mysql
          awsAurora      = var.configs.awsAurora
        }
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
    }),
    jsonencode({ proxysql = var.extra_configs })
  ]
}
