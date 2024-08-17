variable "vpc_id" {
  description = "ID da VPC onde o RDS será criado"
  type        = string
}

variable "security_group_id" {
  description = "ID do grupo de segurança para o RDS"
  type        = string
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "mydb-subnet-group"
  subnet_ids = [
    "subnet-0918b5e0264f8fc28",  # us-east-1a
    "subnet-0a145008d3db2fc92"   # us-east-1b
  ]
}