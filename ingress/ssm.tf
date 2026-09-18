# Published for the other roots. These three names are the contract; nothing
# else in the project may reach into this root's state.
resource "aws_ssm_parameter" "alb_arn" {
  name        = "/eks/ingress/alb_arn"
  description = "ARN of the shared ingress ALB that fronts both production clusters"
  type        = "String"
  value       = aws_lb.this.arn
}

resource "aws_ssm_parameter" "listener_arn" {
  name        = "/eks/ingress/listener_arn"
  description = "ARN of the HTTPS listener whose weighted forward action splits traffic between the production clusters"
  type        = "String"
  value       = aws_lb_listener.https.arn
}

resource "aws_ssm_parameter" "dns_name" {
  name        = "/eks/ingress/dns_name"
  description = "DNS name of the shared ingress ALB, the alias target of the public record"
  type        = "String"
  value       = aws_lb.this.dns_name
}
