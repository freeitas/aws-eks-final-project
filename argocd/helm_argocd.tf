locals {
  argocd_values = {
    global = {
      domain = var.argocd_host
    }

    configs = {
      params = {
        "server.insecure" = var.argocd_server_insecure
      }
    }

    controller = {
      replicas = var.argocd_controller_replicas

      serviceAccount = {
        create      = true
        name        = var.argocd_service_accounts.controller
        annotations = local.argocd_irsa_annotations
      }
    }

    server = {
      replicas = var.argocd_server_replicas

      serviceAccount = {
        create      = true
        name        = var.argocd_service_accounts.server
        annotations = local.argocd_irsa_annotations
      }

      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class_name
        hostname         = var.argocd_host
        annotations      = var.argocd_ingress_annotations
        tls              = false
      }
    }

    repoServer = {
      replicas = var.argocd_repo_server_replicas

      serviceAccount = {
        create      = true
        name        = var.argocd_service_accounts.repo_server
        annotations = local.argocd_irsa_annotations
      }
    }

    applicationSet = {
      replicas = var.argocd_application_set_replicas

      serviceAccount = {
        create      = true
        name        = var.argocd_service_accounts.application_set
        annotations = local.argocd_irsa_annotations
      }
    }

    "redis-ha" = {
      enabled = var.argocd_redis_ha_enabled
    }
  }
}

resource "helm_release" "argocd" {
  name             = var.argocd_release_name
  namespace        = var.argocd_namespace
  create_namespace = true

  repository = var.argocd_chart_repository
  chart      = var.argocd_chart_name
  version    = var.argocd_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.argocd_values)]

  depends_on = [
    aws_iam_role_policy_attachment.argocd_cluster_access
  ]
}
