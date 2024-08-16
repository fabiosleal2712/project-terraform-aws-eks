variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}
variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
}


variable "availability_zones" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}




