
resource "aws_vpc" "hr_app_vpc" {
  cidr_block           = var.hr_app_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "HR App VPC"
  }
}


# hr app vpc private subnets for nodes
resource "aws_subnet" "hr_app_private_subnet_node_1a" {
  vpc_id                  = aws_vpc.hr_app_vpc.id
  cidr_block              = var.hr_app_private_subnets_node_cidr[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "HR App private subnet Node 1a"
  }
}

resource "aws_subnet" "hr_app_private_subnet_node_1b" {
  vpc_id                  = aws_vpc.hr_app_vpc.id
  cidr_block              = var.hr_app_private_subnets_node_cidr[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "HR App private subnet Node 1b"
  }
}

# hr app vpc private subnets for load balancer
resource "aws_subnet" "hr_app_private_subnet_alb_1a" {
  vpc_id                  = aws_vpc.hr_app_vpc.id
  cidr_block              = var.hr_app_private_subnets_alb_cidr[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "HR App private subnet Load balancer 1a"
  }
}

resource "aws_subnet" "hr_app_private_subnet_alb_1b" {
  vpc_id                  = aws_vpc.hr_app_vpc.id
  cidr_block              = var.hr_app_private_subnets_alb_cidr[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "HR App private subnet Load balancer 1b"
  }
}


# Internet Gateway for HR VPC (needed for NAT gateway egress)
resource "aws_internet_gateway" "igw_hr_app" {
  vpc_id = aws_vpc.hr_app_vpc.id

  tags = {
    Name = "HR App IGW"
  }
}

# hr app vpc public subnets (for NAT gateway)
resource "aws_subnet" "hr_app_public_subnet_1a" {
  vpc_id                  = aws_vpc.hr_app_vpc.id
  cidr_block              = var.hr_app_public_subnets_cidr[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "HR App public subnet 1a"
  }
}

resource "aws_subnet" "hr_app_public_subnet_1b" {
  vpc_id                  = aws_vpc.hr_app_vpc.id
  cidr_block              = var.hr_app_public_subnets_cidr[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "HR App public subnet 1b"
  }
}

# NAT gateways 
resource "aws_eip" "hr_nat_eip_1a" {
  domain = "vpc"

  tags = {
    Name = "HR NAT EIP 1a"
  }
}

resource "aws_eip" "hr_nat_eip_1b" {
  domain = "vpc"

  tags = {
    Name = "HR NAT EIP 1b"
  }
}

resource "aws_nat_gateway" "hr_nat_1a" {
  allocation_id = aws_eip.hr_nat_eip_1a.id
  subnet_id     = aws_subnet.hr_app_public_subnet_1a.id

  tags = {
    Name = "HR NAT Gateway 1a"
  }

  depends_on = [aws_internet_gateway.igw_hr_app]
}

resource "aws_nat_gateway" "hr_nat_1b" {
  allocation_id = aws_eip.hr_nat_eip_1b.id
  subnet_id     = aws_subnet.hr_app_public_subnet_1b.id

  tags = {
    Name = "HR NAT Gateway 1b"
  }

  depends_on = [aws_internet_gateway.igw_hr_app]
}

## VPC endpoints ###

resource "aws_security_group" "hr_ssm_endpoint_sg" {
  name        = "hr-ssm-endpoint-sg"
  description = "Allow HTTPS from HR VPC to SSM/Secrets Manager endpoints"
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

# ── SSM VPC endpoints

resource "aws_vpc_endpoint" "hr_ssm" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.hr_app_private_subnet_node_1a.id, aws_subnet.hr_app_private_subnet_node_1b.id]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = { Name = "HR SSM Endpoint" }
}

resource "aws_vpc_endpoint" "hr_ssmmessages" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.hr_app_private_subnet_node_1a.id, aws_subnet.hr_app_private_subnet_node_1b.id]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = { Name = "HR SSM Messages Endpoint" }
}

resource "aws_vpc_endpoint" "hr_ec2messages" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.hr_app_private_subnet_node_1a.id, aws_subnet.hr_app_private_subnet_node_1b.id]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = { Name = "HR EC2 Messages Endpoint" }
}

# ── S3 gateway endpoint (manifest sync, free) ────────────────────────────────

resource "aws_vpc_endpoint" "hr_s3_gateway" {
  vpc_id            = aws_vpc.hr_app_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.hr_app_private_subnet_rt_1a.id,
    aws_route_table.hr_app_private_subnet_rt_1b.id,
  ]

  tags = { Name = "HR S3 Gateway Endpoint" }
}

# ── Secrets Manager VPC endpoint (nodes read secrets at boot) ────────────────

resource "aws_vpc_endpoint" "hr_secretsmanager" {
  vpc_id              = aws_vpc.hr_app_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.hr_app_private_subnet_node_1a.id, aws_subnet.hr_app_private_subnet_node_1b.id]
  security_group_ids  = [aws_security_group.hr_ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = { Name = "HR Secrets Manager Endpoint" }
}
