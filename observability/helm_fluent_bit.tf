locals {
  # FluentBit still takes classic INI sections, so the four blocks are assembled
  # as text. Every address in them comes from a variable, never a literal.
  fluent_bit_service_config = join("\n", [
    "[SERVICE]",
    "    Daemon        Off",
    "    Flush         ${var.fluent_bit_flush_seconds}",
    "    Log_Level     ${var.fluent_bit_log_level}",
    "    Parsers_File  /fluent-bit/etc/parsers.conf",
    "    HTTP_Server   On",
    "    HTTP_Listen   0.0.0.0",
    "    HTTP_Port     2020",
    ""
  ])

  fluent_bit_inputs_config = join("\n", [
    "[INPUT]",
    "    Name              tail",
    "    Tag               kube.*",
    "    Path              /var/log/containers/*.log",
    "    multiline.parser  cri",
    "    Mem_Buf_Limit     ${var.fluent_bit_mem_buf_limit}",
    "    Skip_Long_Lines   On",
    "    Refresh_Interval  10",
    "    DB                /var/log/flb_kube.db",
    ""
  ])

  fluent_bit_filters_config = join("\n", [
    "[FILTER]",
    "    Name                kubernetes",
    "    Match               kube.*",
    "    Merge_Log           On",
    "    Merge_Log_Key       log_processed",
    "    Keep_Log            Off",
    "    K8S-Logging.Parser  On",
    "    K8S-Logging.Exclude On",
    "    Labels              On",
    "    Annotations         Off",
    ""
  ])

  # The one place logs leave the cluster. Host and URI are derived from the Loki
  # release, so renaming that release cannot silently break shipping.
  fluent_bit_outputs_config = join("\n", [
    "[OUTPUT]",
    "    Name                   loki",
    "    Match                  kube.*",
    "    Host                   ${local.loki_gateway_host}",
    "    Port                   ${var.loki_gateway_port}",
    "    Uri                    ${local.loki_push_path}",
    "    Labels                 job=fluent-bit, cluster=${var.cluster_name}",
    "    Auto_Kubernetes_Labels On",
    "    Line_Format            json",
    "    Retry_Limit            ${var.fluent_bit_retry_limit}",
    ""
  ])

  fluent_bit_values = {
    config = {
      service = local.fluent_bit_service_config
      inputs  = local.fluent_bit_inputs_config
      filters = local.fluent_bit_filters_config
      outputs = local.fluent_bit_outputs_config
    }
  }
}

resource "helm_release" "fluent_bit" {
  name             = var.fluent_bit_release_name
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false

  repository = var.fluent_bit_chart_repository
  chart      = var.fluent_bit_chart_name
  version    = var.fluent_bit_chart_version

  timeout = var.helm_timeout
  atomic  = true

  values = [yamlencode(local.fluent_bit_values)]

  depends_on = [helm_release.loki]
}
