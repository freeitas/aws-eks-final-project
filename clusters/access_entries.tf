resource "aws_eks_access_entry" "cluster_admin" {
  count = length(var.cluster_admin_principals)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_principals[count.index]
  type          = "STANDARD"
  tags          = local.tags
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  count = length(var.cluster_admin_principals)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_principals[count.index]
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.cluster_admin
  ]
}

# Kubernetes RBAC for the ArgoCD access role created in this root. Without this pair the
# role can obtain a token but every API call comes back Forbidden.
resource "aws_eks_access_entry" "argocd_access" {
  count = local.argocd_access_count

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.argocd_access[0].arn
  type          = "STANDARD"
  tags          = local.tags
}

resource "aws_eks_access_policy_association" "argocd_access" {
  count = local.argocd_access_count

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.argocd_access[0].arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.argocd_access
  ]
}
