data "aws_iam_policy_document" "loki_assume_role" {
  statement {
    sid     = "LokiWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.${local.dns_suffix}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.loki_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "loki" {
  name               = "${var.name_prefix}-${var.cluster_name}-loki"
  description        = "IRSA role assumed by Loki. It reaches its own chunk bucket and nothing else."
  assume_role_policy = data.aws_iam_policy_document.loki_assume_role.json
  tags               = local.tags
}

# Scoped to one bucket on purpose: a log flood must never be able to touch the
# trace or the metric store.
data "aws_iam_policy_document" "loki" {
  statement {
    sid    = "ListLokiBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [aws_s3_bucket.loki.arn]
  }

  statement {
    sid    = "ReadWriteLokiObjects"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.loki.arn}/*"]
  }
}

resource "aws_iam_policy" "loki" {
  name        = "${var.name_prefix}-${var.cluster_name}-loki"
  description = "Read and write access to the Loki chunk bucket."
  policy      = data.aws_iam_policy_document.loki.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "loki" {
  role       = aws_iam_role.loki.name
  policy_arn = aws_iam_policy.loki.arn
}
