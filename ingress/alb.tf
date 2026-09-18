resource "aws_lb" "this" {
  name               = local.alb_name
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids

  idle_timeout               = var.idle_timeout
  enable_http2               = true
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"
  ip_address_type            = "ipv4"

  access_logs {
    bucket  = aws_s3_bucket.access_logs.id
    prefix  = var.access_logs_prefix
    enabled = var.enable_access_logs
  }

  tags = {
    Name = local.alb_name
  }

  # The subnets are discovered by tag, so an empty or single result means the
  # clusters/ root that owns alb_vpc_cluster_name has not been applied yet.
  # Say that in the plan instead of letting the apply fail inside AWS with a
  # generic "at least two subnets in two Availability Zones" error.
  lifecycle {
    precondition {
      condition     = length(data.aws_subnets.public.ids) >= 2
      error_message = "Fewer than two subnets in the ALB VPC carry the kubernetes.io/role/elb tag. Apply the clusters/ root for alb_vpc_cluster_name first."
    }
  }

  depends_on = [aws_s3_bucket_policy.access_logs]
}
