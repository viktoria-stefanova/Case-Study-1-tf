
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

# transit gw attatchment 
resource "aws_ec2_transit_gateway_vpc_attachment" "hr_app_tgw_attatchment" {
  subnet_ids         = [aws_subnet.hr_app_private_subnet_alb_1a.id, aws_subnet.hr_app_private_subnet_alb_1b.id]
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = aws_vpc.hr_app_vpc.id

  tags = {
    Name = "tgw-attach-hr-app"
  }
}
