# aws-eks-final-project

A distributed environment running multiple Kubernetes clusters on AWS. Helm
charts, addons and application workloads are managed centrally with ArgoCD, and
an observability stack receives traces, logs and metrics from multiple sources
and exposes them for consumption in Grafana.

## Architecture decisions

### ArgoCD runs in its own cluster, not inside production

I gave ArgoCD and ChartMuseum a dedicated control plane cluster that deploys into both production clusters, instead of running ArgoCD inside cluster 01 and treating it as primary. Active/active only means something if either cluster can be drained to zero; with the delivery tooling inside one of them, that cluster can never leave rotation, and the rollout that breaks it also takes away what I would use to roll it back. A whole extra cluster is the price of that property.

### The traffic split lives in the ALB, not in DNS

One Application Load Balancer fans out to a target group per cluster (50/50, weights driven from Terraform), and each target group is wired to that cluster's Istio ingress gateway through a TargetGroupBinding. Route 53 weighted records were the cheap option and I rejected them: with DNS, "out of rotation" is a TTL you hope resolvers honor, and health checks watch a name instead of the gateway actually serving. Here the weight goes to 0% and the load balancer stops handing new connections to that cluster.

### ArgoCD reaches each cluster through an IAM role

Each production cluster is registered with an IAM role the control plane assumes, not with a kubeconfig or service account token pasted into an ArgoCD cluster secret. Those tokens are effectively non-expiring cluster-admin sitting in a Secret: rotation means editing the control plane by hand, and one leak is both production clusters at once.

### Charts are served from my own ChartMuseum, backed by S3

ArgoCD resolves charts from ChartMuseum in the control plane cluster, whose storage is an S3 bucket, rather than pointing Applications and Addons straight at upstream Helm repos. Upstream would make every reconcile a live dependency on someone else's registry — a yanked or retagged version turns a routine sync into a failed one, exactly while I am reconciling a cluster I have already drained.

### Telemetry leaves the cluster that produced it

FluentBit, the OTel Collector and Prometheus push out of production into a separate observability cluster, over one internal NLB and one private Route 53 record per signal, into one S3 bucket per signal. Per-cluster Prometheus and Grafana is fewer moving parts, but then telemetry dies with the cluster I need to debug, and a trace crossing both active/active clusters can never be reassembled. Separate endpoints keep a log flood from starving metric writes and let retention differ per signal. Loki runs simple scalable — write path, read path, backend — while Tempo and Mimir run full microservices, because only traces and metrics need distributors, ingesters and queriers scaled apart here.

Like the [ECS project](https://github.com/freeitas/aws-ecs-final-project), the
goal is to provide mechanisms for scaling sustainably and resiliently in
medium-to-large corporate environments.

## Part one — multi-cluster management with ArgoCD

![ArgoCD](assets/argocd-multicluster.png)

The first part uses ArgoCD as a control plane, so the contents of multiple
clusters can be managed simply and safely. The proposed architecture has **two
production clusters in an active/active model**, a **load balancer that controls
the percentage of traffic distributed between them**, customizable through
Terraform, and an **ArgoCD cluster with permission to deploy resources into both
production clusters**.

The model allows any cluster to be taken fully out of rotation for maintenance,
testing or upgrades.

## Part two — observability cluster

![Observability](assets/observability-cluster.png)

### Main components

- **Grafana Loki**: log indexing
- **Grafana Tempo**: trace and span indexing
- **Grafana Mimir**: Prometheus metrics indexing
- **Grafana Dashboard**: visualization of data, metrics, logs and traces
- **FluentBit**: collects Kubernetes logs and ships them to Loki
- **OpenTelemetry Collector**: ships traces and spans to Tempo
- **Prometheus**: collects metrics and ships them to Mimir

### Grafana read path — datasources

![Grafana](assets/grafana-datasources.png)

## Related repositories

| Component | Repository |
|---|---|
| VPC / networking | [aws-eks-networking](https://github.com/freeitas/aws-eks-networking) |
| EKS clusters | [aws-eks-cluster](https://github.com/freeitas/aws-eks-cluster) |
