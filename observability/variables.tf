variable "region" {
  description = "AWS region holding the observability cluster, its telemetry buckets and its IAM roles. Every root in this project is pinned to a single region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, applied as a tag to every resource created by this root."
  type        = string
  default     = "eks-multicluster"
}

variable "name_prefix" {
  description = "Prefix for the bucket and IAM names created by this root. Bucket names also carry the account id and the region, so the prefix stays short."
  type        = string
  default     = "efp"
}

variable "tags" {
  description = "Extra tags merged into the default tags applied to every resource created by this root."
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Cluster the LGTM stack is installed on. It is the key of the /eks/<cluster>/* parameters the clusters root publishes, and the value of the cluster label stamped on every metric series."
  type        = string
  default     = "observability"
}

variable "namespace" {
  description = "Kubernetes namespace every chart in this root is installed into. It is also the namespace each IRSA trust policy scopes its service account subject to."
  type        = string
  default     = "observability"
}

variable "cluster_domain" {
  description = "Internal DNS domain of the cluster. It closes the in-cluster service names the components use to reach each other."
  type        = string
  default     = "cluster.local"
}

variable "helm_timeout" {
  description = "Seconds a helm release may take before Terraform gives up and rolls it back."
  type        = number
  default     = 900
}

variable "force_destroy_buckets" {
  description = "Whether the telemetry buckets may be deleted while they still hold objects. Off by default so a destroy never silently drops retained telemetry."
  type        = bool
  default     = false
}

variable "loki_retention_days" {
  description = "Days a Loki chunk object is kept in S3 before the bucket lifecycle rule expires it. Keep it at or above the Loki retention period, which deletes on the read path."
  type        = number
  default     = 30
}

variable "tempo_retention_days" {
  description = "Days a Tempo trace block is kept in S3. Traces are the shortest lived signal: long enough to debug an incident, not long enough to report on."
  type        = number
  default     = 15
}

variable "mimir_retention_days" {
  description = "Days a Mimir block is kept in S3. Metrics outlive the other two signals, which is why each signal gets its own bucket."
  type        = number
  default     = 90
}

variable "noncurrent_version_retention_days" {
  description = "Days a noncurrent object version survives in any of the three telemetry buckets before it is expired."
  type        = number
  default     = 7
}

variable "abort_incomplete_upload_days" {
  description = "Days an incomplete multipart upload is kept before S3 aborts it and reclaims the parts. Every component here writes large objects in parts."
  type        = number
  default     = 7
}

variable "loki_chart_repository" {
  description = "Helm repository that serves the Loki chart."
  type        = string
}

variable "loki_chart_name" {
  description = "Name of the Loki chart in its repository."
  type        = string
  default     = "loki"
}

variable "loki_chart_version" {
  description = "Pinned version of the Loki chart. A reconcile must never pick up whatever is latest."
  type        = string
}

variable "loki_release_name" {
  description = "Helm release name for Loki. Every in-cluster address of the log path is derived from it."
  type        = string
  default     = "loki"
}

variable "loki_service_account_name" {
  description = "Service account the Loki pods run as. It is the subject of the Loki IRSA trust policy and carries the role annotation."
  type        = string
  default     = "loki"
}

variable "loki_replication_factor" {
  description = "Number of write path replicas each log stream is written to before the write is acknowledged."
  type        = number
  default     = 3
}

variable "loki_schema_from" {
  description = "Date the TSDB schema version becomes active, in YYYY-MM-DD form. It must not be moved backwards once Loki has written blocks under it."
  type        = string
  default     = "2024-04-01"
}

variable "loki_retention_period" {
  description = "How long Loki itself keeps log streams queryable, as a duration. The bucket lifecycle rule is the backstop behind it."
  type        = string
  default     = "720h"
}

variable "loki_reject_old_samples_max_age" {
  description = "Age beyond which Loki rejects an incoming log line outright, as a duration. It stops a misconfigured shipper from backfilling the index."
  type        = string
  default     = "168h"
}

variable "loki_write_replicas" {
  description = "Replicas of the Loki write path, which ingests and flushes chunks to S3."
  type        = number
  default     = 3
}

variable "loki_read_replicas" {
  description = "Replicas of the Loki read path, which serves queries from Grafana."
  type        = number
  default     = 2
}

variable "loki_backend_replicas" {
  description = "Replicas of the Loki backend, which runs the compactor, the index gateway and the ruler."
  type        = number
  default     = 2
}

variable "loki_caches_enabled" {
  description = "Whether the chunk and result memcached caches are deployed alongside Loki."
  type        = bool
  default     = true
}

variable "loki_gateway_port" {
  description = "Port the Loki gateway service listens on, which FluentBit ships to."
  type        = number
  default     = 80
}

variable "tempo_chart_repository" {
  description = "Helm repository that serves the distributed Tempo chart."
  type        = string
}

variable "tempo_chart_name" {
  description = "Name of the Tempo chart in its repository. The distributed chart splits distributors, ingesters and queriers apart."
  type        = string
  default     = "tempo-distributed"
}

variable "tempo_chart_version" {
  description = "Pinned version of the Tempo chart."
  type        = string
}

variable "tempo_release_name" {
  description = "Helm release name for Tempo. The distributor and query frontend addresses are derived from it."
  type        = string
  default     = "tempo"
}

variable "tempo_service_account_name" {
  description = "Service account the Tempo pods run as. It is the subject of the Tempo IRSA trust policy."
  type        = string
  default     = "tempo"
}

variable "tempo_distributor_replicas" {
  description = "Replicas of the Tempo distributor, the OTLP entry point every collector writes to."
  type        = number
  default     = 2
}

variable "tempo_ingester_replicas" {
  description = "Replicas of the Tempo ingester, which builds trace blocks and flushes them to S3."
  type        = number
  default     = 3
}

variable "tempo_querier_replicas" {
  description = "Replicas of the Tempo querier, which fetches blocks back out of S3."
  type        = number
  default     = 2
}

variable "tempo_query_frontend_replicas" {
  description = "Replicas of the Tempo query frontend, the address Grafana points its Tempo datasource at."
  type        = number
  default     = 2
}

variable "tempo_compactor_replicas" {
  description = "Replicas of the Tempo compactor, which merges blocks and enforces trace retention."
  type        = number
  default     = 1
}

variable "tempo_block_retention" {
  description = "How long Tempo keeps a trace block before the compactor drops it, as a duration."
  type        = string
  default     = "336h"
}

variable "tempo_query_port" {
  description = "HTTP port of the Tempo query frontend service, used to build the Grafana datasource URL."
  type        = number
  default     = 3100
}

variable "tempo_otlp_grpc_port" {
  description = "OTLP gRPC port of the Tempo distributor service, the endpoint the collector exports spans to."
  type        = number
  default     = 4317
}

variable "mimir_chart_repository" {
  description = "Helm repository that serves the distributed Mimir chart."
  type        = string
}

variable "mimir_chart_name" {
  description = "Name of the Mimir chart in its repository."
  type        = string
  default     = "mimir-distributed"
}

variable "mimir_chart_version" {
  description = "Pinned version of the Mimir chart."
  type        = string
}

variable "mimir_release_name" {
  description = "Helm release name for Mimir. The gateway address used for both remote write and Grafana queries is derived from it."
  type        = string
  default     = "mimir"
}

variable "mimir_service_account_name" {
  description = "Service account the Mimir pods run as. It is the subject of the Mimir IRSA trust policy."
  type        = string
  default     = "mimir"
}

variable "mimir_blocks_retention_period" {
  description = "How long Mimir keeps a metric block queryable, as a duration. The bucket lifecycle rule is the backstop behind it."
  type        = string
  default     = "2160h"
}

variable "mimir_ingestion_rate" {
  description = "Sustained samples per second Mimir accepts per tenant before it starts rejecting writes."
  type        = number
  default     = 100000
}

variable "mimir_ingestion_burst_size" {
  description = "Samples a single push request may carry above the sustained ingestion rate."
  type        = number
  default     = 200000
}

variable "mimir_max_global_series_per_user" {
  description = "Active series ceiling per tenant across the whole Mimir cluster. It is the guard against a cardinality explosion in one production cluster starving the other."
  type        = number
  default     = 1500000
}

variable "mimir_distributor_replicas" {
  description = "Replicas of the Mimir distributor, which receives remote write from every Prometheus."
  type        = number
  default     = 2
}

variable "mimir_ingester_replicas" {
  description = "Replicas of the Mimir ingester, which holds recent samples and ships blocks to S3."
  type        = number
  default     = 3
}

variable "mimir_querier_replicas" {
  description = "Replicas of the Mimir querier, which answers queries from ingesters and store gateways."
  type        = number
  default     = 2
}

variable "mimir_query_frontend_replicas" {
  description = "Replicas of the Mimir query frontend, which splits and caches queries before they reach a querier."
  type        = number
  default     = 2
}

variable "mimir_store_gateway_replicas" {
  description = "Replicas of the Mimir store gateway, which serves blocks that have already been flushed to S3."
  type        = number
  default     = 2
}

variable "mimir_compactor_replicas" {
  description = "Replicas of the Mimir compactor, which merges blocks and enforces the retention period."
  type        = number
  default     = 1
}

variable "mimir_gateway_replicas" {
  description = "Replicas of the Mimir gateway, the single address in front of the read and the write path."
  type        = number
  default     = 2
}

variable "grafana_chart_repository" {
  description = "Helm repository that serves the Grafana chart."
  type        = string
}

variable "grafana_chart_name" {
  description = "Name of the Grafana chart in its repository."
  type        = string
  default     = "grafana"
}

variable "grafana_chart_version" {
  description = "Pinned version of the Grafana chart."
  type        = string
}

variable "grafana_release_name" {
  description = "Helm release name for Grafana."
  type        = string
  default     = "grafana"
}

variable "grafana_replicas" {
  description = "Replicas of the Grafana deployment. More than one requires shared or external dashboard storage."
  type        = number
  default     = 2
}

variable "grafana_host" {
  description = "Hostname Grafana is served on. It is the ingress host and the root URL Grafana builds its own links from."
  type        = string
}

variable "grafana_ingress_enabled" {
  description = "Whether an Ingress is created for Grafana. It needs an ingress controller on the observability cluster to be of any use."
  type        = bool
  default     = true
}

variable "grafana_ingress_class_name" {
  description = "Ingress class the Grafana Ingress is handed to."
  type        = string
  default     = "alb"
}

variable "grafana_ingress_annotations" {
  description = "Annotations put on the Grafana Ingress, which is how the ingress controller is told scheme, target type and certificate."
  type        = map(string)
  default     = {}
}

variable "grafana_persistence_enabled" {
  description = "Whether Grafana gets a persistent volume for the dashboards and users it stores in its local database."
  type        = bool
  default     = true
}

variable "grafana_persistence_size" {
  description = "Size of the Grafana persistent volume."
  type        = string
  default     = "10Gi"
}

variable "grafana_trace_id_regex" {
  description = "Regex Grafana applies to a Loki log line to lift a trace id out of it. The captured group becomes the link into the Tempo datasource, which is what turns a log line into a trace."
  type        = string
  default     = "trace_id=(\\w+)"
}

variable "prometheus_chart_repository" {
  description = "Helm repository that serves the Prometheus chart."
  type        = string
}

variable "prometheus_chart_name" {
  description = "Name of the Prometheus chart in its repository."
  type        = string
  default     = "prometheus"
}

variable "prometheus_chart_version" {
  description = "Pinned version of the Prometheus chart."
  type        = string
}

variable "prometheus_release_name" {
  description = "Helm release name for Prometheus."
  type        = string
  default     = "prometheus"
}

variable "prometheus_server_replicas" {
  description = "Replicas of the Prometheus server. Each one scrapes the same targets, so more than one means duplicate samples that Mimir deduplicates."
  type        = number
  default     = 1
}

variable "prometheus_local_retention" {
  description = "How long the local Prometheus TSDB is kept. It is a buffer in front of remote write, not the archive, so it stays short."
  type        = string
  default     = "6h"
}

variable "prometheus_scrape_interval" {
  description = "Interval between two scrapes of the same target. It is also the interval Grafana assumes when it queries Mimir."
  type        = string
  default     = "30s"
}

variable "prometheus_persistence_enabled" {
  description = "Whether the Prometheus server keeps its local TSDB on a persistent volume."
  type        = bool
  default     = true
}

variable "prometheus_persistence_size" {
  description = "Size of the Prometheus server persistent volume."
  type        = string
  default     = "20Gi"
}

variable "prometheus_remote_write_capacity" {
  description = "Samples the remote write queue buffers per shard before it applies backpressure to the scrape loop."
  type        = number
  default     = 10000
}

variable "prometheus_remote_write_max_shards" {
  description = "Upper bound on the shards remote write may scale out to while it catches up with Mimir."
  type        = number
  default     = 30
}

variable "prometheus_remote_write_max_samples" {
  description = "Samples packed into a single remote write request to Mimir."
  type        = number
  default     = 2000
}

variable "prometheus_alertmanager_enabled" {
  description = "Whether the Alertmanager subchart is deployed. Alerting is expected to be evaluated in Mimir, not locally."
  type        = bool
  default     = false
}

variable "prometheus_kube_state_metrics_enabled" {
  description = "Whether kube-state-metrics is deployed to expose the state of Kubernetes objects as metrics."
  type        = bool
  default     = true
}

variable "prometheus_node_exporter_enabled" {
  description = "Whether the node exporter daemonset is deployed to expose node level metrics."
  type        = bool
  default     = true
}

variable "prometheus_pushgateway_enabled" {
  description = "Whether the pushgateway is deployed. It is off because nothing in this architecture pushes batch job metrics."
  type        = bool
  default     = false
}

variable "fluent_bit_chart_repository" {
  description = "Helm repository that serves the FluentBit chart."
  type        = string
}

variable "fluent_bit_chart_name" {
  description = "Name of the FluentBit chart in its repository."
  type        = string
  default     = "fluent-bit"
}

variable "fluent_bit_chart_version" {
  description = "Pinned version of the FluentBit chart."
  type        = string
}

variable "fluent_bit_release_name" {
  description = "Helm release name for FluentBit."
  type        = string
  default     = "fluent-bit"
}

variable "fluent_bit_flush_seconds" {
  description = "Seconds FluentBit buffers records before it flushes them to Loki."
  type        = number
  default     = 1
}

variable "fluent_bit_log_level" {
  description = "Verbosity of FluentBit's own log, one of error, warn, info, debug or trace."
  type        = string
  default     = "info"

  validation {
    condition     = contains(["error", "warn", "info", "debug", "trace"], var.fluent_bit_log_level)
    error_message = "fluent_bit_log_level must be one of error, warn, info, debug or trace."
  }
}

variable "fluent_bit_mem_buf_limit" {
  description = "Memory each tail input may buffer before it pauses reading, which is what keeps a log flood from evicting the node."
  type        = string
  default     = "10MB"
}

variable "fluent_bit_retry_limit" {
  description = "Times FluentBit retries a failed delivery to Loki before it drops the chunk."
  type        = number
  default     = 5
}

variable "opentelemetry_collector_chart_repository" {
  description = "Helm repository that serves the OpenTelemetry Collector chart."
  type        = string
}

variable "opentelemetry_collector_chart_name" {
  description = "Name of the OpenTelemetry Collector chart in its repository."
  type        = string
  default     = "opentelemetry-collector"
}

variable "opentelemetry_collector_chart_version" {
  description = "Pinned version of the OpenTelemetry Collector chart."
  type        = string
}

variable "opentelemetry_collector_release_name" {
  description = "Helm release name for the OpenTelemetry Collector. It is also the fullname override, so the OTLP service keeps a stable address."
  type        = string
  default     = "otel-collector"
}

variable "opentelemetry_collector_mode" {
  description = "How the collector is deployed: deployment, daemonset or statefulset. A deployment fronts the cluster as a gateway for OTLP traffic."
  type        = string
  default     = "deployment"

  validation {
    condition     = contains(["deployment", "daemonset", "statefulset"], var.opentelemetry_collector_mode)
    error_message = "opentelemetry_collector_mode must be deployment, daemonset or statefulset."
  }
}

variable "opentelemetry_collector_replicas" {
  description = "Replicas of the collector when it runs as a deployment."
  type        = number
  default     = 2
}

variable "opentelemetry_collector_image_repository" {
  description = "Container image the collector runs. The chart refuses to render without it being set explicitly."
  type        = string
  default     = "otel/opentelemetry-collector-k8s"
}

variable "opentelemetry_collector_batch_size" {
  description = "Spans the batch processor groups together before it hands them to the exporter."
  type        = number
  default     = 1024
}

variable "opentelemetry_collector_batch_timeout" {
  description = "How long the batch processor waits for a batch to fill before sending it anyway, as a duration."
  type        = string
  default     = "5s"
}

variable "opentelemetry_collector_exporter_insecure" {
  description = "Whether the OTLP exporter skips TLS to the Tempo distributor. The hop stays inside the cluster network, so it is left insecure by default."
  type        = bool
  default     = true
}
