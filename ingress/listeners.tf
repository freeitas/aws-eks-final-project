resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# The single weighted listener. The two weights ARE the traffic split and the
# drain mechanism: set one to 0, apply, and that cluster stops receiving new
# connections while the other keeps serving. Nothing else has to change.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.prod_01.arn
        weight = var.prod_01_weight
      }

      target_group {
        arn    = aws_lb_target_group.prod_02.arn
        weight = var.prod_02_weight
      }

      stickiness {
        enabled  = var.listener_stickiness_enabled
        duration = var.listener_stickiness_duration
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.prod_01_weight + var.prod_02_weight > 0
      error_message = "At least one production cluster must keep a weight above 0, otherwise the ALB answers every request with 503."
    }
  }
}

# Host based routing for the public hostnames, with the same split. Requests
# arriving with an unknown Host still fall through to the listener default.
resource "aws_lb_listener_rule" "host_based" {
  listener_arn = aws_lb_listener.https.arn
  priority     = var.listener_rule_priority

  condition {
    host_header {
      values = local.host_headers
    }
  }

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.prod_01.arn
        weight = var.prod_01_weight
      }

      target_group {
        arn    = aws_lb_target_group.prod_02.arn
        weight = var.prod_02_weight
      }

      stickiness {
        enabled  = var.listener_stickiness_enabled
        duration = var.listener_stickiness_duration
      }
    }
  }

  tags = {
    Name = "${local.alb_name}-host"
  }
}
