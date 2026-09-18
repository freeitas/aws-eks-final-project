output "alb_arn" {
  description = "ARN of the shared ingress ALB."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the shared ingress ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone of the ALB, the alias target zone for records pointing at it."
  value       = aws_lb.this.zone_id
}

output "alb_security_group_id" {
  description = "Security group attached to the ALB."
  value       = aws_security_group.alb.id
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener that carries the weighted forward action."
  value       = aws_lb_listener.https.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener that redirects to HTTPS."
  value       = aws_lb_listener.http.arn
}

output "target_group_arns" {
  description = "Target group ARN per production cluster. Each cluster references its own ARN from a TargetGroupBinding."
  value = {
    (var.prod_01_cluster_name) = aws_lb_target_group.prod_01.arn
    (var.prod_02_cluster_name) = aws_lb_target_group.prod_02.arn
  }
}

output "traffic_weights" {
  description = "Applied weight per production cluster. A cluster at 0 is drained out of rotation."
  value = {
    (var.prod_01_cluster_name) = var.prod_01_weight
    (var.prod_02_cluster_name) = var.prod_02_weight
  }
}

output "certificate_arn" {
  description = "ARN of the validated ACM certificate served by the HTTPS listener."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "fqdn" {
  description = "Public record that resolves to the ALB."
  value       = aws_route53_record.alias.fqdn
}

output "access_logs_bucket" {
  description = "Bucket receiving the ALB access logs."
  value       = aws_s3_bucket.access_logs.id
}
