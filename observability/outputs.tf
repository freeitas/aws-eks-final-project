output "namespace" {
  description = "Namespace the whole LGTM stack is installed in."
  value       = kubernetes_namespace.this.metadata[0].name
}

output "loki_bucket_name" {
  description = "Bucket holding the Loki chunks."
  value       = aws_s3_bucket.loki.bucket
}

output "tempo_bucket_name" {
  description = "Bucket holding the Tempo trace blocks."
  value       = aws_s3_bucket.tempo.bucket
}

output "mimir_bucket_name" {
  description = "Bucket holding the Mimir metric blocks."
  value       = aws_s3_bucket.mimir.bucket
}

output "loki_irsa_role_arn" {
  description = "Role Loki assumes through IRSA. It reaches the chunk bucket and nothing else."
  value       = aws_iam_role.loki.arn
}

output "tempo_irsa_role_arn" {
  description = "Role Tempo assumes through IRSA. It reaches the trace bucket and nothing else."
  value       = aws_iam_role.tempo.arn
}

output "mimir_irsa_role_arn" {
  description = "Role Mimir assumes through IRSA. It reaches the block bucket and nothing else."
  value       = aws_iam_role.mimir.arn
}

output "loki_push_url" {
  description = "Address a log shipper writes to. FluentBit in this cluster uses it, and a shipper in a production cluster reaches the same path through the internal load balancer."
  value       = "${local.loki_gateway_url}${local.loki_push_path}"
}

output "tempo_otlp_grpc_endpoint" {
  description = "OTLP gRPC endpoint spans are exported to."
  value       = local.tempo_otlp_grpc_endpoint
}

output "mimir_remote_write_url" {
  description = "Endpoint a Prometheus remote writes its samples to."
  value       = local.mimir_remote_write_url
}

output "grafana_url" {
  description = "Address Grafana answers on, with all three datasources provisioned behind it."
  value       = local.grafana_root_url
}

output "helm_releases" {
  description = "Chart versions this root has installed, one entry per component of the stack."
  value = {
    loki                    = helm_release.loki.version
    tempo                   = helm_release.tempo.version
    mimir                   = helm_release.mimir.version
    grafana                 = helm_release.grafana.version
    prometheus              = helm_release.prometheus.version
    fluent_bit              = helm_release.fluent_bit.version
    opentelemetry_collector = helm_release.opentelemetry_collector.version
  }
}
