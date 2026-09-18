region             = "us-east-1"
cluster_name       = "prod-01"
kubernetes_version = "1.35"

vpc_cidr           = "10.0.0.0/16"
service_ipv4_cidr  = "172.20.0.0/16"
single_nat_gateway = false

private_subnets = [
  {
    "name"              = "prod-01-private-1a"
    "cidr"              = "10.0.0.0/19"
    "availability_zone" = "us-east-1a"
  },
  {
    "name"              = "prod-01-private-1b"
    "cidr"              = "10.0.32.0/19"
    "availability_zone" = "us-east-1b"
  },
  {
    "name"              = "prod-01-private-1c"
    "cidr"              = "10.0.64.0/19"
    "availability_zone" = "us-east-1c"
  }
]

public_subnets = [
  {
    "name"              = "prod-01-public-1a"
    "cidr"              = "10.0.96.0/24"
    "availability_zone" = "us-east-1a"
  },
  {
    "name"              = "prod-01-public-1b"
    "cidr"              = "10.0.97.0/24"
    "availability_zone" = "us-east-1b"
  },
  {
    "name"              = "prod-01-public-1c"
    "cidr"              = "10.0.98.0/24"
    "availability_zone" = "us-east-1c"
  }
]

node_group = {
  "name"            = "default"
  "instance_types"  = ["m6i.large"]
  "capacity_type"   = "ON_DEMAND"
  "ami_type"        = "AL2023_x86_64_STANDARD"
  "disk_size"       = 50
  "min_size"        = 3
  "max_size"        = 9
  "desired_size"    = 3
  "max_unavailable" = 1
  "labels" = {
    "workload" = "production"
  }
}

alb_controller = {
  "chart_repository" = "https://aws.github.io/eks-charts"
  "chart_version"    = "1.17.1"
  "namespace"        = "kube-system"
  "service_account"  = "aws-load-balancer-controller"
  "replica_count"    = 2
}

tags = {
  "Project"     = "aws-eks-multicluster"
  "Environment" = "production"
}

create_argocd_access_role = true
argocd_access_role_name   = "aws-eks-multicluster-argocd-access-prod-01"

argocd_access_trusted_role_names = [
  "aws-eks-multicluster-argocd-control-plane"
]
