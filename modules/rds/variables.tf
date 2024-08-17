
variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
}


variable "availability_zones" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
  default     = ["subnet-0918b5e0264f8fc28", "subnet-0a145008d3db2fc92"] 
}