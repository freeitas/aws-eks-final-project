# Both VPCs are in the same account and the same region, so the accepter side is
# accepted in the same API call and no aws_vpc_peering_connection_accepter is
# needed. peer_owner_id comes from the caller identity: no account id is written
# down anywhere in this repository.
resource "aws_vpc_peering_connection" "this" {
  vpc_id        = local.requester_vpc_id
  peer_vpc_id   = local.accepter_vpc_id
  peer_owner_id = data.aws_caller_identity.current.account_id
  auto_accept   = true

  accepter {
    allow_remote_vpc_dns_resolution = var.allow_remote_vpc_dns_resolution
  }

  requester {
    allow_remote_vpc_dns_resolution = var.allow_remote_vpc_dns_resolution
  }

  tags = {
    Name = local.peering_name
  }

  # Peering refuses overlapping address space. clusters/ hands every cluster its
  # own /16 (10.0, 10.1, 10.2, 10.3), so identical CIDRs on both sides means the
  # two environment files drifted -- say that in the plan instead of letting the
  # apply fail inside AWS.
  lifecycle {
    precondition {
      condition     = local.requester_vpc_cidr != local.accepter_vpc_cidr
      error_message = "Both clusters report the same VPC CIDR, which VPC peering rejects. Give each cluster a distinct vpc_cidr in clusters/environment/<cluster>/terraform.tfvars."
    }
  }
}
