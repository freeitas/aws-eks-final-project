resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-${var.node_group.name}"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.node_group.instance_types
  capacity_type   = var.node_group.capacity_type
  ami_type        = var.node_group.ami_type
  disk_size       = var.node_group.disk_size
  labels          = var.node_group.labels

  scaling_config {
    desired_size = var.node_group.desired_size
    min_size     = var.node_group.min_size
    max_size     = var.node_group.max_size
  }

  update_config {
    max_unavailable = var.node_group.max_unavailable
  }

  tags = merge(local.tags, { Name = "${var.cluster_name}-${var.node_group.name}" })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker,
    aws_iam_role_policy_attachment.nodes_cni,
    aws_iam_role_policy_attachment.nodes_ecr,
    aws_iam_role_policy_attachment.nodes_ssm,
    aws_route.private_nat
  ]
}
