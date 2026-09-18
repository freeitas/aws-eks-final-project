# Both manifests are custom resources owned by ArgoCD, so this root is applied after
# helm_release.argocd has installed the CRDs on the control plane cluster.
resource "kubernetes_manifest" "argo_project" {
  manifest = {
    apiVersion = "${var.argo_api_group}/v1alpha1"
    kind       = "AppProject"

    metadata = {
      name      = var.argo_project_name
      namespace = var.argocd_namespace
    }

    spec = {
      description = "Workloads delivered by the control plane to the active/active production clusters."
      sourceRepos = local.argo_project_source_repos

      destinations = [
        for cluster_name in keys(local.managed_clusters) : {
          name      = cluster_name
          namespace = "*"
        }
      ]

      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  }

  depends_on = [
    helm_release.argocd
  ]
}

resource "kubernetes_manifest" "application_set" {
  manifest = {
    apiVersion = "${var.argo_api_group}/v1alpha1"
    kind       = "ApplicationSet"

    metadata = {
      name      = var.application_set_name
      namespace = var.argocd_namespace
    }

    spec = {
      goTemplate = false

      # One Application definition, fanned out to every cluster secret carrying the
      # selector labels, which is what puts the same workload on both prod clusters.
      generators = [
        {
          clusters = {
            selector = {
              matchLabels = var.cluster_generator_match_labels
            }
          }
        }
      ]

      template = {
        metadata = {
          name = "${var.application_set_name}-{{name}}"
        }

        spec = {
          project = var.argo_project_name

          # Plain git source: the manifests live in the repository itself, so a sync
          # depends on nothing but the repo the project already allows.
          source = {
            repoURL        = var.applications_repo_url
            targetRevision = var.applications_target_revision
            path           = var.applications_path
          }

          destination = {
            name      = "{{name}}"
            namespace = var.applications_namespace
          }

          syncPolicy = {
            automated = {
              prune    = var.application_sync_prune
              selfHeal = var.application_sync_self_heal
            }

            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.argo_project,
    kubernetes_secret.managed_cluster
  ]
}
