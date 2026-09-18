# Registers each production cluster with ArgoCD. The control plane reaches them by
# assuming the access role named in awsAuthConfig, so no kubeconfig or service
# account token is ever written into the secret.
resource "kubernetes_secret" "managed_cluster" {
  for_each = local.managed_clusters

  metadata {
    name      = each.key
    namespace = var.argocd_namespace
    labels    = merge(each.value.labels, local.cluster_secret_labels)
  }

  type = "Opaque"

  data = {
    name   = each.key
    server = each.value.endpoint

    config = jsonencode({
      awsAuthConfig = {
        clusterName = each.key
        roleARN     = each.value.access_role_arn
      }

      tlsClientConfig = {
        insecure = false
        caData   = each.value.certificate_authority
      }
    })
  }

  depends_on = [
    helm_release.argocd
  ]
}
