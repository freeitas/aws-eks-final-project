# clusters/

One reusable Terraform root, applied four times, that builds a self-contained
EKS cluster: its own VPC, its own control plane, its own managed node group and
its own load balancer controller.

| Environment | Role | VPC CIDR | Service CIDR |
|---|---|---|---|
| `prod-01` | production, active/active | `10.0.0.0/16` | `172.20.0.0/16` |
| `prod-02` | production, active/active | `10.1.0.0/16` | `172.21.0.0/16` |
| `argocd` | delivery control plane | `10.2.0.0/16` | `172.22.0.0/16` |
| `observability` | Grafana LGTM stack | `10.3.0.0/16` | `172.23.0.0/16` |

Nothing about a cluster is baked into the code — the name, the addressing, the
Kubernetes version and the node group shape all arrive through
`environment/<name>/terraform.tfvars`. That is what makes taking `prod-02` out
of rotation, rebuilding it and putting it back a configuration change rather
than a code change.

## Apply

```bash
terraform init -backend-config=environment/prod-01/backend.tfvars
terraform apply -var-file=environment/prod-01/terraform.tfvars
```

Re-run `init` with `-reconfigure` when switching environments: each one keeps
its state under a different key in the same bucket.

The S3 bucket `eks-final-project-tfstate` and the DynamoDB lock table
`eks-final-project-tfstate-lock` are prerequisites — no root in this repository
creates them, and `ingress/` and `observability/` expect the same two.

## What it creates

- A VPC with three public and three private subnets across `us-east-1a/b/c`, an
  internet gateway and one NAT gateway (per AZ when `single_nat_gateway` is
  `false`, which is how both production clusters run).
- Subnets carry `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb`
  so the load balancer controller can discover them.
- An EKS control plane with both the private and the public endpoint enabled and
  all five control plane log types shipped to CloudWatch Logs.
- An IAM OIDC provider, so every workload identity in this repository is IRSA
  rather than a static key.
- A managed node group in the private subnets, sized from `var.node_group`.
- Addons: `vpc-cni`, `coredns`, `kube-proxy`, `eks-pod-identity-agent` and
  `aws-ebs-csi-driver` (with its own IRSA role).
- `aws-load-balancer-controller`, with an IRSA role scoped to tagging load
  balancers in this account only.

## What it publishes

Every other root in this repository reads this cluster through SSM Parameter
Store — there is no `terraform_remote_state` anywhere, so a root can be
destroyed and rebuilt without dragging its consumers into the same state file.

| Parameter | Contents |
|---|---|
| `/eks/<cluster_name>/endpoint` | Kubernetes API endpoint |
| `/eks/<cluster_name>/cluster_arn` | Cluster ARN |
| `/eks/<cluster_name>/oidc_provider_arn` | IRSA OIDC provider ARN |
| `/eks/<cluster_name>/certificate_authority` | Base64 CA data |
| `/eks/<cluster_name>/vpc_id` | VPC id |
| `/eks/<cluster_name>/private_subnets` | Private subnet ids, comma joined |
| `/eks/<cluster_name>/private_route_table_ids` | Private route table ids, comma joined — where a peering root adds the remote CIDR |
| `/eks/<cluster_name>/vpc_cidr` | Primary VPC CIDR block |
| `/eks/<cluster_name>/node_security_group_id` | EKS managed security group carried by the node group instances |
| `/eks/<cluster_name>/argocd_access_role_arn` | ArgoCD access role ARN — only on the clusters where `create_argocd_access_role` is `true` |

## Granting the control plane access

Two independent mechanisms, both ending in an EKS access entry bound to
`AmazonEKSClusterAdminPolicy`:

`var.cluster_admin_principals` takes IAM role ARNs that already exist elsewhere
and turns each one into an access entry. It is empty by default and is meant for
human break-glass roles.

`var.create_argocd_access_role` closes the loop for ArgoCD. The `argocd/` root
registers `prod-01` and `prod-02` as external clusters and points
`awsAuthConfig.roleARN` at a role per cluster, but it cannot create those roles:
they have to exist in the cluster's own account with an access entry attached,
which only this root can do. Setting the flag here creates, for this cluster:

- an IAM role named `var.argocd_access_role_name`, trusting the principals named
  in `var.argocd_access_trusted_principal_arns` (full ARNs, for a control plane
  in another account) and `var.argocd_access_trusted_role_names` (role names
  expanded against `data.aws_caller_identity`, so the account id is never
  written into a tfvars file),
- an `aws_eks_access_entry` plus `aws_eks_access_policy_association` giving that
  role real Kubernetes RBAC — without the pair the role can mint a token and
  still be refused by the API server,
- `/eks/<cluster_name>/argocd_access_role_arn`, so consumers can read the ARN
  instead of reconstructing it from a name.

Both production environments set the flag; `argocd` and `observability` leave it
`false`, since nothing assumes into them.
