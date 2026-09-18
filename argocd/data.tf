data "aws_partition" "current" {}

data "aws_ssm_parameter" "argocd_endpoint" {
  name = "/eks/${var.argocd_cluster_name}/endpoint"
}

data "aws_ssm_parameter" "argocd_certificate_authority" {
  name = "/eks/${var.argocd_cluster_name}/certificate_authority"
}

data "aws_ssm_parameter" "argocd_oidc_provider_arn" {
  name = "/eks/${var.argocd_cluster_name}/oidc_provider_arn"
}

data "aws_eks_cluster_auth" "argocd" {
  name = var.argocd_cluster_name
}

data "aws_iam_openid_connect_provider" "argocd" {
  arn = data.aws_ssm_parameter.argocd_oidc_provider_arn.value
}

data "aws_ssm_parameter" "prod_01_endpoint" {
  name = "/eks/${var.prod_01_cluster_name}/endpoint"
}

data "aws_ssm_parameter" "prod_01_certificate_authority" {
  name = "/eks/${var.prod_01_cluster_name}/certificate_authority"
}

data "aws_ssm_parameter" "prod_01_cluster_arn" {
  name = "/eks/${var.prod_01_cluster_name}/cluster_arn"
}

# Published by the clusters root, which owns the per-cluster access role. Reading the
# ARN keeps this root from rebuilding it out of a role name that can silently drift.
data "aws_ssm_parameter" "prod_01_access_role_arn" {
  name = "/eks/${var.prod_01_cluster_name}/argocd_access_role_arn"
}

data "aws_ssm_parameter" "prod_02_endpoint" {
  name = "/eks/${var.prod_02_cluster_name}/endpoint"
}

data "aws_ssm_parameter" "prod_02_certificate_authority" {
  name = "/eks/${var.prod_02_cluster_name}/certificate_authority"
}

data "aws_ssm_parameter" "prod_02_cluster_arn" {
  name = "/eks/${var.prod_02_cluster_name}/cluster_arn"
}

data "aws_ssm_parameter" "prod_02_access_role_arn" {
  name = "/eks/${var.prod_02_cluster_name}/argocd_access_role_arn"
}
