data "aws_iam_policy_document" "argocd_assume_role" {
  statement {
    sid     = "ArgoCDWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.argocd.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.${local.dns_suffix}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = local.service_account_subjects
    }
  }
}

resource "aws_iam_role" "argocd" {
  name               = "${var.project_name}-argocd-control-plane"
  description        = "Role assumed by the ArgoCD controllers through IRSA to reach the managed production clusters."
  assume_role_policy = data.aws_iam_policy_document.argocd_assume_role.json
}

data "aws_iam_policy_document" "argocd_cluster_access" {
  statement {
    sid       = "AssumeManagedClusterAccessRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = local.managed_cluster_role_arns
  }

  statement {
    sid       = "DescribeManagedClusters"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = local.managed_cluster_arns
  }

  statement {
    sid       = "ListClusters"
    effect    = "Allow"
    actions   = ["eks:ListClusters"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "argocd_cluster_access" {
  name        = "${var.project_name}-argocd-cluster-access"
  description = "Allows the ArgoCD control plane to assume the access role of every registered production cluster."
  policy      = data.aws_iam_policy_document.argocd_cluster_access.json
}

resource "aws_iam_role_policy_attachment" "argocd_cluster_access" {
  role       = aws_iam_role.argocd.name
  policy_arn = aws_iam_policy.argocd_cluster_access.arn
}
