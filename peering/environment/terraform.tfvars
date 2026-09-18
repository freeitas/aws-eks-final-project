region      = "us-east-1"
project     = "eks-multicluster"
name_prefix = "efp"

# The two active/active production clusters. clusters/ gives them 10.0.0.0/16
# and 10.1.0.0/16, which is what makes peering possible at all.
requester_cluster_name = "prod-01"
accepter_cluster_name  = "prod-02"

allow_remote_vpc_dns_resolution = true

# The shared ALB sits in the public subnets of the requester VPC, so its route
# table needs the remote CIDR as well. Leave this on.
route_all_vpc_route_tables = true

# Filled in on the second apply, after ingress/ exists. That root does not
# publish its security group id, so it is carried here by hand; until then the
# clusters still admit the ALB through the peer CIDR rule above.
ingress_alb_security_group_id = null
alb_target_ports              = [80, 15021]

tags = { Environment = "production", Owner = "platform" }
