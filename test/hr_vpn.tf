####### Customer Gateway #############
####### Virtual Private Gateway #############
####### VGW attachment to HR VPC ###########
####### Site-to-Site VPN connection ###########
####### Static VPN routes for NetLab networks ############


# vpn-test.tf

locals {
  vpn_test_cidr = "10.4.0.0/16"
  onprem_lan_a  = "172.16.1.0/24"
  onprem_lan_b  = "172.16.2.0/24"
  pfsense_public_ip = "145.220.75.5"
}

# ── VPC ────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "vpn_test" {
  cidr_block           = local.vpn_test_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "vpn-test-vpc" }
}

# ── Subnets ────────────────────────────────────────────────────────────────────

resource "aws_subnet" "vpn_test_private" {
  for_each = {
    "a" = { cidr = "10.4.1.0/24", az = "eu-central-1a" }
    "b" = { cidr = "10.4.2.0/24", az = "eu-central-1b" }
    "c" = { cidr = "10.4.3.0/24", az = "eu-central-1a" }
    "d" = { cidr = "10.4.4.0/24", az = "eu-central-1b" }
  }

  vpc_id            = aws_vpc.vpn_test.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = { Name = "vpn-test-private-${each.key}" }
}

# ── Route table (one shared, attached to all subnets) ─────────────────────────

resource "aws_route_table" "vpn_test" {
  vpc_id = aws_vpc.vpn_test.id
  tags   = { Name = "vpn-test-rt" }
}

resource "aws_route_table_association" "vpn_test" {
  for_each       = aws_subnet.vpn_test_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.vpn_test.id
}

# ── Virtual Private Gateway ────────────────────────────────────────────────────

resource "aws_vpn_gateway" "vpn_test" {
  vpc_id          = aws_vpc.vpn_test.id
  amazon_side_asn = 64512

  tags = { Name = "vpn-test-vgw" }
}

# Propagate VGW routes into the route table automatically
resource "aws_vpn_gateway_route_propagation" "vpn_test" {
  vpn_gateway_id = aws_vpn_gateway.vpn_test.id
  route_table_id = aws_route_table.vpn_test.id
}

# ── Customer Gateway (your pfSense) ───────────────────────────────────────────

resource "aws_customer_gateway" "pfsense" {
  bgp_asn    = 65000   # doesn't matter for static routing, just needs a valid value
  ip_address = local.pfsense_public_ip
  type       = "ipsec.1"

  tags = { Name = "vpn-test-cgw-pfsense" }
}

# ── Site-to-Site VPN connection ───────────────────────────────────────────────

resource "aws_vpn_connection" "vpn_test" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_test.id
  customer_gateway_id = aws_customer_gateway.pfsense.id
  type                = "ipsec.1"
  static_routes_only  = true   # no BGP, simple static routing

  # Tunnel 1 options
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel1_dpd_timeout_action           = "restart"
  tunnel1_dpd_timeout_seconds          = 30
  tunnel1_startup_action               = "start"   # AWS initiates — but pfSense will also initiate, this just keeps AWS trying

  # Tunnel 2 options (same config, AWS assigns different endpoint IP)
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

  tags = { Name = "vpn-test-connection" }
}

# ── Static routes telling AWS to send your LANs through the VPN ───────────────

resource "aws_vpn_connection_route" "lan_a" {
  vpn_connection_id      = aws_vpn_connection.vpn_test.id
  destination_cidr_block = local.onprem_lan_a
}

resource "aws_vpn_connection_route" "lan_b" {
  vpn_connection_id      = aws_vpn_connection.vpn_test.id
  destination_cidr_block = local.onprem_lan_b
}

# ── Outputs — you'll need these for pfSense config ────────────────────────────

output "tunnel1_address" {
  value = aws_vpn_connection.vpn_test.tunnel1_address
}

output "tunnel1_psk" {
  value     = aws_vpn_connection.vpn_test.tunnel1_preshared_key
  sensitive = true
}

output "tunnel2_address" {
  value = aws_vpn_connection.vpn_test.tunnel2_address
}

output "tunnel2_psk" {
  value     = aws_vpn_connection.vpn_test.tunnel2_preshared_key
  sensitive = true
}

output "tunnel1_cgw_inside_address" {
  value = aws_vpn_connection.vpn_test.tunnel1_cgw_inside_address
}

output "tunnel1_vgw_inside_address" {
  value = aws_vpn_connection.vpn_test.tunnel1_vgw_inside_address
}