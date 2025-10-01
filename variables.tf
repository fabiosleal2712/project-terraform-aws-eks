variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "security_group_id" {
  description = "ID do grupo de segurança para as instâncias EC2"
  type        = string
  default     = "placeholder"
}
variable "db_password" {
  description = "The password for the database"
  type        = string
  default     = "L2pP2Da2FSjzZN"
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
  default     = "vpc-09c6102458be2706e"
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "cluster_role_arn" {
  description = "ARN da role do cluster EKS"
  type        = string
  default     = "placeholder"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  #default     = "my-cluster" 
}

variable "security_group_ids" {
  description = "IDs dos grupos de segurança para as instâncias EC2"
  type        = list(string)
  default     = []
}

# Credenciais AWS removidas - usando AWS CLI

variable "ami_id" {
  description = "ID da AMI"
  type        = string
}

variable "provider_path" {
  description = "Caminho do provedor"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instância"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "principal_arn" {
  description = "ARN do principal"
  type        = string
  default     = "arn:aws:iam::123456789012:role/example-role"
}