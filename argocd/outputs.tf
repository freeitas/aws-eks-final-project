output "argocd_server_host" {
  description = "Hostname the ArgoCD API and UI answer on."
  value       = var.argocd_host
}

output "argocd_server_host_parameter" {
  description = "Parameter Store entry other roots read to discover the ArgoCD control plane."
  value       = aws_ssm_parameter.argocd_server_host.name
}

output "argocd_namespace" {
  description = "Namespace the ArgoCD release is installed in."
  value       = helm_release.argocd.namespace
}

output "argocd_chart_version" {
  description = "Version of the ArgoCD chart that is installed."
  value       = helm_release.argocd.version
}

output "argocd_irsa_role_arn" {
  description = "Role the ArgoCD controllers assume through IRSA."
  value       = aws_iam_role.argocd.arn
}

output "registered_clusters" {
  description = "Cluster names registered in ArgoCD as external clusters."
  value       = keys(kubernetes_secret.managed_cluster)
}

output "managed_cluster_role_arns" {
  description = "Access role assumed on each registered production cluster."
  value       = local.managed_cluster_role_arns
}

output "application_set_name" {
  description = "ApplicationSet whose cluster generator fans out to every registered production cluster."
  value       = var.application_set_name
}
