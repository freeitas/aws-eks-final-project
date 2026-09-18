# Cross-cluster access role. Created only where var.create_argocd_access_role is true
# (the production clusters). The ArgoCD control plane, which lives in another cluster
# and another VPC, assumes this role and is then bound to Kubernetes RBAC by the EKS
# access entry declared next to the other access entries of this root. Nothing here
# hardcodes an account id: the trusted principals arrive either as full ARNs or as role
# names resolved against the caller account.
#
# The two policy documents below are rendered unconditionally. When the role is turned
# off the trusted principal list is empty and the rendered documents are simply never
# attached to anything; the precondition on the role guarantees that a role that does
# get created always trusts at least one principal.
data "aws_iam_policy_document" "argocd_access_assume_role" {
  statement {
    sid     = "ArgoCDControlPlaneAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.argocd_access_trusted_principals
    }
  }
}

resource "aws_iam_role" "argocd_access" {
  count = local.argocd_access_count

  name               = local.argocd_access_role_name
  description        = "Role assumed by the ArgoCD control plane to authenticate against the ${var.cluster_name} Kubernetes API."
  assume_role_policy = data.aws_iam_policy_document.argocd_access_assume_role.json
  tags               = local.tags

  lifecycle {
    precondition {
      condition     = length(local.argocd_access_trusted_principals) > 0
      error_message = "create_argocd_access_role is true, so argocd_access_trusted_principal_arns or argocd_access_trusted_role_names must name at least one principal."
    }
  }
}

data "aws_iam_policy_document" "argocd_access" {
  statement {
    sid       = "DescribeThisCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [aws_eks_cluster.this.arn]
  }
}

resource "aws_iam_policy" "argocd_access" {
  count = local.argocd_access_count

  name        = local.argocd_access_role_name
  description = "Lets the ArgoCD access role of the ${var.cluster_name} cluster read the cluster description it needs to build an API token."
  policy      = data.aws_iam_policy_document.argocd_access.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "argocd_access" {
  count = local.argocd_access_count

  role       = aws_iam_role.argocd_access[0].name
  policy_arn = aws_iam_policy.argocd_access[0].arn
}
