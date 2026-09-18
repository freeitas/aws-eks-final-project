output "connection_id" {
  description = "Identifier of the VPC peering connection between the two production VPCs."
  value       = aws_vpc_peering_connection.this.id
}

output "accept_status" {
  description = "Acceptance status of the peering connection. It is active right after the apply because both VPCs are in the same account."
  value       = aws_vpc_peering_connection.this.accept_status
}

output "requester_vpc_id" {
  description = "Identifier of the requester VPC, read from SSM."
  value       = local.requester_vpc_id
}

output "accepter_vpc_id" {
  description = "Identifier of the accepter VPC, read from SSM."
  value       = local.accepter_vpc_id
}

output "requester_vpc_cidr" {
  description = "IPv4 CIDR of the requester VPC, the destination routed from the accepter side."
  value       = local.requester_vpc_cidr
}

output "accepter_vpc_cidr" {
  description = "IPv4 CIDR of the accepter VPC, the destination routed from the requester side."
  value       = local.accepter_vpc_cidr
}

output "requester_route_table_ids" {
  description = "Route tables of the requester VPC that received a route to the accepter CIDR."
  value       = sort(tolist(local.requester_route_table_ids))
}

output "accepter_route_table_ids" {
  description = "Route tables of the accepter VPC that received a route to the requester CIDR."
  value       = sort(tolist(local.accepter_route_table_ids))
}

output "alb_security_group_rules_created" {
  description = "Whether the rules admitting the shared ingress ALB by security group were created. False until ingress_alb_security_group_id is set."
  value       = length(local.alb_rule_ports) > 0
}
