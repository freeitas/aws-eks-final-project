resource "helm_release" "alb_controller" {
  name             = "aws-load-balancer-controller"
  repository       = var.alb_controller.chart_repository
  chart            = "aws-load-balancer-controller"
  version          = var.alb_controller.chart_version
  namespace        = var.alb_controller.namespace
  create_namespace = false
  atomic           = true
  wait             = true
  timeout          = 900

  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.this.id
  }

  set {
    name  = "replicaCount"
    value = var.alb_controller.replica_count
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.alb_controller.service_account
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }

  set {
    name  = "enableShield"
    value = "false"
  }

  set {
    name  = "enableWaf"
    value = "false"
  }

  set {
    name  = "enableWafv2"
    value = "false"
  }

  depends_on = [
    aws_eks_node_group.this,
    aws_eks_addon.coredns,
    aws_eks_addon.vpc_cni,
    aws_iam_role_policy_attachment.alb_controller
  ]
}
