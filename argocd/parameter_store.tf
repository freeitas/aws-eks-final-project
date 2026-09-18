resource "aws_ssm_parameter" "argocd_server_host" {
  name        = "/eks/argocd/server_host"
  description = "Hostname the ArgoCD control plane is reachable on."
  type        = "String"
  value       = var.argocd_host

  depends_on = [
    helm_release.argocd
  ]
}
