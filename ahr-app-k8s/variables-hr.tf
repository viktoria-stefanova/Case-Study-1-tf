# variables.tf

variable "aws_region" {
  type        = string
  description = "AWS region"
}

################ DB VPC ################

variable "db_vpc_cidr" {
  type        = string
  description = "CIDR block of the DB VPC"
}

variable "db_private_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for DB Private Subnets"
}

############### HR APP VPC #################################

variable "hr_app_vpc_cidr" {
  type        = string
  description = "CIDR block of the HR App VPC"
}

variable "hr_app_private_subnets_node_cidr" {
  type        = list(string)
  description = "CIDR block for HR App Private Node Subnets"
}

variable "hr_app_private_subnets_alb_cidr" {
  type        = list(string)
  description = "CIDR block for HR App Private ALB Subnets"
}

variable "hr_app_public_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for HR App Public Subnets (NAT GW)"
}

variable "hr_dns_eni_ips" {
  type        = list(string)
  description = "IPs for DNS ENIs in HR VPC"
}

################# S3 TERRAFORM STATE #########

variable "terraform_state_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for terraform state"
}

############## MY IP ##################
variable "my_ip" {
  description = "my public ip"
  type        = string
}


variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}


variable "account_id" {
  type        = string
  description = "Account ID"
}

################### VPN ##########################

variable "netlab_public_ip" {
  type        = string
  description = "Public IP address of the pfSense WAN side / customer gateway"
}

variable "netlab_user_cidr" {
  type        = string
  description = "NetLab user network CIDR"
  default     = "172.16.1.0/24"
}

variable "netlab_server_cidr" {
  type        = string
  description = "NetLab server network CIDR"
  default     = "172.16.2.0/24"
}

variable "pfsense_wan_ip" {
  type        = string
  description = "pfSense WAN IP (for DNS resolver access)"
}

variable "pfsense_cidr_block" {
  type        = string
  description = "pfSense cidr block"
}

################### K3S ##########################

variable "hr_app_secret_name" {
  type        = string
  description = "Secrets Manager secret name for HR app environment variables"
  default     = "hr-ad-sync-env"
}

# variable "k8s_manifests_bucket" {
#   description = "S3 bucket created by bootstrap where Kubernetes manifests are stored"
#   type        = string
# }

variable "k8s_manifests_prefix" {
  description = "Prefix inside the S3 bucket for HR AD Sync Kubernetes manifests"
  type        = string
  default     = "hr-ad-sync"
}