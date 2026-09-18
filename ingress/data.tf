data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_elb_service_account" "main" {}

# The only cross root coupling: the clusters/ root publishes the VPC of every
# cluster it builds. No terraform_remote_state anywhere in this project.
#
# APPLY ORDER: clusters/ -> peering/ -> ingress/. This parameter exists once the
# clusters/ root has been applied for alb_vpc_cluster_name, and the peering/
# root connects that VPC to the second production cluster's VPC so the target
# group holding its pod IPs can be reached and health checked. Apply both before
# this root; nothing here creates or reads a peering resource.
data "aws_ssm_parameter" "vpc_id" {
  name = "/eks/${var.alb_vpc_cluster_name}/vpc_id"
}

# Public subnets carry the kubernetes.io/role/elb tag written by the clusters/
# root, which is also what an in cluster controller would select them by.
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}

data "aws_route53_zone" "this" {
  name         = var.route53_zone_name
  private_zone = false
}
