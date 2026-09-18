region             = "us-east-1"
cluster_name       = "argocd"
kubernetes_version = "1.35"

vpc_cidr           = "10.2.0.0/16"
service_ipv4_cidr  = "172.22.0.0/16"
single_nat_gateway = true

private_subnets = [
  {
    "name"              = "argocd-private-1a"
    "cidr"              = "10.2.0.0/19"
    "availability_zone" = "us-east-1a"
  },
  {
    "name"              = "argocd-private-1b"
    "cidr"              = "10.2.32.0/19"
    "availability_zone" = "us-east-1b"
  },
  {
    "name"              = "argocd-private-1c"
    "cidr"              = "10.2.64.0/19"
    "availability_zone" = "us-east-1c"
  }
]

public_subnets = [
  {
    "name"              = "argocd-public-1a"
    "cidr"              = "10.2.96.0/24"
    "availability_zone" = "us-east-1a"
  },
  {
    "name"              = "argocd-public-1b"
    "cidr"              = "10.2.97.0/24"
    "availability_zone" = "us-east-1b"
  },
  {
    "name"              = "argocd-public-1c"
    "cidr"              = "10.2.98.0/24"
    "availability_zone" = "us-east-1c"
  }
]

node_group = {
  "name"            = "default"
  "instance_types"  = ["m6i.large"]
  "capacity_type"   = "ON_DEMAND"
  "ami_type"        = "AL2023_x86_64_STANDARD"
  "disk_size"       = 50
  "min_size"        = 2
  "max_size"        = 6
  "desired_size"    = 2
  "max_unavailable" = 1
  "labels" = {
    "workload" = "control-plane"
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
  "Project"     = "aws-eks-final-project"
  "Environment" = "platform"
}
