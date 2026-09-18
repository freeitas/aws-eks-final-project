locals {
  opentelemetry_collector_values = {
    mode             = var.opentelemetry_collector_mode
    replicaCount     = var.opentelemetry_collector_replicas
    fullnameOverride = var.opentelemetry_collector_release_name

    # The chart refuses to render without an explicit image, so the distribution
    # is pinned here rather than inherited.
    image = {
      repository = var.opentelemetry_collector_image_repository
    }

    presets = {
      kubernetesAttributes = {
        enabled = true
      }
    }

    config = {
      receivers = {
        otlp = {
          protocols = {
            grpc = {
              endpoint = "0.0.0.0:4317"
            }

            http = {
              endpoint = "0.0.0.0:4318"
            }
          }
        }
      }

      processors = {
        batch = {
          send_batch_size = var.opentelemetry_collector_batch_size
          timeout         = var.opentelemetry_collector_batch_timeout
        }

        memory_limiter = {
          check_interval         = "5s"
          limit_percentage       = 80
          spike_limit_percentage = 25
        }
      }

      # Spans leave here for the Tempo distributor and nowhere else.
      exporters = {
        otlp = {
          endpoint = local.tempo_otlp_grpc_endpoint

          tls = {
            insecure = var.opentelemetry_collector_exporter_insecure
          }
        }
      }

      service = {
        pipelines = {
          traces = {
            receivers  = ["otlp"]
            processors = ["memory_limiter", "batch"]
            exporters  = ["otlp"]
          }
        }
      }
    }
  }
}

resource "helm_release" "opentelemetry_collector" {
  name             = var.opentelemetry_collector_release_name
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false

  repository = var.opentelemetry_collector_chart_repository
  chart      = var.opentelemetry_collector_chart_name
  version    = var.opentelemetry_collector_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.opentelemetry_collector_values)]

  depends_on = [helm_release.tempo]
}
