locals {
  podAnnotations = merge(var.configs.monitoring.enabled && var.configs.monitoring.method == "annotations" ? {
    "prometheus.io/scrape" = "true"
    "prometheus.io/port"   = "6070"
    } : {},
    { "app.config/checksum" = sha256(jsonencode(merge(var.configs, var.extra_configs))) } # to rollout restart deploy on config change
  )

  podMonitor = var.configs.monitoring.enabled && var.configs.monitoring.method == "podMonitor" ? {
    enabled = true
  } : {}

  defaultPort = try(var.configs.mysql.ports[0], 3306)

  service = {
    port = local.defaultPort
    extraPorts = concat(
      [{
        port       = var.configs.admin.port # admin port
        targetPort = var.configs.admin.port
        protocol   = "TCP"
        name       = "admin"
      }],
      [for port in var.configs.mysql.ports : {
        port       = port # additional mysql ports
        targetPort = port
        protocol   = "TCP"
        name       = "mysql-${port}"
      } if port != local.defaultPort],
      var.configs.stats.webEnabled ? [{
        port       = var.configs.stats.webPort # web ui for statistics
        targetPort = var.configs.stats.webPort
        protocol   = "TCP"
        name       = "web"
      }] : []
    )
  }

  volumes = [
    {
      name      = "proxysql-config"
      mountPath = "/etc/proxysql.cnf"
      subPath   = "proxysql.cnf"
      readOnly  = true
      configMap = {
        name : var.name
      }
    }
  ]

  envFrom = {
    secret : var.name
  }

  web = {
    enabled = var.configs.stats.webEnabled
    port    = var.configs.stats.webPort
  }
}
