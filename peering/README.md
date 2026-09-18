# peering/

The wire between the two active/active production VPCs. Without it the
active/active mechanism in `ingress/` is decoration: the ALB holds a target
group for `prod-02` that can never contain a reachable address.

## Why this root exists

`ingress/` builds both target groups with `target_type = "ip"` inside a single
VPC — the one named by `alb_vpc_cluster_name`, `prod-01`. An ALB IP target may
be any RFC 1918 address, not only one from the load balancer's own VPC, which is
what lets one listener weight-split across two clusters. What it may not be is
an address the load balancer has no route to. `prod-02` runs in `10.1.0.0/16`
with its own VPC, its own route tables and its own security groups, so until the
two VPCs are connected its pod IPs are registered, unreachable, permanently
unhealthy, and the weighted forward action silently sends everything to
`prod-01`. Nothing fails loudly; the drain switch just stops being real.

`clusters/` hands every cluster a distinct `/16` — `10.0`, `10.1`, `10.2`,
`10.3` — so the address space never overlaps and peering is possible at all.

## Apply order

    clusters/  ->  peering/  ->  ingress/

Apply `clusters/` for both production environments first: this root reads their
VPC ids, CIDRs, route tables and node security groups from SSM and will fail
fast if a parameter is missing. Apply it before `ingress/` so the `prod-02`
targets become healthy on their first registration instead of flapping until the
peering shows up.

```bash
terraform init -backend-config=environment/backend.tfvars
terraform apply -var-file=environment/terraform.tfvars
```

## What it creates

- One `aws_vpc_peering_connection` between the two production VPCs, accepted in
  the same call (`auto_accept`) because both live in this account and region.
  The account id comes from `data.aws_caller_identity`, never from a tfvars.
- A route to the remote CIDR in the route tables of **both** VPCs, `for_each`
  over the id lists published in SSM. Peering by itself moves no packet; both
  directions are owned here rather than half by each cluster.
- Ingress rules on each cluster's node security group admitting the other VPC's
  CIDR, and — once the ALB's security group id is known — the ALB itself by
  group reference. Referencing a security group across a peering connection is
  legal in the same region, which is why both VPCs are pinned to one region.

## Route tables: more than the private ones

`clusters/` publishes `/eks/<cluster>/private_route_table_ids`, the tables the
nodes sit behind. Those are always routed. But the shared ALB is
internet-facing and its interfaces live in the **public** subnets of the
`prod-01` VPC, behind a route table that is not part of the SSM contract — and
that is the interface that has to reach `prod-02` pod addresses. So
`route_all_vpc_route_tables` (on by default) discovers every route table in each
VPC with `data "aws_route_tables"` and routes those too. Turn it off only if
something else already owns the public routes; with it off, the `prod-02` target
group goes back to being unreachable from the ALB.

## The ALB security group is a second pass

`ingress/` publishes `/eks/ingress/alb_arn`, `listener_arn` and `dns_name` — not
the id of the load balancer's security group. Rather than reach into that root's
state (nothing in this project does) the id is a variable,
`ingress_alb_security_group_id`, defaulting to `null`, and the four rules that
use it disappear under `count` while it is unset. That is the correct state on
the first apply, when `ingress/` does not exist yet.

Once `ingress/` is applied, put its security group id in
`environment/terraform.tfvars` and apply this root again. It is a tightening,
not a fix: the ALB sits inside one of the two peered VPCs, so it is already
covered by the CIDR rule. The group reference just narrows `prod-01`'s side from
"anything in the peer VPC" to "the load balancer", on the two ports the target
groups actually use.

## SSM

Read, all written by `clusters/`:

| Parameter | Used for |
|---|---|
| `/eks/<cluster>/vpc_id` | the two sides of the peering connection |
| `/eks/<cluster>/vpc_cidr` | route destinations and the peer CIDR rules |
| `/eks/<cluster>/private_route_table_ids` | the tables that get the remote route |
| `/eks/<cluster>/node_security_group_id` | the group the ingress rules attach to |

Written:

| Parameter | Value |
|---|---|
| `/eks/peering/connection_id` | id of the peering connection |

SSM is the only coupling between roots in this project. No
`terraform_remote_state`, anywhere.
