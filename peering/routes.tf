# Peering on its own moves no packet: each side needs a route to the other side
# through the connection. Both directions are created here, which is why this
# root owns the peering rather than either cluster owning half of it.
resource "aws_route" "requester_to_accepter" {
  for_each = local.requester_route_table_ids

  route_table_id            = each.value
  destination_cidr_block    = local.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "accepter_to_requester" {
  for_each = local.accepter_route_table_ids

  route_table_id            = each.value
  destination_cidr_block    = local.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
