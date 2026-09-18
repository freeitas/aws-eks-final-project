data "aws_iam_policy_document" "mimir_assume_role" {
  statement {
    sid     = "MimirWebIdentity"
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
      values   = ["system:serviceaccount:${var.namespace}:${var.mimir_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "mimir" {
  name               = "${var.name_prefix}-${var.cluster_name}-mimir"
  description        = "IRSA role assumed by Mimir. It reaches its own block bucket and nothing else."
  assume_role_policy = data.aws_iam_policy_document.mimir_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "mimir" {
  statement {
    sid    = "ListMimirBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [aws_s3_bucket.mimir.arn]
  }

  statement {
    sid    = "ReadWriteMimirObjects"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.mimir.arn}/*"]
  }
}

resource "aws_iam_policy" "mimir" {
  name        = "${var.name_prefix}-${var.cluster_name}-mimir"
  description = "Read and write access to the Mimir block bucket."
  policy      = data.aws_iam_policy_document.mimir.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "mimir" {
  role       = aws_iam_role.mimir.name
  policy_arn = aws_iam_policy.mimir.arn
}
