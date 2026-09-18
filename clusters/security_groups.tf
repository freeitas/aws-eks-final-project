resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "Extra security group attached to the EKS control plane elastic network interfaces."
  vpc_id      = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${var.cluster_name}-cluster" })
}

resource "aws_vpc_security_group_ingress_rule" "cluster_api" {
  security_group_id = aws_security_group.cluster.id
  description       = "Kubernetes API reachable from inside the VPC."
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  description       = "Unrestricted egress from the control plane interfaces."
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
