# ==============================================================================
# FILE: hr_vpn_test_instance.tf
# ==============================================================================
# Throwaway instance for VPN connectivity testing. Delete after VPN is verified.

resource "aws_security_group" "hr_vpn_test_sg" {
  name        = "hr-vpn-test-sg"
  description = "Allow ICMP and SSH from NetLab over VPN"
  vpc_id      = aws_vpc.hr_app_vpc.id

  tags = {
    Name = "HR VPN Test SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "hr_vpn_test_icmp" {
  security_group_id = aws_security_group.hr_vpn_test_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "hr_vpn_test_ssh" {
  security_group_id = aws_security_group.hr_vpn_test_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "hr_vpn_test_egress" {
  security_group_id = aws_security_group.hr_vpn_test_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "hr_vpn_test" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.hr_app_private_subnet_node_1a.id
  private_ip                  = "10.4.1.10"
  vpc_security_group_ids      = [aws_security_group.hr_vpn_test_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "HR VPN Test Instance"
  }
}

output "hr_vpn_test_instance_private_ip" {
  value = aws_instance.hr_vpn_test.private_ip
}