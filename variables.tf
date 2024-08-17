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
  default     = "sg-000031672e37c8557"
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
