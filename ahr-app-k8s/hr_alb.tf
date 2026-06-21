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

# Target group — NodePort 30080 on k3s nodes
resource "aws_lb_target_group" "hr_alb_tg" {
  name        = "hr-alb-tg"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hr_app_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "30080"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "HR ALB Target Group"
  }
}

# Register k3s server node
resource "aws_lb_target_group_attachment" "hr_k3s_server" {
  target_group_arn = aws_lb_target_group.hr_alb_tg.arn
  target_id        = aws_instance.hr_k3s_server.id
  port             = 30080
}

# Register k3s agent node
resource "aws_lb_target_group_attachment" "hr_k3s_agent" {
  target_group_arn = aws_lb_target_group.hr_alb_tg.arn
  target_id        = aws_instance.hr_k3s_agent.id
  port             = 30080
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
  description = "Internal DNS name of the HR ALB)"
}

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

# ALB egress — NodePort 30080 to k3s nodes
resource "aws_vpc_security_group_egress_rule" "hr_alb_egress" {
  security_group_id = aws_security_group.hr_alb_sg.id
  cidr_ipv4         = var.hr_app_vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 30080
  to_port           = 30080
  description       = "NodePort 30080 to k3s nodes"
}
