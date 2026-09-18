region      = "us-east-1"
project     = "eks-final-project"
name_prefix = "efp"

# The LGTM stack runs on its own cluster, away from the workloads it observes.
cluster_name   = "observability"
namespace      = "observability"
cluster_domain = "cluster.local"
helm_timeout   = 900

# Retention differs per signal, which is why each signal gets its own bucket.
force_destroy_buckets             = false
loki_retention_days               = 30
tempo_retention_days              = 15
mimir_retention_days              = 90
noncurrent_version_retention_days = 7
abort_incomplete_upload_days      = 7

# Loki, simple scalable: a write path, a read path and a backend.
loki_chart_repository           = "https://grafana.github.io/helm-charts"
loki_chart_name                 = "loki"
loki_chart_version              = "6.24.0"
loki_release_name               = "loki"
loki_service_account_name       = "loki"
loki_replication_factor         = 3
loki_schema_from                = "2024-04-01"
loki_retention_period           = "720h"
loki_reject_old_samples_max_age = "168h"
loki_write_replicas             = 3
loki_read_replicas              = 2
loki_backend_replicas           = 2
loki_caches_enabled             = true
loki_gateway_port               = 80

# Tempo, full microservices: only traces and metrics need their roles scaled apart.
tempo_chart_repository        = "https://grafana.github.io/helm-charts"
tempo_chart_name              = "tempo-distributed"
tempo_chart_version           = "1.18.3"
tempo_release_name            = "tempo"
tempo_service_account_name    = "tempo"
tempo_distributor_replicas    = 2
tempo_ingester_replicas       = 3
tempo_querier_replicas        = 2
tempo_query_frontend_replicas = 2
tempo_compactor_replicas      = 1
tempo_block_retention         = "336h"
tempo_query_port              = 3100
tempo_otlp_grpc_port          = 4317

# Mimir, full microservices, and the archive every Prometheus writes into.
mimir_chart_repository           = "https://grafana.github.io/helm-charts"
mimir_chart_name                 = "mimir-distributed"
mimir_chart_version              = "5.5.1"
mimir_release_name               = "mimir"
mimir_service_account_name       = "mimir"
mimir_blocks_retention_period    = "2160h"
mimir_ingestion_rate             = 100000
mimir_ingestion_burst_size       = 200000
mimir_max_global_series_per_user = 1500000
mimir_distributor_replicas       = 2
mimir_ingester_replicas          = 3
mimir_querier_replicas           = 2
mimir_query_frontend_replicas    = 2
mimir_store_gateway_replicas     = 2
mimir_compactor_replicas         = 1
mimir_gateway_replicas           = 2

# Grafana: the read path over all three stores.
grafana_chart_repository    = "https://grafana.github.io/helm-charts"
grafana_chart_name          = "grafana"
grafana_chart_version       = "8.8.2"
grafana_release_name        = "grafana"
grafana_replicas            = 2
grafana_host                = "grafana.example.com"
grafana_ingress_enabled     = true
grafana_ingress_class_name  = "alb"
grafana_persistence_enabled = true
grafana_persistence_size    = "10Gi"
grafana_trace_id_regex      = "trace_id=(\\w+)"

grafana_ingress_annotations = { "alb.ingress.kubernetes.io/scheme" = "internal", "alb.ingress.kubernetes.io/target-type" = "ip" }

# Prometheus scrapes this cluster and pushes everything into Mimir.
prometheus_chart_repository           = "https://prometheus-community.github.io/helm-charts"
prometheus_chart_name                 = "prometheus"
prometheus_chart_version              = "27.3.0"
prometheus_release_name               = "prometheus"
prometheus_server_replicas            = 1
prometheus_local_retention            = "6h"
prometheus_scrape_interval            = "30s"
prometheus_persistence_enabled        = true
prometheus_persistence_size           = "20Gi"
prometheus_remote_write_capacity      = 10000
prometheus_remote_write_max_shards    = 30
prometheus_remote_write_max_samples   = 2000
prometheus_alertmanager_enabled       = false
prometheus_kube_state_metrics_enabled = true
prometheus_node_exporter_enabled      = true
prometheus_pushgateway_enabled        = false

# FluentBit tails the container logs of this cluster and ships them to Loki.
fluent_bit_chart_repository = "https://fluent.github.io/helm-charts"
fluent_bit_chart_name       = "fluent-bit"
fluent_bit_chart_version    = "0.48.5"
fluent_bit_release_name     = "fluent-bit"
fluent_bit_flush_seconds    = 1
fluent_bit_log_level        = "info"
fluent_bit_mem_buf_limit    = "10MB"
fluent_bit_retry_limit      = 5

# The collector is the OTLP gateway in front of Tempo.
opentelemetry_collector_chart_repository  = "https://open-telemetry.github.io/opentelemetry-helm-charts"
opentelemetry_collector_chart_name        = "opentelemetry-collector"
opentelemetry_collector_chart_version     = "0.108.0"
opentelemetry_collector_release_name      = "otel-collector"
opentelemetry_collector_mode              = "deployment"
opentelemetry_collector_replicas          = 2
opentelemetry_collector_image_repository  = "otel/opentelemetry-collector-k8s"
opentelemetry_collector_batch_size        = 1024
opentelemetry_collector_batch_timeout     = "5s"
opentelemetry_collector_exporter_insecure = true

tags = { Environment = "observability", Owner = "platform" }
