# aws-eks-final-project

A distributed environment running multiple Kubernetes clusters on AWS. Helm
charts, addons and application workloads are managed centrally with ArgoCD, and
an observability stack receives traces, logs and metrics from multiple sources
and exposes them for consumption in Grafana.

## Architecture decisions

### ArgoCD runs in its own cluster, not inside production

I gave ArgoCD a dedicated control plane cluster that deploys into both production clusters, instead of running ArgoCD inside cluster 01 and treating it as primary. Active/active only means something if either cluster can be drained to zero; with the delivery tooling inside one of them, that cluster can never leave rotation, and the rollout that breaks it also takes away what I would use to roll it back. A whole extra cluster is the price of that property.

### The traffic split lives in the ALB, not in DNS

One Application Load Balancer fans out to an `ip`-type target group per cluster, with the weights driven from Terraform (50/50 by default). Route 53 weighted records were the cheap option and I rejected them: with DNS, "out of rotation" is a TTL you hope resolvers honor, and health checks watch a name instead of the gateway actually serving. Here the weight goes to 0% and the load balancer stops handing new connections to that cluster.

### ArgoCD reaches each cluster through an IAM role

Each production cluster is registered with an IAM role the control plane assumes, not with a kubeconfig or service account token pasted into an ArgoCD cluster secret. Those tokens are effectively non-expiring cluster-admin sitting in a Secret: rotation means editing the control plane by hand, and one leak is both production clusters at once.

### One ApplicationSet with a cluster generator, not one Application per cluster

`argocd/applicationset.tf` defines each workload once and lets a cluster generator project it onto every registered production cluster, sourcing manifests from a pinned Git repository and revision. Writing an Application per cluster is the obvious alternative and I rejected it: the definitions drift the moment someone patches one cluster in a hurry, and active/active is worth nothing if the two clusters are quietly running different manifests. Adding a third cluster becomes a registration, not a copy-paste.

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

## Repository layout

```
.
├── clusters/        VPC, EKS control plane, managed node group, addons, ALB controller
│   └── environment/
│       ├── prod-01/        10.0.0.0/16 — production, active/active
│       ├── prod-02/        10.1.0.0/16 — production, active/active
│       ├── argocd/         10.2.0.0/16 — delivery control plane
│       └── observability/  10.3.0.0/16 — LGTM stack
├── peering/         VPC peering prod-01 <-> prod-02: connection, routes, security group rules
├── ingress/         shared internet-facing ALB, one weighted target group per production cluster
├── argocd/          ArgoCD release, cluster registration secrets, AppProject, ApplicationSet
├── observability/   Loki, Tempo, Mimir, Grafana, Prometheus, FluentBit, OTel Collector,
│                    one S3 bucket per signal and the IRSA roles that reach them
└── assets/          diagrams used by this README
```

`clusters/` is **one Terraform root applied four times**, not four copies of the same
code. The cluster name, the addressing, the Kubernetes version and the node group
shape all arrive through `environment/<name>/terraform.tfvars`, and each environment
keeps its state under its own key in the shared bucket. That is what makes taking
`prod-02` out of rotation, rebuilding it and putting it back a configuration change
rather than a code change.

The only coupling between roots is SSM Parameter Store: `clusters/` publishes
`/eks/<cluster_name>/*` and every other root reads it. There is no
`terraform_remote_state` anywhere, so a root can be destroyed and rebuilt without
dragging its consumers into the same state file.

## Prerequisites

An AWS account, credentials for `us-east-1`, Terraform `>= 1.5.7`, and `kubectl`.

### Remote state is not created here

Every root points its backend at the same bucket and lock table, and **no root in
this repository creates either one**. They have to exist before the first
`terraform init`:

| Resource | Name |
|---|---|
| S3 bucket | `eks-final-project-tfstate` |
| DynamoDB lock table | `eks-final-project-tfstate-lock` |

The lock table needs a partition key named `LockID` of type `String`; that is what
the S3 backend expects, and `init` fails against a table shaped any other way.

### Service quotas

The four cluster environments do not fit inside a fresh account's default quotas.
Request the increases before applying, not halfway through:

| Quota | Default | Needed |
|---|---|---|
| VPCs per Region | 5 | 4 — plus the account's default VPC, which counts |
| EC2-VPC Elastic IPs | 5 | 8 |

The Elastic IPs come from the NAT gateways. Both production clusters run
`single_nat_gateway = false`, which is one NAT gateway per public subnet:

| Environment | `single_nat_gateway` | NAT gateways | Elastic IPs |
|---|---|---|---|
| `prod-01` | `false` | 3, one per AZ | 3 |
| `prod-02` | `false` | 3, one per AZ | 3 |
| `argocd` | `true` | 1 | 1 |
| `observability` | `true` | 1 | 1 |
| | | | **8** |

