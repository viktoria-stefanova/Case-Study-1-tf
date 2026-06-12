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

resource "aws_vpc_security_group_ingress_rule" "hr_vpn_test_http_from_alb" {
  security_group_id            = aws_security_group.hr_vpn_test_sg.id
  referenced_security_group_id = aws_security_group.hr_alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "HTTP from HR ALB"
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
  iam_instance_profile        = aws_iam_instance_profile.hr_vpn_test_profile.name  

  tags = {
    Name = "HR VPN Test Instance"
  }
}

output "hr_vpn_test_instance_private_ip" {
  value = aws_instance.hr_vpn_test.private_ip
}

# ── IAM for SSM ───────────────────────────────────────────────────────────────

resource "aws_iam_role" "hr_vpn_test_ssm_role" {
  name = "hr-vpn-test-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "hr_vpn_test_ssm_attach" {
  role       = aws_iam_role.hr_vpn_test_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "hr_vpn_test_profile" {
  name = "hr-vpn-test-ssm-profile"
  role = aws_iam_role.hr_vpn_test_ssm_role.name
}

# ── Security group for SSM endpoints ──────────────────────────────────────────

resource "aws_security_group" "hr_ssm_endpoint_sg" {
  name        = "hr-ssm-endpoint-sg"
  description = "Allow HTTPS from HR VPC to SSM endpoints"
  vpc_id      = aws_vpc.hr_app_vpc.id

  tags = {
    Name = "HR SSM Endpoint SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "hr_ssm_endpoint_https" {
  security_group_id = aws_security_group.hr_ssm_endpoint_sg.id
  cidr_ipv4         = var.hr_app_vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "hr_ssm_endpoint_egress" {
  security_group_id = aws_security_group.hr_ssm_endpoint_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── SSM VPC endpoints (interface type, 3 required) ────────────────────────────

resource "aws_vpc_endpoint" "hr_ssm" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.hr_app_private_subnet_node_1a.id, aws_subnet.hr_app_private_subnet_node_1b.id]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "HR SSM Endpoint"
  }
}

resource "aws_vpc_endpoint" "hr_ssmmessages" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.hr_app_private_subnet_node_1a.id, aws_subnet.hr_app_private_subnet_node_1b.id]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "HR SSM Messages Endpoint"
  }
}

resource "aws_vpc_endpoint" "hr_ec2messages" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.hr_app_private_subnet_node_1a.id, aws_subnet.hr_app_private_subnet_node_1b.id]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "HR EC2 Messages Endpoint"
  }
}

# Add to hr_vpn_test_instance.tf or a new hr_ecr_endpoints.tf

resource "aws_vpc_endpoint" "hr_ecr_api" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.hr_app_private_subnet_node_1a.id,
    aws_subnet.hr_app_private_subnet_node_1b.id,
  ]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = { Name = "HR ECR API Endpoint" }
}

resource "aws_vpc_endpoint" "hr_ecr_dkr" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.hr_app_private_subnet_node_1a.id,
    aws_subnet.hr_app_private_subnet_node_1b.id,
  ]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = { Name = "HR ECR DKR Endpoint" }
}

resource "aws_vpc_endpoint" "hr_s3_gateway" {
  vpc_id            = aws_vpc.hr_app_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [
    aws_route_table.hr_app_private_subnet_rt_1a.id,
    aws_route_table.hr_app_private_subnet_rt_1b.id,
  ]

  tags = { Name = "HR S3 Gateway Endpoint" }
}


resource "aws_iam_role_policy_attachment" "hr_vpn_test_ecr_read" {
  role       = aws_iam_role.hr_vpn_test_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}