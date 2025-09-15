locals {
  podAnnotations = merge(var.configs.monitoring.enabled && var.configs.monitoring.method == "annotations" ? {
    "prometheus.io/scrape" = "true"
    "prometheus.io/port"   = var.configs.monitoring.targetPort
    } : {},
    { "app.config/checksum" = sha256(jsonencode(merge(var.configs, var.extra_configs))) } # to rollout restart deploy on config change
  )

  defaultPort = try(var.configs.mysql.ports[0], 3306)

  serviceAnnotations = var.configs.setLinkerdOpaquePorts ? {
    "config.linkerd.io/opaque-ports" = join(",", concat(var.configs.mysql.ports, [var.configs.admin.port]))
  } : {}

  service = {
    port = local.defaultPort
    extraPorts = concat(
      [{
        port       = var.configs.admin.port # admin port
        targetPort = var.configs.admin.port
        protocol   = "TCP"
        name       = "admin"
      }],
      var.configs.monitoring.enabled ? [{
        port       = var.configs.monitoring.targetPort # prometheus monitoring port
        targetPort = var.configs.monitoring.targetPort
        protocol   = "TCP"
        name       = "metrics"
      }] : [],
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
    annotations = local.serviceAnnotations
  }
  containerExtraPorts = [for item in local.service.extraPorts : {
    name          = item.name
    protocol      = item.protocol
    containerPort = item.targetPort
  }]

  volumes = [
    {
      name      = "proxysql-config"
      mountPath = "/etc/proxysql.cnf"
      subPath   = "proxysql.cnf"
      readOnly  = true
      configMap = {
        name : var.name
      }
    },
    {
      name      = "proxysql-cert"
      mountPath = "/etc/proxysql/certs/ca-cert.pem"
      subPath   = "ca-cert.pem"
      readOnly  = true
      configMap = {
        name : "${var.name}-cert"
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
