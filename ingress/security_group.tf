# name_prefix, not name: create_before_destroy makes the replacement group exist
# alongside the old one, and two security groups in the same VPC cannot share a
# name. A fixed name would turn every replacement into InvalidGroup.Duplicate.
# Nothing refers to this group by name -- the ALB, the rules and the output all
# use its id -- so the generated suffix costs nothing, and the stable name stays
# on the Name tag.
resource "aws_security_group" "alb" {
  name_prefix = "${local.alb_name}-sg-"
  description = "Shared ingress ALB for both production clusters"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.alb_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = toset(var.ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from clients"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from clients, redirected to HTTPS by the listener"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.alb.id
  description       = "Reach the registered pod IPs in both production clusters, the second one across the VPC peering"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
