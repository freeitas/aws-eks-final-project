locals {
  dns_suffix  = data.aws_partition.current.dns_suffix
  oidc_issuer = replace(data.aws_iam_openid_connect_provider.argocd.url, "https://", "")

  irsa_annotation_key      = "eks.${local.dns_suffix}/role-arn"
  argocd_secret_type_label = "argocd.${var.argo_api_group}/secret-type"
  argocd_irsa_annotations  = zipmap([local.irsa_annotation_key], [aws_iam_role.argocd.arn])
  cluster_secret_labels    = zipmap([local.argocd_secret_type_label], ["cluster"])

  service_account_subjects = [
    for component, service_account in var.argocd_service_accounts :
    "system:serviceaccount:${var.argocd_namespace}:${service_account}"
  ]

  managed_cluster_arns = [
    for cluster_name, cluster in local.managed_clusters :
    cluster.cluster_arn
  ]

  managed_cluster_role_arns = [
    for cluster_name, cluster in local.managed_clusters :
    cluster.access_role_arn
  ]

  # The repository the ApplicationSet renders from is always permitted by the project,
  # so the two can never disagree about where a generated Application may pull from.
  argo_project_source_repos = distinct(concat(
    [var.applications_repo_url],
    var.argo_project_additional_source_repos
  ))
}

locals {
  managed_clusters = {
    (var.prod_01_cluster_name) = {
      endpoint              = data.aws_ssm_parameter.prod_01_endpoint.value
      certificate_authority = data.aws_ssm_parameter.prod_01_certificate_authority.value
      cluster_arn           = data.aws_ssm_parameter.prod_01_cluster_arn.value
      access_role_arn       = data.aws_ssm_parameter.prod_01_access_role_arn.value
      labels                = var.prod_01_cluster_labels
    }

    (var.prod_02_cluster_name) = {
      endpoint              = data.aws_ssm_parameter.prod_02_endpoint.value
      certificate_authority = data.aws_ssm_parameter.prod_02_certificate_authority.value
      cluster_arn           = data.aws_ssm_parameter.prod_02_cluster_arn.value
      access_role_arn       = data.aws_ssm_parameter.prod_02_access_role_arn.value
      labels                = var.prod_02_cluster_labels
    }
  }
}
