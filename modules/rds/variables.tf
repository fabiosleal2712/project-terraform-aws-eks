variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID do Security Group"
  type        = string
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
}