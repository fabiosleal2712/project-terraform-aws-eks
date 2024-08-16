variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}
variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
}


variable "vpc_id" {
  description = "ID da VPC onde o RDS será criado"
  type        = string
}

variable "security_group_id" {
  description = "ID do grupo de segurança para o RDS"
  type        = string
}