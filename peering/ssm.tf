# Published for the other roots. Nothing may reach into this root's state.
resource "aws_ssm_parameter" "connection_id" {
  name        = "/eks/peering/connection_id"
  description = "Identifier of the VPC peering connection joining the two production cluster VPCs, the link the shared ALB target group of the remote cluster depends on"
  type        = "String"
  value       = aws_vpc_peering_connection.this.id
}
