resource "aws_ssm_parameter" "endpoint" {
  name        = "/eks/${var.cluster_name}/endpoint"
  description = "Kubernetes API endpoint of the ${var.cluster_name} cluster."
  type        = "String"
  value       = aws_eks_cluster.this.endpoint
  tags        = local.tags
}

resource "aws_ssm_parameter" "cluster_arn" {
  name        = "/eks/${var.cluster_name}/cluster_arn"
  description = "ARN of the ${var.cluster_name} EKS cluster."
  type        = "String"
  value       = aws_eks_cluster.this.arn
  tags        = local.tags
}

resource "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/eks/${var.cluster_name}/oidc_provider_arn"
  description = "ARN of the IAM OIDC provider backing IRSA on the ${var.cluster_name} cluster."
  type        = "String"
  value       = aws_iam_openid_connect_provider.this.arn
  tags        = local.tags
}

resource "aws_ssm_parameter" "certificate_authority" {
  name        = "/eks/${var.cluster_name}/certificate_authority"
  description = "Base64 encoded certificate authority data of the ${var.cluster_name} cluster."
  type        = "String"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  tags        = local.tags
}

resource "aws_ssm_parameter" "vpc_id" {
  name        = "/eks/${var.cluster_name}/vpc_id"
  description = "Identifier of the VPC hosting the ${var.cluster_name} cluster."
  type        = "String"
  value       = aws_vpc.this.id
  tags        = local.tags
}

resource "aws_ssm_parameter" "private_subnets" {
  name        = "/eks/${var.cluster_name}/private_subnets"
  description = "Comma separated private subnet identifiers of the ${var.cluster_name} cluster."
  type        = "StringList"
  value       = join(",", aws_subnet.private[*].id)
  tags        = local.tags
}

resource "aws_ssm_parameter" "vpc_cidr" {
  name        = "/eks/${var.cluster_name}/vpc_cidr"
  description = "Primary IPv4 CIDR block of the VPC hosting the ${var.cluster_name} cluster, used by other roots to build cross-VPC routes and security group rules."
  type        = "String"
  value       = aws_vpc.this.cidr_block
  tags        = local.tags
}

resource "aws_ssm_parameter" "private_route_table_ids" {
  name        = "/eks/${var.cluster_name}/private_route_table_ids"
  description = "Comma separated identifiers of the private route tables of the ${var.cluster_name} VPC, the tables a peering root has to add the remote CIDR to."
  type        = "StringList"
  value       = join(",", aws_route_table.private[*].id)
  tags        = local.tags
}

resource "aws_ssm_parameter" "node_security_group_id" {
  name        = "/eks/${var.cluster_name}/node_security_group_id"
  description = "Identifier of the EKS managed security group carried by the ${var.cluster_name} node group instances and by the control plane interfaces, the target of cross-VPC ingress rules."
  type        = "String"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  tags        = local.tags
}

resource "aws_ssm_parameter" "argocd_access_role_arn" {
  count = local.argocd_access_count

  name        = "/eks/${var.cluster_name}/argocd_access_role_arn"
  description = "ARN of the IAM role the ArgoCD control plane assumes to reach the Kubernetes API of the ${var.cluster_name} cluster."
  type        = "String"
  value       = aws_iam_role.argocd_access[0].arn
  tags        = local.tags
}
