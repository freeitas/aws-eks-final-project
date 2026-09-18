# The rules below are attached to security groups this root does not own: the
# EKS managed cluster security group of each cluster, published by clusters/ as
# /eks/<cluster>/node_security_group_id. They are standalone rule resources on
# purpose -- an aws_security_group with inline blocks would fight whoever else
# writes to that group.

resource "aws_vpc_security_group_ingress_rule" "requester_from_accepter_cidr" {
  security_group_id = local.requester_node_security_group_id
  description       = "All traffic from the ${var.accepter_cluster_name} VPC over the peering connection"
  cidr_ipv4         = local.accepter_vpc_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "${local.peering_name}-${var.requester_cluster_name}-from-${var.accepter_cluster_name}"
  }

  depends_on = [aws_vpc_peering_connection.this]
}

resource "aws_vpc_security_group_ingress_rule" "accepter_from_requester_cidr" {
  security_group_id = local.accepter_node_security_group_id
  description       = "All traffic from the ${var.requester_cluster_name} VPC over the peering connection"
  cidr_ipv4         = local.requester_vpc_cidr
  ip_protocol       = "-1"

  tags = {
    Name = "${local.peering_name}-${var.accepter_cluster_name}-from-${var.requester_cluster_name}"
  }

  depends_on = [aws_vpc_peering_connection.this]
}

# Referencing a security group that lives in the peer VPC is only legal once the
# connection is active, and only inside one region -- both true here. The rules
# disappear entirely while ingress_alb_security_group_id is null, which is the
# state of this root before ingress/ has ever been applied.
resource "aws_vpc_security_group_ingress_rule" "requester_from_alb" {
  count = length(local.alb_rule_ports)

  security_group_id            = local.requester_node_security_group_id
  description                  = "Shared ingress ALB to the ${var.requester_cluster_name} targets on port ${local.alb_rule_ports[count.index]}"
  referenced_security_group_id = var.ingress_alb_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = local.alb_rule_ports[count.index]
  to_port                      = local.alb_rule_ports[count.index]

  tags = {
    Name = "${local.peering_name}-${var.requester_cluster_name}-from-alb-${local.alb_rule_ports[count.index]}"
  }

  depends_on = [aws_vpc_peering_connection.this]
}

resource "aws_vpc_security_group_ingress_rule" "accepter_from_alb" {
  count = length(local.alb_rule_ports)

  security_group_id            = local.accepter_node_security_group_id
  description                  = "Shared ingress ALB to the ${var.accepter_cluster_name} targets on port ${local.alb_rule_ports[count.index]}"
  referenced_security_group_id = var.ingress_alb_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = local.alb_rule_ports[count.index]
  to_port                      = local.alb_rule_ports[count.index]

  tags = {
    Name = "${local.peering_name}-${var.accepter_cluster_name}-from-alb-${local.alb_rule_ports[count.index]}"
  }

  depends_on = [aws_vpc_peering_connection.this]
}
