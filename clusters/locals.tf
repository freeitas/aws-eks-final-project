locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.public_subnets)
  oidc_issuer       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
  tags              = merge(var.tags, { Cluster = var.cluster_name, ManagedBy = "terraform" })

  argocd_access_count     = var.create_argocd_access_role ? 1 : 0
  argocd_access_role_name = coalesce(var.argocd_access_role_name, "argocd-access-${var.cluster_name}")

  argocd_access_trusted_principals = concat(
    var.argocd_access_trusted_principal_arns,
    [
      for role_name in var.argocd_access_trusted_role_names :
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${role_name}"
    ]
  )
}
