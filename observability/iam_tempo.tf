data "aws_iam_policy_document" "tempo_assume_role" {
  statement {
    sid     = "TempoWebIdentity"
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
      values   = ["system:serviceaccount:${var.namespace}:${var.tempo_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "tempo" {
  name               = "${var.name_prefix}-${var.cluster_name}-tempo"
  description        = "IRSA role assumed by Tempo. It reaches its own trace bucket and nothing else."
  assume_role_policy = data.aws_iam_policy_document.tempo_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "tempo" {
  statement {
    sid    = "ListTempoBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [aws_s3_bucket.tempo.arn]
  }

  statement {
    sid    = "ReadWriteTempoObjects"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.tempo.arn}/*"]
  }
}

resource "aws_iam_policy" "tempo" {
  name        = "${var.name_prefix}-${var.cluster_name}-tempo"
  description = "Read and write access to the Tempo trace bucket."
  policy      = data.aws_iam_policy_document.tempo.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "tempo" {
  role       = aws_iam_role.tempo.name
  policy_arn = aws_iam_policy.tempo.arn
}
