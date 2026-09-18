# Mimir block store. Metrics outlive both other signals, so this bucket carries
# the longest expiration and Mimir's own compactor retention matches it.
resource "aws_s3_bucket" "mimir" {
  bucket        = local.mimir_bucket_name
  force_destroy = var.force_destroy_buckets
}

resource "aws_s3_bucket_public_access_block" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  rule {
    id     = "expire-blocks"
    status = "Enabled"

    filter {}

    expiration {
      days = var.mimir_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_upload_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.mimir]
}
