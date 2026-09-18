data "aws_caller_identity" "current" {}

# SSM Parameter Store is the only coupling between roots in this project. Every
# parameter below is written by clusters/ when that cluster is applied. There is
# no terraform_remote_state anywhere: this root can be destroyed and rebuilt
# without dragging either cluster into its state file.
data "aws_ssm_parameter" "requester_vpc_id" {
  name = "/eks/${var.requester_cluster_name}/vpc_id"
}

data "aws_ssm_parameter" "requester_vpc_cidr" {
  name = "/eks/${var.requester_cluster_name}/vpc_cidr"
}

data "aws_ssm_parameter" "requester_private_route_table_ids" {
  name = "/eks/${var.requester_cluster_name}/private_route_table_ids"
}

data "aws_ssm_parameter" "requester_node_security_group_id" {
  name = "/eks/${var.requester_cluster_name}/node_security_group_id"
}

data "aws_ssm_parameter" "accepter_vpc_id" {
  name = "/eks/${var.accepter_cluster_name}/vpc_id"
}

data "aws_ssm_parameter" "accepter_vpc_cidr" {
  name = "/eks/${var.accepter_cluster_name}/vpc_cidr"
}

data "aws_ssm_parameter" "accepter_private_route_table_ids" {
  name = "/eks/${var.accepter_cluster_name}/private_route_table_ids"
}

data "aws_ssm_parameter" "accepter_node_security_group_id" {
  name = "/eks/${var.accepter_cluster_name}/node_security_group_id"
}

# clusters/ publishes the PRIVATE route tables only. The shared ALB lives in the
# public subnets of one of these VPCs, so its own route table needs the remote
# CIDR too or every target in the peer VPC stays unreachable. Discovering the
# tables keeps that fix inside this root instead of widening the SSM contract.
data "aws_route_tables" "requester" {
  vpc_id = local.requester_vpc_id
}

data "aws_route_tables" "accepter" {
  vpc_id = local.accepter_vpc_id
}
