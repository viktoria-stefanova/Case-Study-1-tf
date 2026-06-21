# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  hr_k3s_nodes.tf — k3s server + agent nodes                                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# ── AMI ───────────────────────────────────────────────────────────────────────

data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── k3s SERVER (AZ 1a) ──────────────────────────────────────────────────────

resource "aws_instance" "hr_k3s_server" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.hr_app_private_subnet_node_1a.id
  vpc_security_group_ids      = [aws_security_group.hr_k3s_node_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.hr_k3s_node_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/templates/k3s_server_userdata.sh.tftpl", {
    aws_region       = var.aws_region
    manifests_bucket = "hr-k8s-manifests-${var.account_id}"
    manifests_prefix = "phpldapadmin"
    k3s_token_secret = "hr-k3s-token"
    ca_cert_secret   = "hr-corp-ca-cert"
  }))

  tags = {
    Name = "HR k3s Server"
  }

  depends_on = [aws_nat_gateway.hr_nat_1a]
}

# ── k3s AGENT (AZ 1b) ───────────────────────────────────────────────────────

resource "aws_instance" "hr_k3s_agent" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.hr_app_private_subnet_node_1b.id
  vpc_security_group_ids      = [aws_security_group.hr_k3s_node_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.hr_k3s_node_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/templates/k3s_agent_userdata.sh.tftpl", {
    aws_region       = var.aws_region
    k3s_token_secret = "hr-k3s-token"
    server_ip        = aws_instance.hr_k3s_server.private_ip
  }))

  tags = {
    Name = "HR k3s Agent"
  }

  depends_on = [aws_nat_gateway.hr_nat_1b, aws_instance.hr_k3s_server]
}

# ── Outputs ──────────────────────────────────────────────────────────────────

output "hr_k3s_server_private_ip" {
  value = aws_instance.hr_k3s_server.private_ip
}

output "hr_k3s_agent_private_ip" {
  value = aws_instance.hr_k3s_agent.private_ip
}

# ── IAM role for k3s nodes (SSM + Secrets Manager read + S3 manifests) ───────

resource "aws_iam_role" "hr_k3s_node_role" {
  name = "hr-k3s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "hr_k3s_ssm" {
  role       = aws_iam_role.hr_k3s_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM policy to read the k3s token and the CA certificate
resource "aws_iam_policy" "hr_k3s_secrets_read" {
  name = "hr-k3s-secrets-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:hr-k3s-token-*",
        "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:hr-corp-ca-cert-*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "hr_k3s_secrets" {
  role       = aws_iam_role.hr_k3s_node_role.name
  policy_arn = aws_iam_policy.hr_k3s_secrets_read.arn
}

resource "aws_iam_policy" "hr_k3s_s3_manifests_read" {
  name = "hr-k3s-s3-manifests-read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::hr-k8s-manifests-${var.account_id}",
        "arn:aws:s3:::hr-k8s-manifests-${var.account_id}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "hr_k3s_s3_manifests_read" {
  role       = aws_iam_role.hr_k3s_node_role.name
  policy_arn = aws_iam_policy.hr_k3s_s3_manifests_read.arn
}

resource "aws_iam_instance_profile" "hr_k3s_node_profile" {
  name = "hr-k3s-node-profile"
  role = aws_iam_role.hr_k3s_node_role.name
}

# ── Security group for k3s nodes ─────────────────────────────────────────────

resource "aws_security_group" "hr_k3s_node_sg" {
  name        = "hr-k3s-node-sg"
  description = "k3s cluster traffic + ALB health checks + VPN access"
  vpc_id      = aws_vpc.hr_app_vpc.id

  tags = {
    Name = "HR k3s Node SG"
  }
}

# k3s API server (6443) — agent needs to reach server
resource "aws_vpc_security_group_ingress_rule" "k3s_api" {
  security_group_id            = aws_security_group.hr_k3s_node_sg.id
  referenced_security_group_id = aws_security_group.hr_k3s_node_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
  description                  = "k3s API server (node-to-node)"
}

# kubelet metrics (10250) — node-to-node
resource "aws_vpc_security_group_ingress_rule" "k3s_kubelet" {
  security_group_id            = aws_security_group.hr_k3s_node_sg.id
  referenced_security_group_id = aws_security_group.hr_k3s_node_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  description                  = "kubelet metrics (node-to-node)"
}

# Flannel VXLAN (8472 UDP) — k3s default CNI
resource "aws_vpc_security_group_ingress_rule" "k3s_vxlan" {
  security_group_id            = aws_security_group.hr_k3s_node_sg.id
  referenced_security_group_id = aws_security_group.hr_k3s_node_sg.id
  ip_protocol                  = "udp"
  from_port                    = 8472
  to_port                      = 8472
  description                  = "Flannel VXLAN overlay (node-to-node)"
}

# NodePort for ALB traffic (30080)
resource "aws_vpc_security_group_ingress_rule" "k3s_nodeport_from_alb" {
  security_group_id            = aws_security_group.hr_k3s_node_sg.id
  referenced_security_group_id = aws_security_group.hr_alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 30080
  to_port                      = 30080
  description                  = "NodePort 30080 from ALB"
}

# ICMP from NetLab only (VPN debugging)
resource "aws_vpc_security_group_ingress_rule" "k3s_icmp_lan_a" {
  security_group_id = aws_security_group.hr_k3s_node_sg.id
  cidr_ipv4         = var.netlab_user_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  description       = "ICMP from NetLab LAN A (VPN debugging)"
}

resource "aws_vpc_security_group_ingress_rule" "k3s_icmp_lan_b" {
  security_group_id = aws_security_group.hr_k3s_node_sg.id
  cidr_ipv4         = var.netlab_server_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  description       = "ICMP from NetLab LAN B (VPN debugging)"
}

# Full egress 
resource "aws_vpc_security_group_egress_rule" "k3s_egress" {
  security_group_id = aws_security_group.hr_k3s_node_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
