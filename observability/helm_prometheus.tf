locals {
  prometheus_values = {
    server = {
      replicaCount = var.prometheus_server_replicas
      retention    = var.prometheus_local_retention

      global = {
        scrape_interval     = var.prometheus_scrape_interval
        evaluation_interval = var.prometheus_scrape_interval

        # Every series carries the cluster it came from, which is what lets one
        # Mimir hold metrics from both production clusters and this one.
        external_labels = {
          cluster = var.cluster_name
        }
      }

      persistentVolume = {
        enabled = var.prometheus_persistence_enabled
        size    = var.prometheus_persistence_size
      }

      # Local storage is a buffer, not the archive: the archive is Mimir.
      remoteWrite = [
        {
          url = local.mimir_remote_write_url

          queue_config = {
            capacity             = var.prometheus_remote_write_capacity
            max_shards           = var.prometheus_remote_write_max_shards
            max_samples_per_send = var.prometheus_remote_write_max_samples
          }
        }
      ]
    }

    alertmanager = {
      enabled = var.prometheus_alertmanager_enabled
    }

    "kube-state-metrics" = {
      enabled = var.prometheus_kube_state_metrics_enabled
    }

    "prometheus-node-exporter" = {
      enabled = var.prometheus_node_exporter_enabled
    }

    "prometheus-pushgateway" = {
      enabled = var.prometheus_pushgateway_enabled
    }
  }
}

resource "helm_release" "prometheus" {
  name             = var.prometheus_release_name
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false

  repository = var.prometheus_chart_repository
  chart      = var.prometheus_chart_name
  version    = var.prometheus_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.prometheus_values)]

  depends_on = [helm_release.mimir]
}
