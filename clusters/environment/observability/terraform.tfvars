region             = "us-east-1"
cluster_name       = "observability"
kubernetes_version = "1.35"

vpc_cidr           = "10.3.0.0/16"
service_ipv4_cidr  = "172.23.0.0/16"
single_nat_gateway = true

private_subnets = [
  {
    "name"              = "observability-private-1a"
    "cidr"              = "10.3.0.0/19"
    "availability_zone" = "us-east-1a"
  },
  {
    "name"              = "observability-private-1b"
    "cidr"              = "10.3.32.0/19"
    "availability_zone" = "us-east-1b"
  },
  {
    "name"              = "observability-private-1c"
    "cidr"              = "10.3.64.0/19"
    "availability_zone" = "us-east-1c"
  }
]

public_subnets = [
  {
    "name"              = "observability-public-1a"
    "cidr"              = "10.3.96.0/24"
    "availability_zone" = "us-east-1a"
  },
  {
    "name"              = "observability-public-1b"
    "cidr"              = "10.3.97.0/24"
    "availability_zone" = "us-east-1b"
  },
  {
    "name"              = "observability-public-1c"
    "cidr"              = "10.3.98.0/24"
    "availability_zone" = "us-east-1c"
  }
]

node_group = {
  "name"            = "default"
  "instance_types"  = ["m6i.xlarge"]
  "capacity_type"   = "ON_DEMAND"
  "ami_type"        = "AL2023_x86_64_STANDARD"
  "disk_size"       = 50
  "min_size"        = 3
  "max_size"        = 9
  "desired_size"    = 3
  "max_unavailable" = 1
  "labels" = {
    "workload" = "observability"
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
  "Environment" = "observability"
}
