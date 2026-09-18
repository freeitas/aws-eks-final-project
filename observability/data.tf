data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# The only cross root coupling in this project: the clusters/ root publishes one
# parameter set per cluster it builds. No terraform_remote_state anywhere.
data "aws_ssm_parameter" "cluster_endpoint" {
  name = "/eks/${var.cluster_name}/endpoint"
}

data "aws_ssm_parameter" "cluster_certificate_authority" {
  name = "/eks/${var.cluster_name}/certificate_authority"
}

data "aws_ssm_parameter" "cluster_oidc_provider_arn" {
  name = "/eks/${var.cluster_name}/oidc_provider_arn"
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

# Resolving the provider gives the issuer URL that every IRSA trust policy in
# this root conditions on, without hardcoding an account id or an issuer id.
data "aws_iam_openid_connect_provider" "this" {
  arn = data.aws_ssm_parameter.cluster_oidc_provider_arn.value
}
