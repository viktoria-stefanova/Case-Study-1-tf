# security group for the internal ALB
resource "aws_security_group" "hr_alb_sg" {
  name        = "hr-alb-sg"
  description = "Allow HTTP from NetLab LAN A + LAN B over VPN"
  vpc_id      = aws_vpc.hr_app_vpc.id

  tags = {
    Name = "HR ALB Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "hr_alb_from_lan_a" {
  security_group_id = aws_security_group.hr_alb_sg.id
  cidr_ipv4         = var.netlab_user_cidr
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "HTTP from NetLab LAN A"
}

resource "aws_vpc_security_group_ingress_rule" "hr_alb_from_lan_b" {
  security_group_id = aws_security_group.hr_alb_sg.id
  cidr_ipv4         = var.netlab_server_cidr
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "HTTP from NetLab LAN B"
}

resource "aws_vpc_security_group_egress_rule" "hr_alb_egress" {
  security_group_id = aws_security_group.hr_alb_sg.id
  cidr_ipv4         = var.hr_app_vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "HTTP to HR VPC targets"
}


# udp 53 from pfsense wan
resource "aws_vpc_security_group_ingress_rule" "hr_dns_udp_from_pfsense_wan_alb" {
  security_group_id = aws_security_group.hr_alb_sg.id
  cidr_ipv4         = "${var.pfsense_wan_ip}/32"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  description       = "DNS UDP from pfSense WAN (Unbound source IP)"
}

# tcp 53 from pfsense wan
resource "aws_vpc_security_group_ingress_rule" "hr_dns_tcp_from_pfsense_wan_alb" {
  security_group_id = aws_security_group.hr_alb_sg.id
  cidr_ipv4         = "${var.pfsense_wan_ip}/32"
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  description       = "DNS TCP from pfSense WAN (Unbound source IP)"
}

# Internal ALB
resource "aws_lb" "hr_alb" {
  name               = "hr-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.hr_alb_sg.id]
  subnets = [
    aws_subnet.hr_app_private_subnet_alb_1a.id,
    aws_subnet.hr_app_private_subnet_alb_1b.id,
  ]

  tags = {
    Name = "HR Internal ALB"
  }
}

# Target group — instance type for now, swap to IP type later for K8s
resource "aws_lb_target_group" "hr_alb_tg" {
  name        = "hr-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hr_app_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "HR ALB Target Group"
  }
}

# Attach the existing test EC2 to the target group
resource "aws_lb_target_group_attachment" "hr_test_instance" {
  target_group_arn = aws_lb_target_group.hr_alb_tg.arn
  target_id        = aws_instance.hr_vpn_test.id
  port             = 80
}

# Listener: HTTP :80 → target group
resource "aws_lb_listener" "hr_alb_http" {
  load_balancer_arn = aws_lb.hr_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hr_alb_tg.arn
  }

  tags = {
    Name = "HR ALB HTTP Listener"
  }
}

output "hr_alb_dns_name" {
  value       = aws_lb.hr_alb.dns_name
  description = "Internal DNS name of the HR ALB — reach it from pfSense over the VPN"
}