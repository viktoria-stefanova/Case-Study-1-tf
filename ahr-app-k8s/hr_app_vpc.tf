
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