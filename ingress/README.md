# ingress/

The shared entry point for the two active/active production clusters: one
internet-facing Application Load Balancer, one target group per cluster, and a
single HTTPS listener whose weighted `forward` action decides how the traffic is
split.

The weights are the whole point. They are plain Terraform variables, so the
percentage each cluster receives is reviewed and applied like any other change,
and taking a cluster out of rotation is the same operation with the weight set
to `0`.

## Apply

Apply order: **`clusters/` -> `peering/` -> `ingress/`.**

`clusters/` publishes `/eks/<cluster>/vpc_id`, which this root reads to place the
ALB and both target groups. `peering/` connects the ALB's VPC to the second
production cluster's VPC and routes between them; without it the `prod-02`
target group holds pod IPs the load balancer cannot reach, so every one of its
targets fails its health check. This root creates no peering resource of its
own.

```bash
terraform init -backend-config=environment/backend.tfvars
terraform apply -var-file=environment/terraform.tfvars
```

## Draining a cluster

```hcl
# environment/terraform.tfvars
prod_01_weight = 0    # prod-01 stops receiving new connections
prod_02_weight = 50   # prod-02 serves everything
```

Apply, and the ALB stops routing new requests to that cluster while the other
keeps serving; requests already in flight run to completion. The weight does not
deregister anything, so `deregistration_delay` plays no part here — it only
bounds the drain when the in-cluster controller removes a pod IP from the group.
Nothing about the cluster changes — it keeps running, keeps being reconciled by
ArgoCD, and is put back by restoring its weight.

Two caveats worth knowing before you rely on this:

- `listener_stickiness_enabled` pins a client to one cluster for the lifetime of
  the cookie. While it is on, a cluster drained to `0` keeps serving the clients
  that already hold the cookie until `listener_stickiness_duration` expires. It
  is off by default so a drain takes effect on the next request.
- At least one weight must stay above `0`. A listener precondition rejects the
  plan otherwise, rather than letting the ALB answer every request with `503`.

## Targets

Terraform creates the target groups but never registers a target. Each cluster
owns a `TargetGroupBinding` pointing at its own group, and its AWS Load Balancer
Controller keeps the pod IPs of the workload Service registered. That is why the
groups use `target_type = "ip"`.

Both groups live in the VPC named by `alb_vpc_cluster_name`, read from
`/eks/<cluster>/vpc_id`. The other cluster is reached over the VPC peering built
by the `peering/` root, which works because an ALB IP target may be any RFC 1918
address, not only one from the load balancer's own VPC — provided a route
exists. That is the reason `peering/` is applied before this root.

### Health check

`health_check_port` defaults to `traffic-port` (the same port the group forwards
to) and `health_check_path` to `/`. Both are deliberately generic: no root in
this project installs a service mesh or an ingress gateway, so there is no
mesh-specific readiness endpoint to aim at, and a probe pointing at software the
cluster never runs would leave every target permanently unhealthy and the
listener answering `503`.

Narrow them once you know what the registered pods serve — for example
`health_check_path = "/healthz"` if the workload exposes that probe, or a
literal `health_check_port` if it listens for probes on a separate port.
Whatever you set has to answer with a status in `health_check_matcher` (`200` by
default).

## Published to SSM

| Parameter | Value |
|---|---|
| `/eks/ingress/alb_arn` | ARN of the shared ALB |
| `/eks/ingress/listener_arn` | ARN of the weighted HTTPS listener |
| `/eks/ingress/dns_name` | DNS name of the ALB |

SSM is the only coupling between roots in this project. Nothing here reads
another root's state.
