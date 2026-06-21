# Resources:
# aws_route_table
# aws_route
# aws_route_table_association

# HR App VPC private subnet for Nodes
# HR App VPC PUBLIC route table (for NAT subnets)
resource "aws_route_table" "hr_app_public_subnet_rt" {
  vpc_id = aws_vpc.hr_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_hr_app.id
  }

  tags = {
    Name = "HR App VPC public subnet RT"
  }
}

# HR App VPC PRIVATE route table 1a (for node subnet 1a + ALB subnet 1a)
resource "aws_route_table" "hr_app_private_subnet_rt_1a" {
  vpc_id = aws_vpc.hr_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hr_nat_1a.id
  }
  route {
    cidr_block = "${var.pfsense_wan_ip}/32"
    gateway_id = aws_vpn_gateway.hr_vgw.id
  }
  tags = {
    Name = "HR App VPC private subnet RT 1a"
  }
}

# HR App VPC PRIVATE route table 1b
resource "aws_route_table" "hr_app_private_subnet_rt_1b" {
  vpc_id = aws_vpc.hr_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hr_nat_1b.id
  }

  route {
    cidr_block = "${var.pfsense_wan_ip}/32"
    gateway_id = aws_vpn_gateway.hr_vgw.id
  }

  tags = {
    Name = "HR App VPC private subnet RT 1b"
  }
}

# HR App VPC public subnets (NAT)
resource "aws_route_table_association" "hr_app_public_subnet_rt_assoc_1a" {
  subnet_id      = aws_subnet.hr_app_public_subnet_1a.id
  route_table_id = aws_route_table.hr_app_public_subnet_rt.id
}

resource "aws_route_table_association" "hr_app_public_subnet_rt_assoc_1b" {
  subnet_id      = aws_subnet.hr_app_public_subnet_1b.id
  route_table_id = aws_route_table.hr_app_public_subnet_rt.id
}

# HR App private subnets — node + ALB share AZ-matched route tables
resource "aws_route_table_association" "hr_app_private_subnet_node_rt_assoc_1a" {
  subnet_id      = aws_subnet.hr_app_private_subnet_node_1a.id
  route_table_id = aws_route_table.hr_app_private_subnet_rt_1a.id
}

resource "aws_route_table_association" "hr_app_private_subnet_node_rt_assoc_1b" {
  subnet_id      = aws_subnet.hr_app_private_subnet_node_1b.id
  route_table_id = aws_route_table.hr_app_private_subnet_rt_1b.id
}

resource "aws_route_table_association" "hr_app_private_subnet_alb_rt_assoc_1a" {
  subnet_id      = aws_subnet.hr_app_private_subnet_alb_1a.id
  route_table_id = aws_route_table.hr_app_private_subnet_rt_1a.id
}

resource "aws_route_table_association" "hr_app_private_subnet_alb_rt_assoc_1b" {
  subnet_id      = aws_subnet.hr_app_private_subnet_alb_1b.id
  route_table_id = aws_route_table.hr_app_private_subnet_rt_1b.id
}