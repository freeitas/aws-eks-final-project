locals {
  tempo_values = {
    serviceAccount = {
      create      = true
      name        = var.tempo_service_account_name
      annotations = local.tempo_irsa_annotations
    }

    storage = {
      trace = {
        backend = "s3"

        # Tempo reaches S3 through a minio-go client built from this endpoint,
        # so an empty one stops the ingesters starting. Loki is the exception in
        # this root: it resolves the regional endpoint through the AWS SDK.
        s3 = {
          bucket   = local.tempo_bucket_name
          endpoint = "s3.${var.region}.${local.dns_suffix}"
          region   = var.region
        }
      }
    }

    # The distributor accepts OTLP on both transports; the collector in every
    # production cluster is the only thing expected to write here.
    traces = {
      otlp = {
        grpc = {
          enabled = true
        }

        http = {
          enabled = true
        }
      }
    }

    distributor = {
      replicas = var.tempo_distributor_replicas
    }

    ingester = {
      replicas = var.tempo_ingester_replicas
    }

    querier = {
      replicas = var.tempo_querier_replicas
    }

    queryFrontend = {
      replicas = var.tempo_query_frontend_replicas
    }

    compactor = {
      replicas = var.tempo_compactor_replicas

      config = {
        compaction = {
          block_retention = var.tempo_block_retention
        }
      }
    }

    metricsGenerator = {
      enabled = false
    }

    # The chart ships MinIO for a self contained demo. The bucket this root
    # creates replaces it.
    minio = {
      enabled = false
    }
  }
}

resource "helm_release" "tempo" {
  name             = var.tempo_release_name
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false

  repository = var.tempo_chart_repository
  chart      = var.tempo_chart_name
  version    = var.tempo_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.tempo_values)]

  depends_on = [
    aws_iam_role_policy_attachment.tempo,
    aws_s3_bucket_public_access_block.tempo
  ]
}
