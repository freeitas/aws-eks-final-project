output "cluster_name" {
  description = "Name of the EKS cluster created by this root."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint of the cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data of the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider used by IRSA on this cluster."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "Issuer URL of the cluster OIDC provider, without the scheme."
  value       = local.oidc_issuer
}

output "vpc_id" {
  description = "Identifier of the VPC hosting the cluster."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Identifiers of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Identifiers of the private subnets."
  value       = aws_subnet.private[*].id
}

output "node_group_arn" {
  description = "ARN of the managed node group."
  value       = aws_eks_node_group.this.arn
}

output "node_role_arn" {
  description = "ARN of the IAM role attached to the node group instances."
  value       = aws_iam_role.nodes.arn
}

output "alb_controller_role_arn" {
  description = "ARN of the IRSA role assumed by the AWS Load Balancer Controller."
  value       = aws_iam_role.alb_controller.arn
}

output "vpc_cidr" {
  description = "Primary IPv4 CIDR block of the VPC hosting the cluster."
  value       = aws_vpc.this.cidr_block
}

output "private_route_table_ids" {
  description = "Identifiers of the private route tables, the tables a peering root adds remote routes to."
  value       = aws_route_table.private[*].id
}

output "node_security_group_id" {
  description = "Identifier of the EKS managed security group carried by the node group instances."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "argocd_access_role_arn" {
  description = "ARN of the IAM role the ArgoCD control plane assumes into this cluster, or null when create_argocd_access_role is false."
  value       = one(aws_iam_role.argocd_access[*].arn)
}
