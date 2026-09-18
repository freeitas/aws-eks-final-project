locals {
  # The read path of the whole stack. All three stores are provisioned as
  # datasources, and the correlation links between them are what makes a trace
  # reachable from a log line and a service map reachable from a trace.
  grafana_datasources = [
    {
      name      = "Mimir"
      uid       = "mimir"
      type      = "prometheus"
      access    = "proxy"
      url       = local.mimir_query_url
      isDefault = true

      jsonData = {
        httpMethod     = "POST"
        prometheusType = "Mimir"
        timeInterval   = var.prometheus_scrape_interval
      }
    },
    {
      name      = "Loki"
      uid       = "loki"
      type      = "loki"
      access    = "proxy"
      url       = local.loki_gateway_url
      isDefault = false

      jsonData = {
        derivedFields = [
          {
            name          = "TraceID"
            matcherRegex  = var.grafana_trace_id_regex
            datasourceUid = "tempo"
            url           = "$${__value.raw}"
          }
        ]
      }
    },
    {
      name      = "Tempo"
      uid       = "tempo"
      type      = "tempo"
      access    = "proxy"
      url       = local.tempo_query_url
      isDefault = false

      jsonData = {
        tracesToLogsV2 = {
          datasourceUid      = "loki"
          spanStartTimeShift = "-1h"
          spanEndTimeShift   = "1h"
          filterByTraceID    = true
        }

        tracesToMetrics = {
          datasourceUid = "mimir"
        }

        serviceMap = {
          datasourceUid = "mimir"
        }

        nodeGraph = {
          enabled = true
        }
      }
    }
  ]
}

# The admin credential is deliberately absent: left unset, the chart generates a
# password and keeps it in its own Secret, so nothing lands in this repo.
locals {
  grafana_values = {
    replicas = var.grafana_replicas

    datasources = {
      "datasources.yaml" = {
        apiVersion  = 1
        datasources = local.grafana_datasources
      }
    }

    persistence = {
      enabled = var.grafana_persistence_enabled
      size    = var.grafana_persistence_size
    }

    ingress = {
      enabled          = var.grafana_ingress_enabled
      ingressClassName = var.grafana_ingress_class_name
      hosts            = [var.grafana_host]
      annotations      = var.grafana_ingress_annotations
    }

    "grafana.ini" = {
      server = {
        root_url = local.grafana_root_url
      }

      analytics = {
        reporting_enabled = false
        check_for_updates = false
      }
    }
  }
}

resource "helm_release" "grafana" {
  name             = var.grafana_release_name
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false

  repository = var.grafana_chart_repository
  chart      = var.grafana_chart_name
  version    = var.grafana_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.grafana_values)]

  depends_on = [
    helm_release.loki,
    helm_release.tempo,
    helm_release.mimir
  ]
}
