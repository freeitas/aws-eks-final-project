locals {
  mimir_values = {
    serviceAccount = {
      create      = true
      name        = var.mimir_service_account_name
      annotations = local.mimir_irsa_annotations
    }

    mimir = {
      structuredConfig = {
        common = {
          storage = {
            backend = "s3"

            # Mimir's object store client refuses to start on an empty endpoint
            # ("no s3 endpoint in config file"). blocks_storage inherits it from
            # here, which is why only the common block carries it.
            s3 = {
              bucket_name = local.mimir_bucket_name
              endpoint    = "s3.${var.region}.${local.dns_suffix}"
              region      = var.region
            }
          }
        }

        blocks_storage = {
          backend = "s3"

          s3 = {
            bucket_name = local.mimir_bucket_name
          }

          tsdb = {
            dir = "/data/tsdb"
          }
        }

        limits = {
          compactor_blocks_retention_period = var.mimir_blocks_retention_period
          ingestion_rate                    = var.mimir_ingestion_rate
          ingestion_burst_size              = var.mimir_ingestion_burst_size
          max_global_series_per_user        = var.mimir_max_global_series_per_user
          max_label_names_per_series        = 40
        }
      }
    }

    distributor = {
      replicas = var.mimir_distributor_replicas
    }

    ingester = {
      replicas = var.mimir_ingester_replicas
    }

    querier = {
      replicas = var.mimir_querier_replicas
    }

    query_frontend = {
      replicas = var.mimir_query_frontend_replicas
    }

    store_gateway = {
      replicas = var.mimir_store_gateway_replicas
    }

    compactor = {
      replicas = var.mimir_compactor_replicas
    }

    # nginx is the Mimir gateway: one address for the write path Prometheus
    # pushes to and for the read path Grafana queries.
    nginx = {
      replicas = var.mimir_gateway_replicas
    }

    alertmanager = {
      enabled = false
    }

    ruler = {
      enabled = false
    }

    minio = {
      enabled = false
    }
  }
}

resource "helm_release" "mimir" {
  name             = var.mimir_release_name
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false

  repository = var.mimir_chart_repository
  chart      = var.mimir_chart_name
  version    = var.mimir_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.mimir_values)]

  depends_on = [
    aws_iam_role_policy_attachment.mimir,
    aws_s3_bucket_public_access_block.mimir
  ]
}
