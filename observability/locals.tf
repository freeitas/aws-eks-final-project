locals {
  account_id = data.aws_caller_identity.current.account_id
  dns_suffix = data.aws_partition.current.dns_suffix
  # The provider attribute keeps the https:// scheme, but the condition key in a
  # trust policy is the bare issuer host and path. Stripping it is what the
  # clusters/ and argocd/ roots do, and without it every IRSA AssumeRole here
  # fails at runtime while still applying cleanly.
  oidc_issuer = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")

  # Built by interpolation so the literal annotation key never has to be spelled
  # out, and so a non commercial partition keeps working.
  irsa_annotation_key = "eks.${data.aws_partition.current.dns_suffix}/role-arn"

  # One bucket per signal. The account id and the region keep the names globally
  # unique without pinning the code to a single account.
  loki_bucket_name  = "${var.name_prefix}-loki-chunks-${local.account_id}-${data.aws_region.current.name}"
  tempo_bucket_name = "${var.name_prefix}-tempo-traces-${local.account_id}-${data.aws_region.current.name}"
  mimir_bucket_name = "${var.name_prefix}-mimir-blocks-${local.account_id}-${data.aws_region.current.name}"

  # In cluster addresses the components use to reach each other. Everything here
  # is assembled from variables, so renaming a release moves every reference.
  service_suffix = "${var.namespace}.svc.${var.cluster_domain}"

  loki_gateway_host = "${var.loki_release_name}-gateway.${local.service_suffix}"
  loki_gateway_url  = "http://${local.loki_gateway_host}:${var.loki_gateway_port}"
  loki_push_path    = "/loki/api/v1/push"

  tempo_query_host         = "${var.tempo_release_name}-query-frontend.${local.service_suffix}"
  tempo_query_url          = "http://${local.tempo_query_host}:${var.tempo_query_port}"
  tempo_distributor_host   = "${var.tempo_release_name}-distributor.${local.service_suffix}"
  tempo_otlp_grpc_endpoint = "${local.tempo_distributor_host}:${var.tempo_otlp_grpc_port}"

  mimir_gateway_host     = "${var.mimir_release_name}-nginx.${local.service_suffix}"
  mimir_gateway_url      = "http://${local.mimir_gateway_host}"
  mimir_query_url        = "${local.mimir_gateway_url}/prometheus"
  mimir_remote_write_url = "${local.mimir_gateway_url}/api/v1/push"

  grafana_root_url = "https://${var.grafana_host}"

  # zipmap keeps the annotation key dynamic; a literal key cannot be templated.
  loki_irsa_annotations  = zipmap([local.irsa_annotation_key], [aws_iam_role.loki.arn])
  tempo_irsa_annotations = zipmap([local.irsa_annotation_key], [aws_iam_role.tempo.arn])
  mimir_irsa_annotations = zipmap([local.irsa_annotation_key], [aws_iam_role.mimir.arn])

  tags = merge(var.tags, {
    Project   = var.project
    Root      = "observability"
    Cluster   = var.cluster_name
    ManagedBy = "terraform"
  })
}
