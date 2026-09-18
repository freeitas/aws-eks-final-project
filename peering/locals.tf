locals {
  peering_name = "${var.name_prefix}-${var.requester_cluster_name}-${var.accepter_cluster_name}"

  # An SSM parameter data source marks its value as sensitive. None of these
  # values is a secret -- they are VPC, route table and security group ids --
  # and for_each refuses a sensitive value, so they are unwrapped once here.
  requester_vpc_id                 = nonsensitive(data.aws_ssm_parameter.requester_vpc_id.value)
  requester_vpc_cidr               = nonsensitive(data.aws_ssm_parameter.requester_vpc_cidr.value)
  requester_node_security_group_id = nonsensitive(data.aws_ssm_parameter.requester_node_security_group_id.value)

  accepter_vpc_id                 = nonsensitive(data.aws_ssm_parameter.accepter_vpc_id.value)
  accepter_vpc_cidr               = nonsensitive(data.aws_ssm_parameter.accepter_vpc_cidr.value)
  accepter_node_security_group_id = nonsensitive(data.aws_ssm_parameter.accepter_node_security_group_id.value)

  # A StringList parameter comes back comma joined.
  requester_private_route_table_ids = split(",", nonsensitive(data.aws_ssm_parameter.requester_private_route_table_ids.value))
  accepter_private_route_table_ids  = split(",", nonsensitive(data.aws_ssm_parameter.accepter_private_route_table_ids.value))

  requester_route_table_ids = toset(concat(
    local.requester_private_route_table_ids,
    var.route_all_vpc_route_tables ? tolist(data.aws_route_tables.requester.ids) : []
  ))

  accepter_route_table_ids = toset(concat(
    local.accepter_private_route_table_ids,
    var.route_all_vpc_route_tables ? tolist(data.aws_route_tables.accepter.ids) : []
  ))

  # Empty until the ingress/ root exists and its security group id is passed in,
  # which is what makes the ALB rules skip themselves on the first apply.
  alb_rule_ports = var.ingress_alb_security_group_id == null ? [] : var.alb_target_ports

  tags = merge(var.tags, {
    Project   = var.project
    Root      = "peering"
    ManagedBy = "terraform"
  })
}
