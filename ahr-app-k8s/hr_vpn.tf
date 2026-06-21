####### Customer Gateway #############
# Border Gateway Protocol (BGP) is the protocol that manages the routed peerings 
# and routing of packets between different autonomous systems across the Internet.
resource "aws_customer_gateway" "netlab_cgw" {
  bgp_asn    = 65000
  ip_address = var.netlab_public_ip
  type       = "ipsec.1"

  tags = {
    Name = "netlab-pfsense-cgw"
  }
}

####### Virtual Private Gateway #############
resource "aws_vpn_gateway" "hr_vgw" {
  amazon_side_asn = 64512

  tags = {
    Name = "hr-vpc-vgw"
  }
}

####### VGW attachment to HR VPC ###########
resource "aws_vpn_gateway_attachment" "hr_vgw_attachment" {
  vpc_id         = aws_vpc.hr_app_vpc.id
  vpn_gateway_id = aws_vpn_gateway.hr_vgw.id
}

####### Route propagation into HR App route table ###########
resource "aws_vpn_gateway_route_propagation" "hr_vgw_propagation_1a" {
  vpn_gateway_id = aws_vpn_gateway.hr_vgw.id
  route_table_id = aws_route_table.hr_app_private_subnet_rt_1a.id
}

resource "aws_vpn_gateway_route_propagation" "hr_vgw_propagation_1b" {
  vpn_gateway_id = aws_vpn_gateway.hr_vgw.id
  route_table_id = aws_route_table.hr_app_private_subnet_rt_1b.id 
}

####### Site-to-Site VPN connection ###########
resource "aws_vpn_connection" "hr_vpn" {
  vpn_gateway_id      = aws_vpn_gateway.hr_vgw.id
  customer_gateway_id = aws_customer_gateway.netlab_cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel1_dpd_timeout_action           = "restart"
  tunnel1_dpd_timeout_seconds          = 30
  tunnel1_startup_action               = "start"

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]
  tunnel2_dpd_timeout_action           = "restart"
  tunnel2_dpd_timeout_seconds          = 30
  tunnel2_startup_action               = "start"

  tags = {
    Name = "hr-vpc-vpn-connection"
  }
}

####### Static VPN routes for NetLab networks ############
resource "aws_vpn_connection_route" "lan_a" {
  vpn_connection_id      = aws_vpn_connection.hr_vpn.id
  destination_cidr_block = var.netlab_user_cidr
}

resource "aws_vpn_connection_route" "lan_b" {
  vpn_connection_id      = aws_vpn_connection.hr_vpn.id
  destination_cidr_block = var.netlab_server_cidr
}

resource "aws_vpn_connection_route" "pfsense_wan" {
  vpn_connection_id      = aws_vpn_connection.hr_vpn.id
  destination_cidr_block = var.pfsense_cidr_block
}

####### outputs for pfSense config ############
output "hr_vpn_tunnel1_address" {
  value = aws_vpn_connection.hr_vpn.tunnel1_address
}

output "hr_vpn_tunnel1_psk" {
  value     = aws_vpn_connection.hr_vpn.tunnel1_preshared_key
  sensitive = true
}