Four VPCs against a limit of 5 leaves no headroom at all, and the eighth Elastic IP
fails to allocate on an untouched account. An apply that trips either limit stops
partway and leaves a half-built cluster behind.

## Apply order

```
clusters/ (x4)  ->  peering/  ->  ingress/  ->  argocd/  ->  observability/
```

Every root is applied the same way, from its own directory:

```bash
terraform init -backend-config=environment/backend.tfvars
terraform apply -var-file=environment/terraform.tfvars
```

`clusters/` is the exception, because it is applied once per environment and each one
has its own backend key. Re-run `init` with `-reconfigure` when switching:

```bash
cd clusters
terraform init -reconfigure -backend-config=environment/prod-01/backend.tfvars
terraform apply -var-file=environment/prod-01/terraform.tfvars
# then the same for prod-02, argocd and observability
```

Why this order:

- **`clusters/` first.** Every other root resolves the cluster it works on through
  `/eks/<cluster>/*` in SSM and fails fast when a parameter is missing.
- **`peering/` before `ingress/`.** Both target groups are `target_type = "ip"` and
  live in the `prod-01` VPC. An ALB IP target may be any RFC 1918 address, but not
  one the load balancer has no route to. Apply `ingress/` first and the `prod-02`
  pod IPs register, fail every health check, and the weighted forward action quietly
  sends 100% of traffic to `prod-01` — the drain switch is there but means nothing.
- **`argocd/` after both production clusters.** It registers them as cluster secrets
  from their endpoint, CA, cluster ARN and access role ARN, and the ApplicationSet's
  cluster generator has nothing to fan out to until those secrets exist.
- **`observability/` last.** It is a leaf: nothing else reads it.

One deliberate second pass: `ingress/` does not publish its load balancer's security
group id, so `peering/` takes it as `ingress_alb_security_group_id`, defaulting to
`null`. Fill it in after `ingress/` is applied and apply `peering/` again. It is a
tightening, not a fix — the ALB already sits inside one of the peered VPCs and is
covered by the peer CIDR rule until then.

## Draining a cluster

This is the maintenance mechanism the architecture above promises, and it is one
variable. The weights live in `ingress/environment/terraform.tfvars`:

```hcl
prod_01_weight = 0    # prod-01 stops receiving new connections
prod_02_weight = 50   # prod-02 serves everything
```

```bash
cd ingress
terraform apply -var-file=environment/terraform.tfvars
```

The ALB stops handing new connections to that cluster while the other keeps serving;
requests already in flight run to completion. Nothing is deregistered and nothing
about the cluster itself changes — it keeps running, keeps being reconciled by
ArgoCD, and is put back in rotation by restoring its weight.

Two things to know before relying on it:

- `listener_stickiness_enabled` pins a client to one cluster for the lifetime of the
  cookie, so a cluster drained to `0` keeps serving clients that already hold one
  until the cookie expires. It is off by default so a drain takes effect on the next
  request.
- At least one weight must stay above `0`. A precondition rejects the plan otherwise,
  rather than letting the ALB answer every request with `503`.

## Known gaps

- **None of this has been run.** No root has been through `terraform validate`,
  `terraform plan` or `terraform apply`. Chart versions, value schemas and argument
  names are written from the documentation, not from a successful apply — treat them
  as unverified.
- **ArgoCD needs two passes on a fresh cluster.** `argocd/applicationset.tf` creates
  the `AppProject` and the `ApplicationSet` with `kubernetes_manifest`, which
  contacts the API server at **plan** time to resolve the CRD schema. `depends_on`
  does not help: against a cluster that does not yet have ArgoCD's CRDs installed,
  the plan fails before anything is created. Install the chart first, then apply the
  rest:

  ```bash
  terraform apply -target=helm_release.argocd -var-file=environment/terraform.tfvars
  terraform apply -var-file=environment/terraform.tfvars
  ```

- **The observability stack only scrapes its own cluster.** Prometheus, FluentBit and
  the OTel Collector are installed on the `observability` cluster alone, and every
  endpoint they write to is an in-cluster service name under
  `<namespace>.svc.cluster.local`. The internal NLB and the private Route 53 record
  per signal that the narrative above describes do not exist in this repository, and
  no collector is deployed into `prod-01` or `prod-02` — so no production telemetry
  reaches Loki, Tempo or Mimir yet. The per-cluster `external_labels` on Prometheus
  are in place for when it does.

## Related repositories

| Component | Repository |
|---|---|
| VPC / networking | [aws-eks-networking](https://github.com/freeitas/aws-eks-networking) |
| EKS clusters | [aws-eks-cluster](https://github.com/freeitas/aws-eks-cluster) |
