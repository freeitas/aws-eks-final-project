variable "region" {
  description = "AWS region holding both production VPCs. The peering built here is intra region, which is also what lets a security group in one VPC reference a security group in the other."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, applied as a tag to every resource created by this root."
  type        = string
  default     = "eks-multicluster"
}

variable "name_prefix" {
  description = "Prefix for the peering connection name and for the Name tag of every security group rule created here."
  type        = string
  default     = "efp"
}

variable "tags" {
  description = "Extra tags merged into the default tags applied to every resource created by this root."
  type        = map(string)
  default     = {}
}

variable "requester_cluster_name" {
  description = "Cluster whose VPC is the requester side of the peering. Its /eks/<cluster>/vpc_id, vpc_cidr, private_route_table_ids and node_security_group_id parameters are read from SSM."
  type        = string
  default     = "prod-01"
}

variable "accepter_cluster_name" {
  description = "Cluster whose VPC is the accepter side of the peering. Same four SSM parameters are read for it. Requester and accepter are symmetric here: routes and security group rules are created on both sides."
  type        = string
  default     = "prod-02"

  validation {
    condition     = var.accepter_cluster_name != var.requester_cluster_name
    error_message = "accepter_cluster_name must differ from requester_cluster_name: a VPC cannot be peered with itself."
  }
}

variable "allow_remote_vpc_dns_resolution" {
  description = "Resolve DNS names of the peer VPC to private addresses instead of public ones. Both sides get the same setting."
  type        = bool
  default     = true
}

variable "route_all_vpc_route_tables" {
  description = "Besides the private route tables published in SSM, add the remote CIDR to every other route table of each VPC. This is on by default because the shared ALB sits in the PUBLIC subnets of one production VPC and has to reach pod addresses in the other one; clusters/ publishes only the private tables, so the public table is discovered here instead."
  type        = bool
  default     = true
}

variable "ingress_alb_security_group_id" {
  description = "Security group of the shared ingress ALB, so both clusters accept traffic from it by group rather than only by CIDR. The ingress/ root does not publish this id to SSM, so it is passed in after that root has been applied. Leave it null on the first apply and the rules are skipped."
  type        = string
  default     = null
}

variable "alb_target_ports" {
  description = "Ports the ALB reaches on the cluster nodes: the target group traffic port and the health check port. One ingress rule per port is created on each cluster's node security group, and only when ingress_alb_security_group_id is set."
  type        = list(number)
  default     = [80, 15021]
}
