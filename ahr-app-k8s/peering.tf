
# # Resources:
# # aws_vpc_peering_connection
# # peering hr app to db vpc
# resource "aws_vpc_peering_connection" "hr_app_to_db_peering" {
#   vpc_id      = aws_vpc.hr_app_vpc.id
#   peer_vpc_id = aws_vpc.db_vpc.id

#   auto_accept = true

#   requester {
#     allow_remote_vpc_dns_resolution = true
#   }

#   accepter {
#     allow_remote_vpc_dns_resolution = true
#   }

#   tags = {
#     Name = "hr-app-db-peering"
#   }
# }
