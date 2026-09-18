locals {
  loki_values = {
    # Simple scalable: a write path, a read path and a backend, rather than the
    # full microservice split. Logs need the write path scaled, not six roles.
    deploymentMode = "SimpleScalable"

    loki = {
      auth_enabled = false

      commonConfig = {
        replication_factor = var.loki_replication_factor
      }

      storage = {
        type = "s3"

        bucketNames = {
          chunks = local.loki_bucket_name
          ruler  = local.loki_bucket_name
          admin  = local.loki_bucket_name
        }

        # No access keys and no endpoint: the SDK resolves the regional endpoint
        # and picks up the IRSA web identity from the projected token.
        s3 = {
          region = var.region
        }
      }

      schemaConfig = {
        configs = [
          {
            from         = var.loki_schema_from
            store        = "tsdb"
            object_store = "s3"
            schema       = "v13"

            index = {
              prefix = "loki_index_"
              period = "24h"
            }
          }
        ]
      }

      limits_config = {
        retention_period              = var.loki_retention_period
        reject_old_samples            = true
        reject_old_samples_max_age    = var.loki_reject_old_samples_max_age
        max_cache_freshness_per_query = "10m"
      }

      compactor = {
        retention_enabled    = true
        delete_request_store = "s3"
      }
    }

    serviceAccount = {
      create      = true
      name        = var.loki_service_account_name
      annotations = local.loki_irsa_annotations
    }

    write = {
      replicas = var.loki_write_replicas
    }

    read = {
      replicas = var.loki_read_replicas
    }

    backend = {
      replicas = var.loki_backend_replicas
    }

    # Single binary is the alternative to simple scalable; leaving it at zero
    # keeps the chart from rendering both.
    singleBinary = {
      replicas = 0
    }

    gateway = {
      enabled = true
    }

    chunksCache = {
      enabled = var.loki_caches_enabled
    }

    resultsCache = {
      enabled = var.loki_caches_enabled
    }

    lokiCanary = {
      enabled = false
    }

    test = {
      enabled = false
    }
  }
}

resource "helm_release" "loki" {
  name             = var.loki_release_name
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false

  repository = var.loki_chart_repository
  chart      = var.loki_chart_name
  version    = var.loki_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.loki_values)]

  depends_on = [
    aws_iam_role_policy_attachment.loki,
    aws_s3_bucket_public_access_block.loki
  ]
}
