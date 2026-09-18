locals {
  alb_name = "${var.name_prefix}-ingress"

  # The ALB and BOTH target groups live in a single VPC. The second production
  # cluster is reached over VPC peering: an ALB target group of type "ip" may
  # hold any RFC 1918 address, not only addresses from its own VPC.
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  host_headers = concat([var.dns_name], var.additional_host_headers)

  log_bucket_name = "${var.name_prefix}-alb-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = merge(var.tags, {
    Project   = var.project
    Root      = "ingress"
    ManagedBy = "terraform"
  })
}
