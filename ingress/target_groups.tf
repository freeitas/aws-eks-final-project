# One target group per production cluster. Terraform never registers targets:
# each cluster owns a TargetGroupBinding, and its AWS Load Balancer Controller
# registers the pod IPs of the workload Service into the group named here.
#
# The health check is deliberately generic: port "traffic-port" (the same port
# the group serves on) and path "/". No root in this project installs a service
# mesh or an ingress gateway, so there is no mesh-specific probe endpoint to
# point at. Set health_check_path and health_check_port to whatever the
# registered pods actually answer -- a probe aimed at software the cluster does
# not run leaves every target unhealthy and the listener returning 503.
#
# APPLY ORDER: clusters/ -> peering/ -> ingress/.
# Both groups are created in the VPC of alb_vpc_cluster_name, but one of them
# holds pod IPs that live in the other production cluster's VPC. Those targets
# only pass their health check once the peering root has connected the two VPCs
# and routed between them, so apply peering/ before this root. This root neither
# creates nor reads any peering resource.
#
# The port is part of the name on purpose. target_port forces a new target
# group, create_before_destroy has the old and the new one exist at the same
# time, and a target group name has to be unique -- so a name that did not move
# with the port would make every target_port change fail with
# DuplicateTargetGroupName instead of replacing the group cleanly.
resource "aws_lb_target_group" "prod_01" {
  name                 = "${var.name_prefix}-${var.prod_01_cluster_name}-${var.target_port}"
  vpc_id               = local.vpc_id
  port                 = var.target_port
  protocol             = "HTTP"
  protocol_version     = "HTTP1"
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.health_check_path
    port                = var.health_check_port
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = var.target_group_stickiness_enabled
    cookie_duration = var.target_group_stickiness_duration
  }

  tags = {
    Name    = "${var.name_prefix}-${var.prod_01_cluster_name}-${var.target_port}"
    Cluster = var.prod_01_cluster_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "prod_02" {
  name                 = "${var.name_prefix}-${var.prod_02_cluster_name}-${var.target_port}"
  vpc_id               = local.vpc_id
  port                 = var.target_port
  protocol             = "HTTP"
  protocol_version     = "HTTP1"
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.health_check_path
    port                = var.health_check_port
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = var.target_group_stickiness_enabled
    cookie_duration = var.target_group_stickiness_duration
  }

  tags = {
    Name    = "${var.name_prefix}-${var.prod_02_cluster_name}-${var.target_port}"
    Cluster = var.prod_02_cluster_name
  }

  lifecycle {
    create_before_destroy = true
  }
}
