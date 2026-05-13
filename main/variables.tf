# variables.tf

variable "aws_region" {
  type        = string
  description = "AWS region"
}

################ HUB VPC ################

variable "hub_vpc_cidr" {
  type        = string
  description = "CIDR block of the Hub VPC"
}

variable "hub_public_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for Hub Public Subnets"
}

variable "hub_private_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for Hub Public Subnets"
}

################ APP VPC ################

variable "app_vpc_cidr" {
  type        = string
  description = "CIDR block of the App VPC"
}

variable "app_public_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for App Public Subnets"
}

variable "app_private_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for App Private Subnets"
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

############## SOAR ####################

variable "alert_email" {
  type        = string
  description = "Email address to receive SOAR alert notifications"
}

variable "waf_rate_limit" {
  type        = number
  description = "Max requests per 5-minute window per IP before WAF blocks and Lambda responds"
  default     = 300
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