
# Security group: allow DNS from NetLab over VPN
resource "aws_security_group" "hr_dns_resolver_sg" {
  name        = "hr-dns-resolver-sg"
  description = "Allow DNS from NetLab LAN A + LAN B over VPN"
  vpc_id      = aws_vpc.hr_app_vpc.id

  tags = {
    Name = "HR DNS Resolver SG"
  }
}

# UDP 53 from LAN A
resource "aws_vpc_security_group_ingress_rule" "hr_dns_udp_from_lan_a" {
  security_group_id = aws_security_group.hr_dns_resolver_sg.id
  cidr_ipv4         = var.netlab_user_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  description       = "DNS UDP from NetLab LAN A"
}

# TCP 53 from LAN A (large responses)
resource "aws_vpc_security_group_ingress_rule" "hr_dns_tcp_from_lan_a" {
  security_group_id = aws_security_group.hr_dns_resolver_sg.id
  cidr_ipv4         = var.netlab_user_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  description       = "DNS TCP from NetLab LAN A"
}

# UDP 53 from LAN B
resource "aws_vpc_security_group_ingress_rule" "hr_dns_udp_from_lan_b" {
  security_group_id = aws_security_group.hr_dns_resolver_sg.id
  cidr_ipv4         = var.netlab_server_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  description       = "DNS UDP from NetLab LAN B"
}

# TCP 53 from LAN B
resource "aws_vpc_security_group_ingress_rule" "hr_dns_tcp_from_lan_b" {
  security_group_id = aws_security_group.hr_dns_resolver_sg.id
  cidr_ipv4         = var.netlab_server_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  description       = "DNS TCP from NetLab LAN B"
}

# udp 53 from pfsense wan
resource "aws_vpc_security_group_ingress_rule" "hr_dns_udp_from_pfsense_wan" {
  security_group_id = aws_security_group.hr_dns_resolver_sg.id
  cidr_ipv4         = "${var.pfsense_wan_ip}/32"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  description       = "DNS UDP from pfSense WAN (Unbound source IP)"
}

# tcp 53 from pfsense wan
resource "aws_vpc_security_group_ingress_rule" "hr_dns_tcp_from_pfsense_wan" {
  security_group_id = aws_security_group.hr_dns_resolver_sg.id
  cidr_ipv4         = "${var.pfsense_wan_ip}/32"
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  description       = "DNS TCP from pfSense WAN (Unbound source IP)"
}


# Egress 
resource "aws_vpc_security_group_egress_rule" "hr_dns_resolver_egress" {
  security_group_id = aws_security_group.hr_dns_resolver_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Resolver Inbound Endpoint: the ip addresses of the dns resolver
resource "aws_route53_resolver_endpoint" "hr_inbound" {
  name      = "hr-vpc-inbound-resolver"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.hr_dns_resolver_sg.id]

  ip_address {
    subnet_id = aws_subnet.hr_app_private_subnet_alb_1a.id
    ip        = var.hr_dns_eni_ips[0]
  }

  ip_address {
    subnet_id = aws_subnet.hr_app_private_subnet_alb_1b.id
    ip        = var.hr_dns_eni_ips[1]
  }

  tags = {
    Name = "HR VPC Inbound Resolver"
  }
}

output "hr_resolver_ips" {
  value       = [for ip in aws_route53_resolver_endpoint.hr_inbound.ip_address : ip.ip]
  description = "DNS resolver IPs to configure in pfSense DNS forwarder"
}
