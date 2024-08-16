variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}


variable "security_group_id" {
  description = "ID do grupo de segurança para as instâncias EC2"
  type        = string
  default = "sg-000031672e37c8557"
}
